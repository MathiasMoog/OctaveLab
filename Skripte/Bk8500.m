% Klasse zum Ansteuern und Auslesen der BK8500 Lasten
% Beispiele anschauen ...
% Dieser Code kann nur so viel wie ich gerade benötige. Bei Bedarf erweitern.
% Die Methoden sind ähnlich zu dem Java Code zur Ansteuerung des BK8500.
%
% Den Pfad zu diesem Skript mit in den Suchpfad aufnehmen, z.B.
% addpath( "OctaveElektro/Skripte" );
%
% Installation der instrument-control package mit
% pkg -forge install instrument-control
% Anleitung: https://octave.sourceforge.io/instrument-control/index.html
%
% Spezifikation des Protokolls entsprechend der Hersteller Anleitung des
% BK8500. Online unter
% https://www.bkprecision.com/support/downloads/manuals/en/
%
% Copyright, 2021, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA
%
classdef Bk8500  < handle

  % properties, constants
  properties (Constant = true)
    % Constant length of commands and answers
	  n=26;
  endproperties

  % properties (should be internal, rw access)
  properties ( Access = public )
    % Command array
    command = [];
	  % Answer array
	  answer = []
	  % Serial port
	  s = [];
	  % Debug flag
	  debug = false;
	  % End of properties
  end


  methods
    % Public methods like in Java interface

    % Create Instance and load instrument-control package
    function obj = Bk8500()
      % Lade die package
      pkg load instrument-control
    endfunction

	  % Open com port, automatic correction for Windows Com port names.
    % Set internal handle to serial port
	  function ok = connect( obj, com )
      % Window COM Port correction
      % Open com port on windows with \\.\ correction.
      % Applies only if com starts with "COM", otherwise the port is passed
      if (startsWith(com,"COM"))
        com =  [ "\\\\.\\" com ] ;
      end
      % 1 als timeout ca. 100 ms, siehe http://wiki.octave.org/Instrument_control_package
      obj.s = serial(  com , 9600, 1 );
      ok = !isempty( obj.s );
      % Initialisiere die Arrays
      obj.command = uint8(zeros(1,BK8500.n));
      obj.answer  = uint8(zeros(1,BK8500.n));
      % Etwas warten bis das Gerät wirklich bereit ist
      pause(0.1);
	  end

	  % Close com port
	  function disconnect( obj )
	    pause(0.1);
      fclose( obj.s );
	  end

	  % 0x20 DC-Last auf ferngesteuerten Betrieb einstellen.
    % remote on - true - 1  / off - false - 0
    % return true on success
    function ok = remoteOperation(obj, remote)
        obj.createCommand(0x20, uint8(remote) );
        ok = obj.sendCommand() && obj.correctReply();
	  end

	  % 0x21 DC-Last ein- oder ausschalten.
    % onOff on - true - 1 / off - false - 0
    % return true on success
    function ok = loadOnOff(obj, onOff)
        obj.createCommand(0x21, uint8(onOff) );
        ok = obj.sendCommand() && obj.correctReply();
	  endfunction

	  % 0x28 Betriebsart einstellen.
    % mode operation mode: 0 - CC / 1 - CV / 2 - CW / 3 - CR
    % true onn success
    function ok = operationMode(obj, mode)
        obj.createCommand(0x28, uint8(mode));
        ok = obj.sendCommand() && obj.correctReply();
    endfunction

	  % 0x2A Strom einstellen.
    % current in 0.1 mA
    % return true onn success
    function ok = setCurrent( obj, current)
        obj.createCommand(0x2A);
        obj.encode(4, uint32(current));
        ok = obj.sendCommand() && obj.correctReply();
    endfunction

	  % 0x2B Eingestellten Strom einlesen.
    % return >=0 Strom in 1e-4 A, -1 Fehler
    function strom = getCurrent(obj)
        obj.createCommand(0x2B);
        if (!obj.sendCommand())
            strom = -1;
        else
         strom = obj.decode(4);
		  endif
	  endfunction

	  % 0x2C Spannung einstellen.
    % voltage in 1 mV
    % return true on success
    function ok = setVoltage(obj, voltage)
        obj.createCommand(0x2C);
        obj.encode(4, uint32(voltage));
        ok = obj.sendCommand() && obj.correctReply();
	  endfunction

	  % 0x2D eingestellte Spannung einlesen.
    % return >=0 Spannung in mV, -1 Fehler
    function spannung =  getVoltage(obj)
        obj.createCommand(0x2D);
        if (!obj.sendCommand())
          spannung =  -1;
        else
          spannung = obj.decode(4);
        endif
	  endfunction

	  % 0x5F Status abfragen.
    % on success voltage in V, current in A and power in W
    function [voltage, current, power] = getState(obj)
        obj.createCommand(0x5F);
        if (!obj.sendCommand())
          voltage = -1;
			    current = -1;
			    power = -1;
        else
          voltage = 1e-3*double(obj.decode(4));
          current = 1e-4*double(obj.decode(8));
          power   = 1e-3*double(obj.decode(12));
        endif
    endfunction



    % -------------------------------------------------------------------------------------------
    % Internal methods follow here, not jet separated.

	  % Add integer value to command
	  % versatz byte in command structure
	  % value to be encoded
    function encode(obj, versatz, value)
      value = uint32(value);
      obj.command(versatz) = uint8( bitand(value,0x000000FF) );
      obj.command(versatz+1) = uint8( bitand(bitshift(value,-8,32), 0x000000FF));
      obj.command(versatz+2) = uint8( bitand(bitshift(value,-16,32), 0x000000FF));
      obj.command(versatz+3) = uint8( bitand(bitshift(value,-24,32), 0x000000FF));
	  endfunction

	  % Read integer value from command / answer.
	  % versatz byte in command structure
	  % vlaue - return integer value
	  function value = decode(obj, versatz)
      value = uint32(0);
      value = bitor( value, bitshift(uint32(obj.answer(versatz + 3)), 24, 32));
      value = bitor( value, bitshift(uint32(obj.answer(versatz + 2)), 16, 32));
      value = bitor( value, bitshift(uint32(obj.answer(versatz + 1)), 8, 32));
      value = bitor( value, uint32(obj.answer(versatz)) );
	  endfunction

	  % Calculate checksum for command.
	  % command
	  % return  calculated checksum
	  function cs = checksum(obj, command)
      cs = uint8(mod(sum(command(1:25)),256));
	  endfunction

	% Create basic entries for a command.
	% c - command code (Byte number 3)
	% v - value byte, byte number 4, default 0
    function createCommand(obj, c, v=0)
	    obj.command = uint8(zeros(1,BK8500.n));
      obj.command(1) = 0xAA;
      obj.command(3) = uint8(c);
      obj.command(4) = uint8(v);
    endfunction

	% Calculate checksum and add to a command.
    function addChecksum(obj)
        obj.command(obj.n) = obj.checksum(obj.command);
    endfunction

	% Print command as hex string
	function printHex( obj, command )
	  printf("%02x",command);
	  printf("\n");
	endfunction

	% Check for valid reply.
	function valid = correctReply(obj)
	  valid = (obj.answer(3) == uint8(0x12)) && (obj.answer(4) == uint8(0x80));
	endfunction

	% Send command
	% Add checksum to existing obj.command and send. Recive answer, check checksum
  % store answer in obj.answer
	function ok = sendCommand( obj )
	  obj.addChecksum();
    if (obj.debug)
        printf( "Send " ); + obj.printHex(obj.command);
    endif
    c = obj.checksum(obj.command);
    if (obj.debug)
        printf("Expected Checksum = %02x\n",c );
    endif
    srl_write(obj.s, obj.command);
    srl_flush(obj.s);
    pause(0.02);
	  obj.answer = srl_read(obj.s, 26);
    if (obj.debug)
         printf("Receive " );  obj.printHex(obj.answer);
    endif
    c = obj.checksum(obj.answer);
    if (obj.debug)
        printf("Expected Checksum = %02x, found %02x\n", c, obj.answer(obj.n));
    endif
    ok = (c == obj.answer(obj.n));
	endfunction

  endmethods
endclassdef



