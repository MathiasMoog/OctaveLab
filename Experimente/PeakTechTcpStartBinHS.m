% Versuche mit dem PeakTech 1265 Oszi über TCP zu sprechen
% Achtung, diesen Code für das Scope der Hochschule verwenden,
% STARTBIN liefert Daten im SPBS0A Format
% Lese die Daten von einem oder zwei Kanälen aus.

% Beispiel Code von https://wiki.octave.org/Instrument_control_package#TCP


pkg load instrument-control

% Little Endian, 4 byte in einen uint32 verwandeln
function n=le4uint( data, i);
  n=uint32(data(i)) + bitshift(uint32(data(i+1)),8) + bitshift(uint32(data(i+2)),16) ...
    + bitshift(uint32(data(i+3)),24);
endfunction

% Little Endian, 2 byte in einen int16 verwandeln
function n=le2int( data, i);
  n=bitshift(int16(data(i+1)),8)+int16(data(i));
endfunction

disp("Open TCP Connection");
# Open TCP connection to 127.0.0.1:8000 with timeout of 100 ms
% Die IP ist fix im Oszi eingestellt, das kann kein dhcp
% Der Port 3000 ist die Voreinstellung.
% 
t0 = tcp("192.168.178.72",3000,1000)
# set timeout to blocking
#tcp_timeout(t0, -1) 

disp("Send command");
# write to listener
%tcp_write(t0, "*IDN") 
% Aktiviere SCPI
tcp_write(t0, ":SDSLSCPI#") 
% Lese die Antwort, warte 1000 ms
[data, count] = tcp_read ( t0, 1000, 1000 )
if (count==0) 
  disp("SCPI konnte nicht aktiviert werden oder ist schon aktiv.")
else
  printf("SCPI aktiviert, Antwort=%s",char(data));
endif

% Lese die Serienummer aus
tcp_write(t0, "*IDN?") 
% Lese die Antwort, warte 1000 ms
[data, count] = tcp_read ( t0, 1000, 1000 );
if (count==0) 
  disp("Ups - keine Seriennummer!?")
else
  printf("Seriennummer=%s",char(data));
endif

% Frage Daten im Binären Format ab.
% Siehe D:\Elektro\Geraete\Peaktech1265\OwonProtokoll, Word Dokumenten
% und PeakTechProtokoll, usb Beispiel Code
tcp_write(t0, "STARTBIN") 
% Leere Legende
L={};
% Lese den Header, 12 bytes
[data, count] = tcp_read ( t0, 12, 1000 );
ndata=0;
if (count==0) 
  disp("Ups - kein Antwort des Oszi!? Wo blebt der Kanal?")
else
  % Rohdaten anzeigen, 12 bytes wenn alles gut geht
  disp(count)
  disp(data)
  % Die ersten drei bytes enthalten die Länge des folgenden Datenstroms
  % Nach dem Own Protokoll die ersten vier bytes
  ndata=le4uint(data,1);
  printf("Size, hex bytes:%x%x%x, hex value %x, dec value %d\n", ...
   data(3),data(2),data(1), ndata, ndata);
  % der zweite uint32 (data(5:8) wird ignoriert
  % Format des folgenden Datenstroms anzeigen 1 - Bild, 0 - binärformat
  % OWON: der dritte uint ist "flag"
  flag = le4uint(data,9);
  % Achtung, es kommt 129 in flag an, das bedeutet nach owon Anleitung
  % S 5 "deep memory vector data file" da sollen eigentlich zwei Kanäle kommen !?
  % Das Peaktech sendet immer 129 und einen Datensatz. Diese kann jedoch bis zu 
  % zwei Kanäle enthalten.
  printf("Format = %d, flag =%d\n",data(12),flag);
endif

% Lese die Daten
[data, count] = tcp_read ( t0, ndata, 1000 );
if (count!=ndata) 
  printf("Nicht genügend Daten erhalten. Erwarte %d, erhalten %d\n",ndata,count);
else
  % schreibe eine binäre Datei
  fid = fopen("test.bin","w");
  fwrite(fid,data);
  fclose(fid);
  % Lese die Daten - das funktioniert nicht, das Format ist anders!
  % zumindest kommen die Daten als 16 bin integers 
  %bin=read_peak_tech_bin( "test.bin" )  
  % Der Header ist noch verständlich ...
  printf("Header %s, Scope %s\n",data(1:6), data(11:22));
  % Durch Probieren den Start des ersten Kanals entdeckt ...
  % Beginn des Kanals
  m=55;
  do 
    printf("Kanal %s\n",data(m:m+2));
    % Versuche die Daten zu verstehen, gib als uint32 aus
    for i=(m+3:4:m+56)
      printf("i=%d v=%d\n",i-m,le4uint(data,i));
    endfor
    % Ab m+59 beginnt ein gegelmäßiges Muster, anscheinend immer zwei bytes zusammen
    % als int16 interpretieren.
    % Die Anzahl der Daten scheint in m+15 zu stehen
    n=le4uint(data,m+15);
    x=zeros(1,n);
    for i=1:n
      x(i) = le2int(data,m+57+2*i);
    end
    plot(x)
    L=[L, char(data(m:m+2))];
    hold on;
    % Schaue ob ein zweiter Kanal kommt
    % der schreint genau gelich aufgebaut zu sein.
    m=m+59+2*n
  until (ndata<m+100) 
  hold off
  legend(L);
end


# close tcp session
tcp_close(t0)