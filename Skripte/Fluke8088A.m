classdef Fluke8088A < handle
  % Class for serial / usb communication with the Fluke 8088A Multimeter
  %
  % Based on the Fluke documentation.
  %
  % Uses the instrument-control extension srl_getl
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
  % Missing:
  %  - Everything else
  %
  % Copyright, 2021, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA

  properties
    % Serial Port Handle
    serialPort=[];
    % Debug Level, default is 0 (erros)( 1- warning, 2- info, during developement up to 3)
    debugLevel=3;
  end

  % Public methods
  methods (Access = public)

    % Create Instance and load instrument-control package
    function obj = Fluke8088A( )
      % Lade die package
      pkg load instrument-control
    end

    % Connect to power supply. Open com port, correct windows com port, set interal port handle
    function ok = connect( obj, com )
      % Window COM Port correction
      % Open com port on windows with \\.\ correction.
      % Applies only if com starts with "COM", otherwiee the port is passed
      if (startsWith(com,"COM"))
        com =  [ "\\\\.\\" com ] ;
      end
      obj.dprintf(2,"Fluke8088A, connect with port %s\n",com);
      % timeout ca. 100 ms, siehe http://wiki.octave.org/Instrument_control_package
      obj.serialPort = serialport( com, "BaudRate", 9600, ...
        "Timeout", 0.2, "DataBits", 8, "StopBits", 1, ...
        "Parity", "none");
      pause(0.5)      % Warte ein klein wenig
      readline( obj.serialPort )   % Lese die begrüßung
    end

    % Disconnect from power supply. Close com port
    function disconnect( obj )
      obj.serialPort = [];
    end

    % Get version and serial number
    function idn = getVersion( obj )
      write( obj.serialPort, "*IDN?\n" );
      flush( obj.serialPort, "output" );% Output Flushend
      idn = readline( obj.serialPort );
    end

    % Set Rate, and check it ... S slow, M medium, F fast
    function r = setRate( obj, rate )
      write( obj.serialPort, ["RATE ", rate, "\n"] );
      flush( obj.serialPort, "output" );% Output Flushend
      % todo, Ausgabestrom leer lesen!
      readline( obj.serialPort );
      readline( obj.serialPort );
      r = obj.getRate();
    end

    function r = getRate( obj )
      write( obj.serialPort, "RATE?\n" );
      r = serialPortReadLine( obj.serialPort, 13 );
    endfunction

    % Aktuellen Messwert einlesen
    % i "1" oder "2"
    function v = getMeasurement( obj, i )
      flush( obj.serialPort, "input" );% Output Flushend
      write( obj.serialPort, [ "VAL", i, "?\n" ] );
      flush( obj.serialPort, "output" );% Output Flushend
      versuche=0;
      do
        pause(0.1);
        l = serialPortReadLine( obj.serialPort, 13 );
        if ( length(l)>0)
          [v, c] = sscanf(l, "%f");
          if (c==1)
            return
          end
        end
        versuche++;
      until versuche>5;
      v=NA
    end

  % End of public methods
  end

  % ----------------------------------------------------------------------------
  % Protected methods - at the moment public, change later on to protected
  methods (Access = public)

    % Debug output, like printf, but debug level as first argument.
    function dprintf(obj, level, varargin )
      if (level <= obj.debugLevel)
        printf(varargin{:});
      end
    end

  % End of protected methods
  end

end




