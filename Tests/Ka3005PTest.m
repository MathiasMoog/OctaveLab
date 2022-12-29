% Test Kommunikation mit dem KORAD KA3005P Netzgerät
% Siehe Kommentare in der Klasse KA3005P
%
% Aufbau und Verwendung
%  - Netzgerät anschalten und mit dem Rechner verbinden
%  - Com Port anpassen
%  - Dieses Skript starten
%
% Copyright, 2021, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA


% Instanz anlegen
ka = Ka3005P();
ka.debugLevel=3;

% Com Port öffnen, bitte Anpassen ...

ka.connect("COM28")
%ka.connect("/dev/ttyACM0")
ka.getVersion()

% Spannungs - Strom Kennlinien
% Erst mal Spannung auf 10
ka.setVoltage( 10)
% Maximal Strom 2 A
ka.setCurrent( 2)
% an schalten
ka.setOnOff( 1)
% jetzt messen
u = ka.getVoltage()
i = ka.getCurrent()
ka.setOnOff( 0 )

% alles schließen
ka.disconnect()

