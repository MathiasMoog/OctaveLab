% Beispiel Code zur Ansteuerung des Feqzenzzählers FZ 7001 von ELV
%
% Copyright, 2022, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA

% Objekt anlegen
fz = Fz7001();
fz.debugLevel=5; % Debug Ausgaben einschalten

% Verbindung aufbauen
fz.connect( "COM29" )

disp("Status abfragen");
fz.getStatus()
disp("Status auf Betrieb setzen");
fz.setStatus(false)

disp("Auflösung abfragen");
fz.getResolution()
disp("Auflösung setzen");
fz.setResolution( 5 )

% etwas warten bis ausgelesen wird
pause(1)

disp("Einmal Messen");
[value,unit] = fz.measure()

disp("Modus abfragen");
fz.getMode();
disp("Modus auf Periode setzen");
fz.setMode('T');

% etwas warten bis ausgelesen wird
pause(1)

disp("Nocheinmal Messen");
[value,unit] = fz.measure()

disp("Modus auf Frequenz zurücksetzen");
fz.setMode('F');

disp("Relais abfragen");
fz.getCoil()
%disp("Relais setzen");
%fz.setCoil( true )


disp("Verbindung beenden");
fz.disconnect()

