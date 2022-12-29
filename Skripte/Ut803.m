classdef Ut803 < handle
  % Class for serial / usb communication with the UT803 Multimeter
  %
  % Based on the UT803 documentation.
  % UT must be set in RS232 Mode.
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
  % Implemented:
  %  - read measurement
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
    % Einheiten, auf Index aufpassen!
    utEinheit = { "", "", "Hz", "Ohm", "°C", "°C", "F", "", "", "A", "", "V", "", "A", "hFE", "A"};
    % Umrechenfaktoren
    utFaktor = [...
    NA, NA, 1e0, 0.1e0, 1e0, 0.1e0, 0.001e-9, NA, NA, 0.01e0, NA, 0.001e0, NA, 0.1e-6, 1, 0.01e-3;
    NA, NA, 0.01e3, 1e0, NA, 1e0, 0.01e-9, NA, NA, NA, NA, 0.01e0, NA, 1e-6, NA, 0.1e-3;
    NA, NA, 0.1e3, 0.01e3, NA, 0.01e3, 0.1e-9, NA, NA, NA, NA, 0.1e0, NA, NA, NA, NA;
    NA, NA, 1e3, 0.1e3, NA, 0.1e3, 0.001e-6, NA, NA, NA, NA, 1e0, NA, NA, NA, NA;
    NA, NA, 0.01e6, 1e3, NA, 1e3, 0.01e-6, NA, NA, NA, NA, 0.1e-3, NA, NA, NA, NA;
    NA, NA, NA, 0.01e6, NA, 0.01e6, 0.1e-6, NA, NA, NA, NA, NA, NA, NA, NA, NA;
    NA, NA, NA, NA, NA, NA, 0.1e-6, NA, NA, NA, NA, NA, NA, NA, NA, NA;
    NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA];

  endproperties

  % Public methods
  methods (Access = public)

    % Create Instance and load instrument-control package
    function obj = Ut803( )
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
      obj.dprintf(2,"UT 803, connect with port %s\n",com);
      % siehe https://gnu-octave.github.io/packages/instrument-control/
      obj.serialPort = serialport( com, "BaudRate", 19200, "Timeout", 0.3, ...
        "DataBits", 7, "StopBits", 2, "Parity", "none" );
      setDTR( obj.serialPort, true );
      setRTS( obj.serialPort, false );
      % Read one line, provide clean start for next method calls.
      serialPortReadLine( obj.serialPort, "\n" );
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
      l = serialPortReadLine( obj.serialPort, "\n" );
      [value, unit] = obj.parseLine( l );
    end

    % Get last value
    % Nützlich im COMM Modus wenn nicht ganz regelmäßig Daten abgeholt werden,
    % Dann können mehrer Messwerte im Buffer des serial port liegen.
    % Lese alle weg, werte nur die letzte aus.
    function [value, unit] = getLastValue( obj );
       set( obj.serialPort, "TimeOut", 3.0 ); % Longer timeout, wait for first value
       l = [];
       do
         lastLine = l;
         l = serialPortReadLine( obj.serialPort, "\n" );
         set( obj.serialPort, "TimeOut", 0.1 ); % Shorter timeout, fetch from buffer
         obj.dprintf(3,"l=%s\n",l);
       until ( isempty(l) );

      [value, unit] = obj.parseLine( lastLine );
    endfunction

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

      if (length(l)!=10)
        unit=["Invalid Data: " l];
        return;
      endif
      % split line
      bereich = bitand( l(1)+0, 0x7);
      wert = substr(l,2,4);
      schalter = bitand(l(6)+0,0xf);
      info = bitand( l(7)+0, 0xf );
      kopplung = bitand( l(9)+0, 0xf );

      % extract unit
      unit = obj.utEinheit{ schalter +1 };


      % Numerischen Wert zur entsprechenden Einheit
      value = str2double(wert)*obj.utFaktor(bereich+1,schalter+1);
      % Kopplung mit an die Einheit anhängen
      if (bitget(info,1))
        value = NA;
      endif
      if (bitget(kopplung,3))
        unit = [ unit, " (AC)" ];
      endif
      if (bitget(kopplung,4))
        unit = [ unit, " (DC)" ];
      endif

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

