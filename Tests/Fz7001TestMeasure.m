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

disp("Auflösung setzen");
fz.setResolution( 5 )

disp("Messen bis E gedrückt.");
running=1
while (running)
  [value,unit] = fz.measure()
  x = kbhit (1);
	if (strcmp(x,"E"))
    running = 0;
    disp("Breche ab");
  endif
  pause(1);
endwhile

disp("Verbindung beenden");
fz.disconnect()

