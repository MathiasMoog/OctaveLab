classdef Sls60 < handle
  % Class for serial / usb communication with the Stamos S-LS-60
  % Electronic Load
  %
  % Based on Stamos Documentation "Communication Commands with Computer V2.10.pdf"
  %
  % Den Pfad zu diesem Skript mit in den Suchpfad aufnehmen, z.B.
  % addpath( "OctaveElektro/Skripte" );
  %
  % Installation der instrument-control package mit
  % pkg -forge install instrument-control
  % Anleitung: https://octave.sourceforge.io/instrument-control/index.html
  %
  % Implemented:
  %  - Measure voltage, current and power
  %  - Function (VOLT|CURR|RES|POW|SHORT) access
  %  - CC Mode (basic functionality)
  %  - CV,CR,CP Mode (not jet testet)
  %
  % Missing:
  %  - Everything else
  %
  % Copyright, 2022, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA

  properties
    % Serial Port Handle
    serialPort=[];
    % UDP connection flag
    udp = [];
    ip  = [];
    udpPort=[];
    % Debug Level, default is 0 (erros)( 1- warning, 2- info, during developement up to 3)
    debugLevel=1;
  end

  % Public methods
  methods (Access = public)

    % Create Instance and load instrument-control package
    function obj = Sls60( )
      % Lade die package
      pkg load instrument-control
    end

    % Connect to load. Open com port, correct windows com port, set interal port handle
    function ok = connect( obj, com, udpPort=18190 )
      % Window COM Port correction
      % Open com port on windows with \\.\ correction.
      % Applies only if com starts with "COM", otherwise the port is passed
      if (startsWith(com,"COM"))
        com =  [ "\\\\.\\" com ] ;
      end
      if (startsWith(com,"192.")) % UDP connection
        obj.serialPort = udpport("LocalPort",udpPort)
        set( obj.serialPort, "Timeout", 3 ); % hilft nix ...
        obj.udp = true;
        obj.ip=com;
        obj.udpPort=udpPort;
      else  % serial connection
        obj.serialPort = serialport( com, "BaudRate", 115200, "Timeout", 0.2, ...
          "DataBits", 8, "StopBits", 1, "Parity", "none" );
      end
      version = obj.getVersion()
      ok = version ~= -1;
    end

    % Disconnect from load. Close com port
    function disconnect( obj )
      %fclose( obj.serialPort );
      obj.serialPort = [];
    end

    % Get version and serial number
    function version = getVersion( obj )
      obj.send("*IDN?");
      version=obj.readLine();
    end

    % Measure Voltage
    function u = measureVoltage( obj )
      obj.send(":MEASure:VOLTage?");
      u = obj.parseNumber("V");
    end

    % Measure Current
    function i = measureCurrent( obj )
      obj.send(":MEASure:CURRent?");
      i = obj.parseNumber("A");
    end

    % Measure Voltage
    function p = measurePower( obj )
      obj.send(":MEASure:POWer?");
      p = obj.parseNumber("W");
    end

    % Set operating function
    % Allowed: VOLT|CURR|RES|POW|SHORT
    function setFunction( obj, f )
      obj.send( [":FUNCtion ",f] );
    end

    % Get operating function
    function f = getFunction( obj)
      obj.send( ":FUNCtion?" );
      f = obj.readLine();
    end

    % Set CC Current in A
    function setCcCurrent( obj, i)
      obj.send( sprintf(":CURRent %.4fA",i) );
    end

    % get CC Current in A
    function i = getCcCurrent( obj )
      obj.send(":CURRent?");
      i = obj.parseNumber("A");
    end

    % Set CV Voltage in V
    function setCvVoltage( obj, u)
      obj.send( sprintf(":VOLTage %.4fV",u) );
    end

    % get CC Current in V
    function u = getCvVoltage( obj )
      obj.send(":VOLTage?");
      u = obj.parseNumber("V");
    end

    % Set CR Resistance in OHM
    function setCrResistance( obj, r)
      obj.send( sprintf(":RESistance %.3fOHM",r) );
    end

    % get CR Resistance in OHM
    function r = getCrResistance( obj )
      obj.send(":RESistance?");
      r = obj.parseNumber("OHM");
    end

    % Set CP Power in W
    function setCpPower( obj, p)
      obj.send( sprintf(":RESistance %.4fW",p) );
    end

    % get CP Power in W
    function p = getCpPower( obj )
      obj.send(":RESistance?");
      p = obj.parseNumber("W");
    end


    % get "INPUT", this is the ON / OFF switch, on=true
    function s = getInput( obj )
      obj.send(":INPut?");
      i = obj.readLine();
      switch (i)
        case "ON"
          s=true;
        case "OFF"
          s=false;
        otherwise
          obj.dprintf("Unknown input state %s\n",i);
          s=false;
      end
    end

    % set "INPUT", switch on (true) or off (false)
    function setInput( obj, on )
      if (on)
        obj.send(":INPut ON");
      else
        obj.send(":INPut OFF");
      end
    end


  % End of public methods
  end

  % Protected methods - at the moment public, change later on to protected
  methods (Access = public)

    % Read a single line terminates by \r\n
    function line = readLine( obj )
      if (obj.udp)
        % Timeout is not working
        for i=1:30
          if (get(obj.serialPort,"NumBytesAvailable")>0)
            break;
          end
          pause(0.1);
        end
        obj.dprintf(3,"Wait for %f s for Answer\n",i*0.1);
        % Read everything - hopefully one line, read( .., 1) is not working!
        line = char( read( obj.serialPort) );
      else
        ints = uint8(1); % create int array
        i=1;
        while( 1 )
          v = read( obj.serialPort, 1); % read one character
          if (isempty(v)) % Nothing to read
            line = -1;
            return;
          end
          % Terminate with <CR><LF>, octave: \r\n  binary 13 10
          if (v==10) % \n=10
            break;
          end
          if (v==13) % \r=13
            continue;
          end
          if (i>1 || ~isspace(v)) % Ommit white spaces at the beginning
            ints(i++)=v;
          end
        end
        line = char(ints);
      end;
    end

    % Parse Answer (Number with unit)
    function v = parseNumber( obj, unit )
      v=NA;
      line=obj.readLine();
      if ( line == -1)
        obj.dprintf(0,"Error: No Anwer from Electronic load. Check connection.\n");
      else
        f = sprintf("\%f%s",unit);
        [v,c] = sscanf(line,"%fV");
        if (c~=1)
          obj.dprintf(0,"Error: No numerical Value in Answer %s\n",line);
          v=NA;
        end
      end
    end


    % See Communication Protocoll p 1
    function send(obj, command)
      if (obj.udp)
       write(obj.serialPort,[command,"\n"],obj.ip,obj.udpPort);
      else
       write(obj.serialPort,command);
       write(obj.serialPort,"\n");
      end
      obj.dprintf(3,"sls send: %s\n",command);
    end

    function dprintf(obj, level, varargin )
      if (level <= obj.debugLevel)
        printf(varargin{:});
      end
    end

  % End of protected methods
  end

end




