% Metrex4650Cr Beispiel, Daten einzeln anfordern (nicht im COMM Modus)
% Siehe Kommentare in der Klasse Metrex4650Cr
%
% Aufbau und Verwendung
%  - Datenkabel an Messgeräte anschließen. Richtung beachten!
%  - Datenkabel mit COM Port oder COM Adapter an den Rechner anschließen
%  - COM Port im Skript eintragen
%  - Skript ausführen.
%  - Skript mit "E" auf der Kommandzeile anhalten
%  Achtung: Nicht den COMM Modus am Messgerät aktivieren.
%
% Copyright, 2014, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA

% Lege Instanz an
me = Metrex4650Cr();

% Öffne Com Port
me.connect("COM31");

% Messungen einzeln anfordern
running=1
while (running)
  [value, unit] = me.acquireValue()
  x = kbhit (1);
	if (strcmp(x,"E"))
    running = 0;
    disp("Breche ab");
  endif
  pause(1);
endwhile

% alles schließen
me.disconnect()
