E% Metrex4650Cr Beispiel, Daten einzeln anfordern (nicht im COMM Modus)
% Siehe Kommentare in der Klasse Metrex4650Cr
%
% Aufbau und Verwendung
%  - Datenkabel an Messgeräte anschließen. Richtung beachten!
%  - Datenkabel mit COM Port oder COM Adapter an den Rechner anschließen
%  - COM Port im Skript eintragen
%  - Skript ausführen.
%  - COMM Taste am Messgeräte drücken, ab jetzt werden Daten gesendet.
%    Taste COMM, Display COM
%  - Skript mit "E" auf der Kommandzeile anhalten
%
% Copyright, 2014, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA

% Lege Instanz an
me = Metrex4650Cr();

% Öffne Com Port
me.connect("COM31");

% Messungen abholen, die kommen automatisch nur im COMM Modus
running=1
while (running)
  [value, unit] = me.getValue()
  x = kbhit (1);
	if (strcmp(x,"E"))
    running = 0;
    disp("Breche ab");
  endif
endwhile

% alles schließen
me.disconnect()
