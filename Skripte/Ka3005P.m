classdef Ka3005P < handle
  % Class for serial / usb communication with the Korad KA3005P Power Supply
  % Use also for RND 320-KA3005P
  %
  % Based on Korad Documentation "KA Series Communication Protocol.pdf"
  %
  % Den Pfad zu diesem Skript mit in den Suchpfad aufnehmen, z.B.
  % addpath( "OctaveElektro/Skripte" );
  %
  % Installation der instrument-control package mit
  % pkg -forge install instrument-control
  % Anleitung: https://octave.sourceforge.io/instrument-control/index.html
  %
  % Implemented:
  %  - set and get voltage and current
  %  - switch on and off
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
    function obj = Ka3005P( )
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
      % 1 als timeout ca. 100 ms, siehe http://wiki.octave.org/Instrument_control_package
      obj.serialPort = serial(  com , 9600, 1 );
    end

    % Disconnect from power supply. Close com port
    function disconnect( obj )
      fclose( obj.serialPort );
      obj.serialPort = [];
    end

    % Get version and serial number
    function idn = getVersion( obj )
      srl_write(obj.serialPort, "*IDN?");
      data = srl_read(obj.serialPort, 255);
      idn = char(data);
    end

    % get status, nice printout on info level and return status byte
    function data = getStatus( obj )
      srl_write(obj.serialPort, "STATUS?");
      data = srl_read(obj.serialPort, 1);
      bits = bitunpack(data)
      text={ "ch1 0=cc, 1=cv"; ""; ""; ""; "beep"; "lock"; "output"};
      dprintf(2,"Status\n");
      for i=1:length(text)
        if (length(text{i})>0)
          dprintf(2,"  %s - %d\n",text{i},bits(i));
        endif
      endfor
    end

    % get output current in A
    function i = getCurrent( obj )
      srl_write(obj.serialPort, "IOUT1?" );
      data = srl_read(obj.serialPort, 16);
      i=str2double( char( data ) );
    end

    % get output voltage in A
    function v = getVoltage( obj )
      srl_write(obj.serialPort, "VOUT1?" );
      data = srl_read(obj.serialPort, 16);
      v=str2double( char( data ) );
    end

    % set maximal output current in A
    function setCurrent( obj, i )
      srl_write(obj.serialPort, sprintf("ISET1:%.3f", i));
      data = srl_read(obj.serialPort, 16);
    end

    % set voltage in V
    function setVoltage( obj, v )
      srl_write(obj.serialPort, sprintf("VSET1:%.2f", v));
      data = srl_read(obj.serialPort, 16);
    end

    % enable or disable output
    function setOnOff( obj, o )
     srl_write(obj.serialPort, sprintf("OUT%d", o));
      data = srl_read(obj.serialPort, 16);
    end

    % --------------------------------------------------------------------------
    %  High level Function

    % voltage sweep, according to vector us, fixed delay in s
    function [U,I] = voltageSweep( obj, us, delay )
      U=[];
      I=[];
      for u=us
        obj.setVoltage(u);
        pause(delay);
        U = [ U, obj.getVoltage() ];
        I = [ I, obj.getCurrent() ];
        pause(.01);
      end
    end

    % current sweep, according to vector is, fixed delay in s
    function [U,I] = currentSweep( obj, is, delay )
      U=[];
      I=[];
      for i=is
        obj.setCurrent(s, i);
        pause(delay);
        U = [ U, obj.getVoltage() ];
        I = [ I, obj.getCurrent() ];
        pause(.01);
      end
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




