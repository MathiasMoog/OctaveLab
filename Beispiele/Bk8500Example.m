% Beispiel Code zur Ansteuerung der elektronischen Last BK8500
% Leerlaufspannung und Kurzschussstrom ermitteln.
%
% Zur einefachen Fehlersuche werden alle Rückgabewerte der Aufrufe ausgegeben.
% Im Erfolgsfall sollte ok? immer 1 sein.
%
% Copyright, 2021, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA

% Objekt anlegen
bk = Bk8500();
%bk.debug=true; % Debug Ausgaben einschalten

% Verbindung aufbauen
bk.connect( "COM37" )

% Fernbedienung aktivieren
ok1 = bk.remoteOperation( 1 )
pause(0.1);

% Status abfragen
[u,i,p] = bk.getState()

% Kurzschussstrom ermitteln
% Setzte Spannung auf 100 mV, darunter instabil
ok2 = bk.operationMode( 1 ) % CV - constant Voltag
ok3 = bk.setVoltage( 100 ) % set to 100 mV
ok4 = bk.loadOnOff( 1 ) % Switch load on
pause(1.5); % Warte bis die Werte stabil sind

% Status abfragen
[u,i,p] = bk.getState()

% Close connection
ok5 = bk.loadOnOff( 0 ) % Switch load off
ok6 = bk.remoteOperation( 1 ) % disable remot operation
bk.disconnect()

