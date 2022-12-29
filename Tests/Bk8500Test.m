% Test Code
% Interne Tests mit der BK8500 Klasse
% Nur für die Weiterentwicklung der BK8500 Klasse nutzen
% Copyright, 2021, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA

% Objekt anlegen
bk = Bk8500();

disp(" Verbindungstest - bitte Port anpassen und einkommentieren." )
%bk.connect( "COM37" )
%pause(0.1);
%[voltage, current, power] = bk.getState()
%bk.disconnect()

disp(" Prüfsumme testen " )
bk.createCommand( 128 )
bk.printHex( bk.command )
cs = bk.checksum( bk.command )
assert( cs == 42 );

bk.createCommand( 128, 42 )
bk.printHex( bk.command )
cs = bk.checksum( bk.command )
assert( cs == 84 );

disp(" Encode, decode Testen ");
for k=1:10
  a = uint32( randi(2^32-1) )
  bk.encode(4, a )
  bk.printHex( bk.command )
  bk.answer=bk.command;
  A = bk.decode(4)
  assert(a==A)
endfor
