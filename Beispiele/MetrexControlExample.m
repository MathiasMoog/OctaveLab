% Experiment zur Kommunikation mit dem Metrix M-4650CR Multimeter

% Linux Merker
% pkg install -forge instrument-control

% Lade das Skript mit den Funktionen
MetrexControl;

%s=meStartWin("COM21")
s=meStart("/dev/ttyUSB0")

% Lese Zeilen und gebe sie aus
% Daf?r muss die COMM Taste gedr?ckt werden. Danach erscheint "COM" im Display
% Abbruch durch Eingage von E auf der Tastatur order nach 10 Fehlversuchen
##running=10;
##while (running>0)
##  l = srl_getl( s )
##  if (l==-1)
##    running--;
##  else
##    running=10;
##  endif
##  x = kbhit (1);	
##	if (strcmp(x,"E"))
##    running = 0;
##    disp("Breche ab");
##  endif
##endwhile

% Eine Messung anfordern
% Die COM Taste darf nicht gedr?ckt sein
running=1
while (running)
  [value, unit] = meAcquireValue(s)
  x = kbhit (1)
	if (strcmp(x,"E"))
    running = 0;
    disp("Breche ab");
  endif
  pause(2)
endwhile
  
% Auflaufende Messungen abarbeiten
% Die COM Taste muss ged?rckt sein, dann sendet das Ger?t regelm??ig die Messdaten aus
##running=1
##while (running)
##  [value, unit] = meGetValue(s)
##  x = kbhit (1);	
##	if (strcmp(x,"E"))
##    running = 0;
##    disp("Breche ab");
##  endif
##  pause(2)
##endwhile
  


% alles schlie?en
meEnd(s)
