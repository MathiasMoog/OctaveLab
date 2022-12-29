% Experiment zur Kommunikation mit dem KORAD KA3005P Netzgerät
% Siehe Kommentare in der Klasse KA3005P
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
%rd.connect("COM32")
rd.connectTcp("192.168.178.67")
rd.getVersion()

datestr( rd.getDate() )
rd.setDate( now() )

% Lese die Temperatur aus
Ti = rd.getTemp()
Te = rd.getExtTemp()
% Lese Eingangsspannung
Uin = rd.getInputVoltage()

% Lese die eingestellte Ausgangsspannung, setze sie danach
Umax = rd.getMaxVoltage()
rd.setMaxVoltage(12.34)

% Lese den eingestellten Ausgangsstrom, setze sie danach
Imax = rd.getMaxCurrent()
rd.setMaxCurrent(1.23)

% Lese Spannung, Strom und Leistung
u = rd.getVoltage()
i = rd.getCurrent()
p = rd.getPower()

rd.setOnOff( 1 )
pause(0.3)
% Lese Spannung, Strom und Leistung
u = rd.getVoltage()
i = rd.getCurrent()
p = rd.getPower()

rd.setOnOff( 0 )

% Konfiguriere Grenzen für Sweep
rd.setMaxVoltage(0);
rd.setMaxCurrent(2);
rd.setOnOff( 1 );

[ Uv, Iv ] = rd.voltageSweep( 0:.5:13, .7 )

[ Ur, Ir ] = rd.voltageSweep( 13:-.5:0, .7 )

% aus schalten
rd.setOnOff( 0 );


% Ausgaben
plot(Uv,Iv, "*-", Ur,Ir, "*-");
xlabel("U");
ylabel("I");
legend("Aufsteigend", "Absteigend");

% Bei Bedarf die Kennline abspeichern.
%csvwrite("test.csv", [Uv', Iv', Ur', Ir'] );


% alles schließen
rd.disconnect();

