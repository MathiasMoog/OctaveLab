% Test Code
% Interne Tests mit der Metrix4650 Klasse
%
% Aufbau:
%  - Metrex 4650 CR anschließen, und auf COMM Modus stellen
%  - Com Port anpassen
%  - Skript starten
%
% Liest einen Wert direkt, wartet dann und liest den ganzen buffer leer.
%
% Copyright, 2021, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA

% Objekt anlegen
me = Metrex4650Cr();
me.debugLevel=3; % show debug messages

% Adopt com port here!
me.connect("COM31");

% Get one value
me.getValue();
disp("Warte ...");
pause(7); % wait until the serial port buffer fills with some values
disp("Lese alles weg ...");
me.getLastValue();

me.disconnect();
