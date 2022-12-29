% Experiment zur Kommunikation mit dem UT 803 Multimeter
% Copyright, 2021, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA

% Lege Instanz an
ut = Ut803();

% Öffne Com Port
ut.connect("COM31");

% Auflaufende Messungen abarbeiten
% Die COM Taste muss gedürckt sein, dann sendet das Gerät regelmäßig die Messdaten aus
running=1
while (running)
  [value, unit] = ut.getValue()
  x = kbhit (1);
	if (strcmp(x,"E"))
    running = 0;
    disp("Breche ab");
  endif
endwhile



% alles schließen
ut.disconnect()
