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
      % 1 als timeout ca. 100 ms, siehe http://wiki.octave.org/Instrument_control_package
      obj.serialPort = serial(  com , 9600, 2 );
      pause(0.5)      % Warte ein klein wenig
      srl_getl( obj.serialPort, '\n' )   % Lese die begrüßung
    end

    % Disconnect from power supply. Close com port
    function disconnect( obj )
      fclose( obj.serialPort );
      obj.serialPort = [];
    end

    % Get version and serial number
    function idn = getVersion( obj )
      srl_write( obj.serialPort, "*IDN?\n" );
      idn = srl_getl( obj.serialPort, '\n' );
    end

    % Aktuellen Messwert einlesen
    % i "1" oder "2"
    function v = getMeasurement( obj, i )
      srl_write( obj.serialPort, [ "VAL", i, "?\n" ] );
      versuche=0;
      do
        pause(0.1);
        l = srl_getl( obj.serialPort, '\n' );
        if ( l!=-1)
          [v, c] = sscanf(l, "%f");
          if (c==1)
            return
          end
        end
        versuche++;
      until versuche>25;
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




