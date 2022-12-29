% Test Code
% Interne Tests mit der Ut803 Klasse
%
% Aufbau:
%  - Ut803 anschließen, und auf COMM Modus stellen
%  - Com Port anpassen
%  - Skript starten
%
% Liest einen Wert direkt, wartet dann und liest den ganzen buffer leer.
%
% Copyright, 2021, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA

% Objekt anlegen
ut = Ut803();
ut.debugLevel=3; % show debug messages

% Adopt com port here!
ut.connect("COM31");

% Get one value
[value, unit] = ut.getValue()
disp("Warte ...");
pause(5); % wait until the serial port buffer fills with some values
disp("Lese alles weg ...");
[value, unit] = ut.getLastValue()

ut.disconnect();
