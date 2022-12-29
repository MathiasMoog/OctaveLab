% Beispiel Code
% Daten einmal abfragen. Das Oszi muss die Kurven anzeigen.

% Instanz anzelgen
pt = Peaktech1265();

% Verbindung aufbauen
pt.connect("192.168.178.72");

% Daten abfragen
pt.getCurves( )
% Einstellungen anzeigen
pt.disp();
% Daten zeichnen
pt.plot( );

% Zum Schluss die Verbindung kappen
pt.disconnect();

% Daten bei Bedarf speichern
M=[pt.t',pt.u'];
%csvwrite("Kondensator.csv",M)
% C = 10 mu F, R= 1 k Ohm, f=6 Hz
