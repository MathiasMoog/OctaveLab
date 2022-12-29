% Einfaches Skript zum Erfassen von Messwerten
% Mit dem Fluke Messinstrument 8808A
% Copyright, 2021, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA

% Instanz anlegen
fl = Fluke8088A();

% Öffne den Com Port
fl.connect( "COM39" )

% Zeige Seriennummer an
fl.getVersion( )

% Spannung auf primären Display
%srl_write( s, "VDC\n" );
% Strom auf sekundärem Display
%srl_write( s, "ADC2\n" );

% lange warten bis alles bereit ist
%pause(5);

% Primäres Display lesen
v1 = fl.getMeasurement( "1" )
% Sekundäres Display lesen
%v2 = fl.getMeasurement( s, "2" )

% Schließe serielle Schnittstelle
fl.disconnect( );
