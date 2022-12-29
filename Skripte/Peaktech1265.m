classdef Peaktech1265 < handle
  % Class for ip communication with the Peachtech 1265 Scope
  %
  % Klasse zum Auslesen meinen Peaktech 1265 Oszilloskops
  % Beispiel anschauen ...
  % Achtung, dieser Code läuft momentan nur mit meinem Oszi.
  % an der Hochschule haben wir zwar auch ein Peaktech 1265, aber das ist
  % neuer und spricht einen anderen dialekt.
  %
  % Das Oszi muss über das Netzwerk erreichbar sein. Der Port ist fix auf
  % der Voreinstellung (3000)
  %
  % Die Spannungen (V/div, vertical Position) stimmen mit der Anzeige auf
  % dem Oszi überein.
  % Die Zeiten (Samples / s bzw. samplingzeit) passen nicht. Das Oszi misst
  % mit Faktor 2.5 höherer zeitlicher Auflösung und angeblich auch mit 10 k
  % Speichertiefe. Ausgegeben werden nur 3040 Punkte.

  % Die Instrument Control Package wird für die Kommunikation über TCP benötigt.
  %
  % Implemented:
  %  - read scope data
  %
  % Missing:
  %  - Everything else
  %
  % Copyright, 2015, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA

  properties
    % TCP socket handle
    tcp=[];
    % Debug Level, default is 0 (erros)( 1- warning, 2- info, during developement up to 3)
    debugLevel=3;

    % -------------------------------------------------------------------------
    % Data read from scope

    % Format der empfangenen Daten
    format=[];
    % Einstellung der Zeitbasis
    M=[];

    % samples (columns in t and u)
    samples=[];
    % U offset
    uOfs=[];
    % U scale
    uScale=[];
    % Sample time
    tSample=[];


    % time, in columns
    t=[];
    % voltage, row channel 1 or 2, columns data
    u=[];
    % channel
    ch=[];
  end

  properties (Constant = true)
    % Peak Tech Spannung, Index-1 -> Volt
    % Owon Oscilloscope PC ... S 9
    PT_V=[0.002, 0.005, 0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1, 2, 5, 10, 20, 50, 100, ...
      200,500,1000,2000,5000,10000];

    % Peak Tech Zeitbasis in s
    PT_M=[4e-9,10e-9,20e-9,40e-9,100e-9,200e-9,400e-9,1e-6,2e-6,4e-6,10e-6,20e-6,40e-6, ...
      100e-6,200e-6,400e-6,1e-3,2e-4,4e-3,10e-3,20e-3,40e-3,100e-3,200e-3,400e-3, ...
      1,2,4,10,20,40];
  end

  % Public methods
  methods (Access = public)

    % Create Instance and load instrument-control package
    function obj = Peaktech1265( )
      % Lade die package
      pkg load instrument-control
    end

    % baue eine TCP Verbindung zum Peakttech 1265 auf.
    function ok = connect( obj, ip="192.168.178.72" )
      %obj.tcp = tcp(ip,3000,3000);
      obj.tcp = tcpclient(ip,3000,"Timeout",3000);
    end

    % Disconnect from scope. Close tcp client
    function disconnect( obj )
      %tcp_close(obj.tcp);
      obj.tcp = [];
    end

    % Frage Daten im Binären Format ab.
    % Siehe D:\Elektro\Geraete\Peaktech1265\OwonProtokoll, Word Dokumenten
    % und PeakTechProtokoll, usb Beispiel Code
    function ok = getCurves( obj )
      % Daten im Binärformat abfragen
      write(obj.tcp, "STARTBIN");

      % Lese den Header, 12 bytes
      data = read ( obj.tcp, 12);
      ndata=0;
      if (isempty(data))
        obj.dprintf(0,"Ups - kein Antwort des Oszi!? Wo blebt der Kanal?");
        ok=false;
        return;
      endif
      % Rohdaten anzeigen, 12 bytes wenn alles gut geht
      %disp(count)
      %disp(data)
      % Die ersten vier bytes enthalten die Länge des folgenden Datenstroms
      ndata=obj.le4uint(data,1);
      %printf("Size, hex bytes:%x%x%x, hex value %x, dec value %d\n", ...
      % data(3),data(2),data(1), ndata, ndata);
      % der zweite uint32 (data(5:8) wird ignoriert
      % Format des folgenden Datenstroms anzeigen 1 - Bild, 0 - binärformat
      % OWON: der dritte uint ist "flag"
      %flag = obj.le4uint(data,9);
      % Achtung, es kommt 129 in flag an, das bedeutet nach owon Anleitung
      % S 5 "deep memory vector data file" da sollen eigentlich zwei Kanäle kommen !?
      % Das Peaktech sendet immer 129 und einen Datensatz. Diese kann jedoch bis zu
      % zwei Kanäle enthalten.
      %printf("Format = %d, flag =%d\n",data(12),flag);

      % Lese die Daten
      data = read ( obj.tcp, ndata );
      count = length(data);
      if (count!=ndata)
        obj.dprintf(0,"Nicht genügend Daten erhalten. Erwarte %d, erhalten %d\n",ndata,count);
        ok=false;
        return;
      endif

      % Die ersten 6 Bytes enhalten das Format der Daten
      obj.format=char(data(1:6));
      obj.dprintf(2,"Format %s\n",obj.format);
      % Das Format scheint dem Binären Format aus read_peaktech_bin
      % OK, scheint zu klappen, jetzt schon mal die Felder initialisieren
      obj.t=[];
      obj.u=[];
      obj.uOfs=[];
      obj.uScale=[];
      obj.ch={};
      % sehr zu ähneln
      m=11;
      do
        % Kanal Namen abfragen und eintragen
        ch = char(data(m:m+2));
        obj.ch = [ obj.ch, ch ];
        obj.dprintf(2,"Kanal %s\n",ch);

        % Lese vierzehn Blöcke
        % Versuche die Daten zu verstehen, gib als uint32 aus
        d=zeros(1,14);
        for i=1:14
          d(i)=obj.le4uint(data,m+i*4-1);
          obj.dprintf(2,"i=%d ofs=%d v=%d\n",i,m+i*4-1,d(i));
        endfor
        % Bisher bekannte Werte:
        % Nr. 1 ?? Owon S 13
        % Nr. 2
        obj.dprintf(2,"Nr. 3, disp start = %d\n",d(3));
        obj.dprintf(2,"Nr. 3, disp ende  = %d\n",d(3));
        % Die Anzahl der Samples wird später zum Auslesen benötigt.
        n=d(4);
        obj.samples=n;
        obj.dprintf(2,"Nr. 4, samples = %d\n",obj.samples);
        % Nr. 7 scheint die Zeitbasis zu sein
        obj.M = obj.PT_M(d(7)+1); % Überschreibe, ist in beiden Kanälen gleich
        obj.dprintf(2,"Nr. 7 wert=%d, M=%f s\n", d(7), obj.M);
        % Nr. 8 scheint das offset als Integer zu sein
        % 25 je Teilung, genau wie die Spannung, rechne auf Teilung um.
        Uofs=double(obj.le4int(data,m+8*4-1))/25.0;
        obj.uOfs=[obj.uOfs;Uofs];
        obj.dprintf("Nr. 8, u offset=%f \n",Uofs);
        % Nr. 9 scheint das Spannungslevel zu sein
        Uscale     = obj.PT_V(d(9)+1);
        obj.uScale = [ obj.uScale; Uscale ];
        obj.dprintf("Nr. 9 wert=%d, V=%f V\n", d(9), Uscale);
        % Nach der Owon Anleitung S 14 kommen noch mehr, erst mal ignorieren

        %Zeit, umrechnen von der Zeitbases aus Zeiten pro sample
        obj.tSample=obj.M*5e-3;
        obj.t=(0:(n-1))*obj.tSample;


        % Ab m+59 (esterer Kanal, absolut 70) beginnt ein gegelmäßiges Muster,
        % anscheinend immer zwei bytes zusammen
        % als int16 interpretieren.
        u=zeros(1,n);
        for i=1:n
          % Rechne gleich um, das Offset wird nicht mit eingerechnet,
          % es beeinfluss nur die Darstellung auf dem Bildschirm.
          u(i) = Uscale*double(obj.le2int(data,m+57+2*i))/25;
          %disp( double(le2int(data,m+57+2*i)) )
        end
        obj.u = [obj.u; u];
        % Schaue ob ein zweiter Kanal kommt
        % der schreint genau gelich aufgebaut zu sein.
        m=m+59+2*n;
      until (ndata<m+100);
      ok=true;
    end

    % Einstellungen anzeigen
    function disp( obj )
      printf("Kanäle %d\n",size(obj.u,1));
      printf("Messungen %d\n",obj.samples);
      printf("U offset in div %f\n",obj.uOfs);
      printf("U V / div %f\n",obj.uScale);
      printf("t sample in %e s\n",obj.tSample);
      printf("Samples / s %e \n",1.0/obj.tSample);
    endfunction


    % Zeichne die abgefragten Daten
    function plot( obj )
      % Leere Legende
      L={};
      % Zeiten passend skalieren
      tunit="s";
      t=obj.t; % local copy, will be modified
      if (t(end)<0.1) t*=1000; tunit="ms"; end;
      if (t(end)<0.1) t*=1000; tunit="us"; end;
      % Alle Kanäle zeichnen
      for l=1:size(obj.u,1)
        % restliche Kanäle hinzu
        plot( t, obj.u(l,:) );
        % Plot offen lassen
        hold on;
        % Legende merken
        L=[L, obj.ch{l}];
      end
      hold off;
      xlabel( ["Zeit in ", tunit] );
      ylabel("Spannung in V");
      legend( L );
      title("Peaktech 1265 Messung");
    end

  % End of public methods
  end

  % ----------------------------------------------------------------------------
  % Protected methods - at the moment public, change later on to protected
  methods (Access = public)

    % Little Endian, 4 byte in einen uint32 verwandeln
    function n=le4uint(obj, data, i);
      n=uint32(data(i)) + bitshift(uint32(data(i+1)),8) + bitshift(uint32(data(i+2)),16) ...
        + bitshift(uint32(data(i+3)),24);
    endfunction

    % Little Endian, 4 byte in einen int32 verwandeln
    function n=le4int(obj, data, i);
      n=int32(data(i)) + bitshift(int32(data(i+1)),8) + bitshift(int32(data(i+2)),16) ...
        + bitshift(int32(data(i+3)),24);
    endfunction

    % Little Endian, 2 byte in einen int16 verwandeln
    function n=le2int(obj, data, i);
      n=bitshift(int16(data(i+1)),8)+int16(data(i));
    endfunction


    % Debug output, like printf, but debug level as first argument.
    function dprintf(obj, level, varargin )
      if (level <= obj.debugLevel)
        printf(varargin{:});
      end
    end

  % End of protected methods
  end

end




