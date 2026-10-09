classdef VC870 < handle
  % Class for serial / usb communication with the VC870 Multimeter
  %
  % Based on the VC870 documentation.
  % UT must be set in communication mode with a long press on REL/PC.
  %
  % Uses the instrument-control extension serialPortReadLine
  %
  % Den Pfad zu diesem Skript mit in den Suchpfad aufnehmen, z.B.
  % addpath( "OctaveElektro/Skripte" );
  %
  % Installation der instrument-control package mit
  % pkg -forge install instrument-control
  % Anleitung: https://octave.sourceforge.io/instrument-control/index.html
  %
  % Hid and Octave ...
  %  - https://stackoverflow.com/questions/50781503/talk-to-an-usb-hid-device-from-within-gnu-octave
  %    Use instrument control, usbtmc, but the VC870 is not an usbtmc device
  %  - http://psychtoolbox.org/docs/PsychHID
  %    Different Application, list HID devices,
  %
  % Implementation details:
  %
  % Auszug aus https://sigrok.org/wiki/Voltcraft_VC-870
  % Siehe Elekto/Laborgeraete/VoltcraftVC870
  % SigrokVoltcraft_VC-870.pdf und 124603-in-01-en-Interfaceprotokoll_VC_870_DMM.pdf
  %
  % Byte(s) 	Name 	Description
  % 0 	Function code 	Bytes 0 and 1 determine the measurement mode.
  % 1 	Function select code 	Bytes 0 and 1 determine the measurement mode.
  % 2 	Range
  % 3-7 	5 main display digits
  % 8-12 	5 auxiliary display digits
  % 13 	?
  % 14 	?
  % 15 	Status 	bit 2 vorzeichen
  % 16 	Option 1
  % 17 	Option 2
  % 18 	Option 3
  % 19 	Option 4
  % 20 	Dual display
  % 21 	Line feed 	Always 10 / 0x0a.
  % 22 	Carriage return 	Always 13 / 0x0d.
  %
  % Measurement modes:
  % Function code 	Function select code 	Measurement mode
  % 0x30 	0x30 	DCV
  % 0x30 	0x31 	ACV
  % 0x31 	0x30 	DCmV
  % 0x31 	0x31 	Temperature (Celsius and Fahrenheit)
  % 0x32 	0x30 	Resistance
  % 0x32 	0x31 	Continuity
  % 0x33 	0x30 	Capacitance
  % 0x34 	0x30 	Diode
  % 0x35 	0x30 	Frequency
  % 0x35 	0x31 	Loop current, (4-20mA)%
  % 0x36 	0x30 	DCuA
  % 0x36 	0x31 	ACuA
  % 0x37 	0x30 	DCmA
  % 0x37 	0x31 	ACmA
  % 0x38 	0x30 	DCA
  % 0x38 	0x31 	ACA
  % 0x39 	0x30 	Active/real power + apparent power
  % 0x39 	0x31 	Power factor + frequency
  % 0x39 	0x32 	Voltage effective value + current effective value
  %
  % Implemented:
  %  - copy from java code
  %
  %
  % Copyright, 2021, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA

  properties
    % Serial Port Handle
    serialPort=[];
    % Debug Level, default is 0 (erros)( 1- warning, 2- info, during developement up to 3)
    debugLevel=3;
  end

  properties (Constant = true)
    % Function codes
    func_code = [ ... % bytes 0 und 1
        '00'; ... % index  0, DCV
        '01'; ... % index  1, ACV
        '10'; ... % index  2, DCmV
        '11'; ... % index  3, C
        '20'; ... % index  4, Ohm
        '21'; ... % index  5, CTN Ohm
        '30'; ... % index  6, F
        '40'; ... % index  7, Diode
        '50'; ... % index  8, Hz
        '51'; ... % index  9, 4 .. 20 mA, %
        '60'; ... % index  10, DCmuA
        '61'; ... % index  11, ACmuA
        '70'; ... % index  12, DCmA
        '71'; ... % index  13, ACmA
        '80'; ... % index  14, DC A
        '81'; ... % index  15, AC A
        '90'; ... % index  16, W
        '91'; ... % index  17, W
        '92'; ... % index  18, V
    ];
    % Einheiten, auf Index aufpassen!
    einheit = ... % Anhand FUNCTION index
        ["V", "V", "V", "°C", "\u2126", "\u2126", "F", "V", "Hz", "%", ...
         "A", "A", "A", "A", "A", "A", "W", "W", "V" ];
    % Umrechenfaktoren
    % erste dim. FUNCTION index, zweite, byte 8, unterste drei bits
    % noch nicht alle Messbereiche durchprobiert, - OK für die getesteten, sonst - ?
    factor = [ ...
         1e-4 , 1e-3 , 1e-2 , 1e-1, -1  , -1  , -1  , -1 ; ... % index 0, V - OK
         1e-4 , 1e-3 , 1e-2 , 1e-1, -1  , -1  , -1  , -1 ; ... % index 1, V - OK
         1e-5 , -1   , -1   , -1  , -1  , -1  , -1  , -1 ; ... % index 2, mV - OK
         1e-2 , -1   , -1   , -1  , -1  , -1  , -1  , -1 ; ... % index 3, C ?? - ?
         1e-2 , 1e-1 , 1e-0 , 1e+1, 1e+2, 1e+3, -1  , -1 ; ... % index 4, Ohm - OK
         1e-2 , 1e-1 , 1e-0 , 1e+1, 1e+2, 1e+3, -1  , -1 ; ... % index 5, Ohm, ctn? - ?
         1e-12, 1e-11, 1e-10, 1e-9, 1e-8, 1e-7, 1e-6, -1 ; ... % index 6, F - ?
         1e-4 , -1   , -1   , -1  , -1  , -1  , -1  , -1 ; ... % index 7, Diode ?? -?
         1e-4 , -1   , -1   , -1  , -1  , -1  , -1  , -1 ; ... % index 8, Hz -?
         1e-5 , -1   , -1   , -1  , -1  , -1  , -1  , -1 ; ... % index 9, 4 .. 20 mA, % -?
         1e-8 , 1e-7 , -1   , -1  , -1  , -1  , -1  , -1 ; ... % index 10, muA - OK
         1e-8 , 1e-7 , -1   , -1  , -1  , -1  , -1  , -1 ; ... % index 11, muA - OK
         1e-6 , 1e-5 , -1   , -1  , -1  , -1  , -1  , -1 ; ... % index 12, mA - OK
         1e-6 , 1e-5 , -1   , -1  , -1  , -1  , -1  , -1 ; ... % index 13, mA - OK
         1e-3 , -1   , -1   , -1  , -1  , -1  , -1  , -1 ; ... % index 14, A - OK
         1e-3 , -1   , -1   , -1  , -1  , -1  , -1  , -1 ; ... % index 15, A - OK
         1e-1 , -1   , -1   , -1  , -1  , -1  , -1  , -1 ; ... % index 16, W ?
         1e-1 , -1   , -1   , -1  , -1  , -1  , -1  , -1 ; ... % index 17, W ?
         1e-1 , -1   , -1   , -1  , -1  , -1  , -1  , -1 ; ... % index 18, V ?
    ];

  endproperties

  % Public methods
  methods (Access = public)

    % Create Instance and load instrument-control package
    function obj = VC870( )
      % Lade die package
      pkg load instrument-control
    end

    % Connect to power supply. Open com port, correct windows com port, set interal port handle
    function ok = connect( obj, com )
      % Window COM Port correction
      % Open com port on windows with \\.\ correction.
      % Applies only if com starts with "COM", otherwise the port is passed
      if (startsWith(com,"COM"))
        com =  [ "\\\\.\\" com ] ;
      end
      obj.dprintf(2,"VC870, connect with port %s\n",com);
      % siehe https://gnu-octave.github.io/packages/instrument-control/
      obj.serialPort = serialport( com, "BaudRate", 9600, "Timeout", 0.3 );
      % Read one line, provide clean start for next method calls.
      serialPortReadLine( obj.serialPort, "\r" );
    end

    % Disconnect from power supply. Close com port
    function disconnect( obj )
      %fclose( obj.serialPort );
      obj.serialPort = [];
    end

    % Messdaten abholen.
    % Nutzbar wenn das Gerät im RS232 Modus (regelmäßige Übertragung) ist.
    % Liefert den numerischen Wert (dezimale Vielfache eingerechnet) und die
    % Einheit. An die Einheit wird ggf. (DC) oder (AC) angehängt.
    % Diese Funktion liefert das erste Ergebniss im Puffer des Seriellen Ports.
    function [value, unit] = getValue( obj )
      set( obj.serialPort, "TimeOut", 3.0 ); % Longer timeout, at least one value
      l = serialPortReadLine( obj.serialPort, "\n" )
      [value, unit] = obj.parseLine( l )
    end


  % End of public methods
  end

  % ----------------------------------------------------------------------------
  % Protected methods - at the moment public, change later on to protected
  methods (Access = public)

    % Parse one received line ...
    function [value, unit] = parseLine( obj, l )
      value=NA;
      unit="";
      % check line
      if (isempty(l))
        unit="No Data";
        return;
      endif;

      if (length(l)!=22)
        unit=["Invalid Data length: " l];
        return;
      endif

      % find index corresponding to function code (first two bytes)
      ff = line(1:2);
      fc = strcmp(ff,obj.function_code)
      if (sum(fc)!=1)
        unit=["Invalid function code: " ff];
        return;
      endif
      nfc = length(fc);
      fc = (1:nfc)(fc)

      % Find factor depending on function code and third byte
      factor = line(3)&0x07
      factor = obj.factor(fc,factor)
      if (factor<0)
        unit=["Invalid factor : " factor];
        return;
      endif

      % Convert main display
      value = str2num( line(4:8) );
      % Extract sign
      sign = 1
      if (bitget( line(16), 2 ))
        sign = -1
      endif

      % Finish ...
      value = sign*value * factor
      unit  = einheit(fc);

    endfunction


    % Debug output, like printf, but debug level as first argument.
    function dprintf(obj, level, varargin )
      if (level <= obj.debugLevel)
        printf(varargin{:});
      end
    end

  % End of protected methods
  end

end

