% Experiment zur Kommunikation mit dem KORAD KA3005P Netzgerät
% Siehe Kommentare in der Klasse KA3005P
%
% Aufbau und Verwendung
%  - Netzgerät anschalten und mit dem Rechner verbinden
%  - Elektronische Last im CR Modus mit 20 Ohm oder
%    12 V Lampe (minmal 12 W) an das Netzgerät anschließen
%  - Com Port anpassen
%  - Dieses Skript starten
%
% Copyright, 2021, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA


% Instanz anlegen
ka = KA3005P();
% Lege Instanz an
ut = Ut803();

% Öffne Com Port
ut.connect("/dev/ttyUSB0");

% Com Port öffnen, bitte Anpassen ...

ka.connect("/dev/ttyKA3005")
%ka.connect("/dev/ttyACM0")
ka.getVersion()
M=[];

s=now();

running=1
while (running)
  [value, unit] = ut.getValue()
  u = ka.getVoltage()
  i = ka.getCurrent()*1000;
  M = [M; [now(),u,i,value*1000]];
  plot((M(:,1)-s)*24*3600,M(:,2:end));
  legend("U","I","I ut");
  x = kbhit (1);
	if (strcmp(x,"E"))
    running = 0;
    disp("Breche ab");
  endif
  pause(1);
endwhile


% Bei Bedarf die Kennline abspeichern.
csvwrite("mess.csv", M );

% alles schließen
ut.disconnect()
% alles schließen
ka.disconnect();

