% Beispiel Code zur Ansteuerung der elektronischen Last BK8500
% U-I-Kennlinie ermitteln.
%
% Aufbau:
%  - BK8500 mit PV Modul oder Netzgerät (und PV Modulersatz) verbinden
%  - BK8500 über den RS232 nach USB Wandler mit dem PC verbinden
%  - Seriellen Port suchen (Gerätemanager oder Arduino IDE) und in bk.connect(...)
%    Eintragen
%  - Skript starten ...
%
% Verwendung:
%  - Vermessen von PV Modul Kennlinien
%
% Copyright, 2021, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA

% Anzahl der Punkte auf der Kennlinie
n=10;

% Objekt anlegen
bk = BK8500();
%bk.debug=true; % Debug Ausgaben einschalten

% Verbindung aufbauen - Hier den passenden Com Port eintragen
bk.connect( "COM37" )

% Fernbedienung aktivieren
bk.remoteOperation( 1 );
bk.loadOnOff( 0 ); % Switch load off
pause(0.1);

% Status abfragen -> ergibt Leerlaufspannung
u_leerlauf = bk.getState()
printf("Leerlaufspannung %.3f V\n");

bk.operationMode( 1 ); % CV - constant Voltage
% Setzte Spannung auf 100 mV, darunter instabil
bk.setVoltage( 100 ); % set to 100 mV
bk.loadOnOff( 1 ); % Switch load on
pause(0.5); % Warte bis die Werte stabil sind

K=[]; % Array für die Kennlinie: Spalte 1 u; Spalte 2 i; Spalte 2 p
% Schleife über die Spannung
for us=linspace(100,u_leerlauf*1000,n)
  bk.setVoltage( us ); % set to 100 mV
  pause(1.0); % Warte bis die Werte stabil sind
  [u,i,p] = bk.getState() % Messen
  printf("u=%5.2f V i=%5.2f A p=%5.2f W\n",u,i,p);
  K=[K;[u,i,p]]; % Merke
  ax = plotyy(K(:,1),K(:,2), K(:,1),K(:,3)); % Zeichne Strom und Leistung über Spannung
  xlabel ("Spannung in V");
  ylabel (ax(1), "Strom in A");
  ylabel (ax(2), "Leistung in W");
endfor

% Close connection
bk.loadOnOff( 0 ); % Switch load off
bk.remoteOperation( 0 ); % disable remot operation
bk.disconnect();

% Bei Bedarf Kennlinie als csv Datei speichern
%csvwrite("Kennlinie.csv",K);

