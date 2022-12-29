% Versuche eine UDP Verbindung zum Stamos aufzubauen.
% Nicht so einfach, alles mögliche probiert.
% Kernpunkte der Lösung:
%  - Gleicher Port auf beiden seiten (default port 18190 von Last)
%  - Terminator \n direkt beim Befehl mit senden, nicht nachträglich
%  - Mit read alle empfangene Daten auf einmal einlesen, nicht bytweise.
% Copyright, 2022, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA

pkg load instrument-control


% TCP ist es nach Anleitung nicht und funktioniert auch nicht.
%socket = tcpclient("192.168.178.64",3000,"Timeout",300);
% Die neue udpport Klasse will nicht. Keine Ahnung.
% Keine Beschreibung. Vor allem steht dort LocalHost drin ..?
%socket = udpport("LocalHost","192.168.178.64","LocalPort",3000,"Timeout",300);
%socket = udp("192.168.178.64",3000,"Timeout",0.3);
%pause(0.1);

%write(socket,"*IDN?\n")
%udp_write(socket,":SYSTem:DEVINFO?\n")
%udp_write(socket,":SYSTem:DEVINFO?\n")
%flush(socket,"output")
% Lesen klappt nicht, dabei hängt er sich fest bis der Timeout abgelaufen ist.
% Selbst nach 20 Sekunden kommt nichts ...
%udp_read(socket,5,10)
%serialPortReadLine(socket,"\n")

%udp_close(socket);

% Aus Matlab Beispiel kombiniert ...
% Funktioniert auch nicht. Es kommt nix an.
%socket = udpport("LocalHost","172.22.0.1");
%socket = udpport("LocalHost","192.168.178.20","LocalPort",18190)
socket = udpport("LocalPort",18190, "Timeout", 3)
%socket = udpport();
write(socket,"*IDN?\n","192.168.178.64",18190)
pause(0.2)
%write(socket,":INPut ON\n","192.168.178.64",18190)
%flush(socket);
get(socket,"NumBytesAvailable")
%serialPortReadLine(socket,"\n")
%read(socket,5)
char(read(socket))
socket = [];

