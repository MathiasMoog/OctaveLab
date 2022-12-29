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
% Copyright, 2021, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA


% Instanz anlegen
ka = KA3005P();

% Com Port öffnen, bitte Anpassen ...

ka.connect("COM38")
%ka.connect("/dev/ttyACM0")
ka.getVersion()

% Spannungs - Strom Kennlinien
% Erst mal Spannung auf 0
ka.setVoltage( 0);
% Maximal Strom 2 A
ka.setCurrent( 2);
% an schalten
ka.setOnOff( 1);

[ Uv, Iv ] = ka.voltageSweep( 0:.5:13, .1 )

[ Ur, Ir ] = ka.voltageSweep( 13:-.5:0, .1 )

% aus schalten
ka.setOnOff( 0 );


% Ausgaben
plot(Uv,Iv, "*-", Ur,Ir, "*-");
xlabel("U");
ylabel("I");
legend("Aufsteigend", "Absteigend");

% Bei Bedarf die Kennline abspeichern.
%csvwrite("test.csv", [Uv', Iv', Ur', Ir'] );


% alles schließen
ka.disconnect();

