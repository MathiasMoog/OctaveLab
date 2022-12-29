% Beispiel Code
% Daten dauerhaft abfragen. Das Oszi muss die Kurven anzeigen.

% Funktionen einladen
PeakTech1265;

% Verbindung aufbauen
t0 = ptStart();

do 
  % Daten abfragen
  data = ptAcquire( t0 );  
  % Daten zeichnen
  ptPlot( data );
  ptDisp( data );
  % Warte ein bischen damit es nicht flackert
  pause(0.5);
  % Warte auf ein x
  c=kbhit(1);
until (c=='x');

% Zum Schluss die Verbindung kappen
ptEnd(t0);