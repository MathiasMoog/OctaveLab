% Experiment zur Kommunikation mit dem KORAD KA3005P Netzgerät
% Siehe Kommentare in der Klasse Rd6006
%
% Umgang mit den Speichern. Es sind die Speicher 0 bis 9 vorhanden.
% Der einzige Weg zum setzen von OVP und OCP ist meines Wissens diese in den
% Speicher zu schreiben und dann den Speicher aufzurufen.
%
% Aufbau und Verwendung
%  - Netzgerät anschalten und mit dem Rechner verbinden
%  - Elektronische Last im CR Modus mit 20 Ohm oder
%    12 V Lampe (minmal 12 W) an das Netzgerät anschließen
%  - Com Port anpassen
%  - Dieses Skript starten
%
% Copyright, 2022, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA


% Instanz anlegen
rd = Rd6006();

% Com Port öffnen, bitte Anpassen ...
rd.connect("COM32")
%ka.connect("/dev/ttyACM0")
rd.getVersion()

% Read memory 0
n  = rd.getData()
i0 = rd.getDataCurrent(0)
u0 = rd.getDataVoltage(0)
i0ocp = rd.getDataOCP(0)
u0ovp = rd.getDataOVP(0)

% Set Memory 0
rd.setDataCurrent(0,2.0)
rd.setDataVoltage(0,12.0)
rd.setDataOCP(0,3.5)
rd.setDataOVP(0,15.1)

% Wähle Speicher an
rd.setData(0)

% aus schalten
rd.setOnOff( 1 );

pause(2)

% aus schalten
rd.setOnOff( 0 );



% alles schließen
rd.disconnect();

