% Test des Octave Interfaces zum Ut8803e


% Instanz erzeugen
ut = Ut8803e();

% Verbinden
ut.connect();

% Einen Werte lesen
[v,u] = ut.getValue()


[v,u] = ut.getLastValue()


ut.disconnect()

ut=[];

