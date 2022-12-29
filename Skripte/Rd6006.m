classdef Rd6006 < handle
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
    % Modbus Handle
    modbus=[];
    % Slave Id
    slaveId=1;
    % Debug Level, default is 0 (erros)( 1- warning, 2- info, during developement up to 3)
    debugLevel=3;
  end

  % Public methods
  methods (Access = public)

    % Create Instance and load instrument-control package
    function obj = Rd6006( )
      % Lade die package
      pkg load instrument-control
    end

    % Connect to power supply. Open com port, correct windows com port, set interal port handle
    function ok = connect( obj, com, slaveId=1 )
      % Window COM Port correction
      % Open com port on windows with \\.\ correction.
      % Applies only if com starts with "COM", otherwise the port is passed
      if (startsWith(com,"COM"))
        com =  [ "\\\\.\\" com ] ;
      end
      % Connect, increase timeout, siehe http://wiki.octave.org/Instrument_control_package
      obj.modbus = modbus('serialrtu', com, 'BaudRate', 115200, 'Timeout', 0.3);

      % remember slaveId
      obj.slaveId=slaveId;
    end

    % Connect to power supply. Open ip, set interal port handle
    function ok = connectTcp( obj, ip, slaveId=1 )
      % Connect, increase timeout, siehe http://wiki.octave.org/Instrument_control_package
      obj.modbus = modbus('tcpip', ip, 'Timeout', 0.3);

      % remember slaveId
      obj.slaveId=slaveId;
    end

    % Disconnect from power supply. Close com port
    function disconnect( obj )
      obj.setOnOff( 0 );
      obj.modbus = [];
    end

    % -------------------------------------------------------------------------
    % Clock settings

    % return set date as datenum
    function d = getDate( obj )
      data = read( obj.modbus, 'holdingregs',48,6, obj.slaveId );
      d = datenum( double(data) );
    end

    % set date, use datenum or string, see datevec function
    function setDate( obj, date )
      v = uint16(datevec( date ));
      write( obj.modbus, 'holdingregs',48,v, obj.slaveId );
    end

    % -------------------------------------------------------------------------
    % Basic Access functions

    % Get version and serial number
    function idn = getVersion( obj )
      data = read( obj.modbus, 'holdingregs',0,4, obj.slaveId );
      obj.dprintf(2,"Version RD%d, Serial number %d, Firmware version %.2f\n",
        data(1), bitor(bitshift(data(2),16),data(3)), double(data(4))*0.01 );
      idn = data(1);
    end

    % Read inner Temperature
    function T = getTemp( obj )
      data = read( obj.modbus, 'holdingregs',4,2, obj.slaveId );
      T = double(data(2));
      if (data(1)==1)
        T = -T;
      end
    end

    % get voltage limit
    function v = getMaxVoltage( obj )
      data = read( obj.modbus, 'holdingregs',8,1, obj.slaveId );
      v = double(data(1))*0.01;
    end

    % set voltage limit in V
    function setMaxVoltage( obj, v )
      write( obj.modbus, 'holdingregs',8,uint16(round(v*100)), obj.slaveId );
    end

    % get current limit
    function i = getMaxCurrent( obj )
      data = read( obj.modbus, 'holdingregs',9,1, obj.slaveId );
      i= double(data(1))*0.001;
    end

    % set current limit
    function setMaxCurrent( obj, i )
      write( obj.modbus, 'holdingregs',9,uint16(round(i*1000)), obj.slaveId );
    end

    % get output current in A
    function i = getCurrent( obj )
      data = read( obj.modbus, 'holdingregs',11,1, obj.slaveId );
      i= double(data(1))*0.001;
    end

    % get output voltage in A
    function v = getVoltage( obj )
      data = read( obj.modbus, 'holdingregs',10,1, obj.slaveId );
      v = double(data(1))*0.01;
    end

    % get input voltage in V
    function v = getInputVoltage( obj )
      data = read( obj.modbus, 'holdingregs',14,1, obj.slaveId );
      v = double(data(1))*0.01;
    end

    % get output power in W
    function p = getPower( obj )
      data = read( obj.modbus, 'holdingregs',12,2, obj.slaveId );
      p = double(bitor(bitshift(data(1),16),data(2)))*0.01
    end

    % check lock
    function l = getLock( obj )
      l = read( obj.modbus, 'holdingregs',15,1, obj.slaveId );
    end

    % set lock, 0 open, 1 locked
    function setLock( obj, lock )
      write( obj.modbus, 'holdingregs',15,uint16(lock), obj.slaveId );
    end

    % get protection 0 OK, 1 OVP, 2 OCP
    function o = getProtection( obj )
      o = read( obj.modbus, 'holdingregs',16,1, obj.slaveId );
    end

    % get output on 1, off 0
    function o = getOnOff( obj )
      o = read( obj.modbus, 'holdingregs',18,1, obj.slaveId );
    end

    % enable or disable output
    function setOnOff( obj, o )
     write( obj.modbus, 'holdingregs',18,uint16(o), obj.slaveId );
    end

    % --------------------------------------------------------------------------
    % Battery functions

    % get Battery Mode, 0 off, 1 on
    function o = getBatteryMode( obj )
      o = read( obj.modbus, 'holdingregs',32,1, obj.slaveId );
    end

    % get battery voltage in V
    function v = getBatteryVoltage( obj )
      data = read( obj.modbus, 'holdingregs',33,1, obj.slaveId ),
      v = double(data(1))*0.01;
    end

    % Read external Temperature
    function T = getExtTemp( obj )
      data = read( obj.modbus, 'holdingregs',34,2, obj.slaveId );
      T = double(data(2));
      if (data(1)==1)
        T = -T;
      end
    end

    % get charged battery energy in Ah
    function p = getAh( obj )
      data = read( obj.modbus, 'holdingregs',38,2, obj.slaveId );
      p = double(bitor(bitshift(data(1),16),data(2)))*0.01;
    end

    % get charged battery energy in Wh
    function p = getWh( obj )
      data = read( obj.modbus, 'holdingregs',40,2, obj.slaveId );
      p = double(bitor(bitshift(data(1),16),data(2)))*0.01;
    end

    % -------------------------------------------------------------------------
    % Memory (Data) Functions

    function n = getData( obj )
      n = read( obj.modbus, 'holdingregs',0x13,1, obj.slaveId );
    end

    function setData( obj, n )
      write( obj.modbus, 'holdingregs', 0x13, n, obj.slaveId );
    end

    % get voltage in memory n
    function v = getDataVoltage( obj, n )
      data = read( obj.modbus, 'holdingregs',0x50+4*n,1, obj.slaveId );
      v = double(data(1))*0.01;
    end

    % set voltage limit in memory n, voltage in V
    function setDataVoltage( obj, n, v )
      write( obj.modbus, 'holdingregs',0x50+4*n,uint16(round(v*100)), obj.slaveId );
    end

    % get current in memory n
    function i = getDataCurrent( obj, n )
      data = read( obj.modbus, 'holdingregs',0x51+4*n,1, obj.slaveId );
      i = double(data(1))*0.001;
    end

    % set current limit in memory n, voltage in V
    function setDataCurrent( obj, n, i )
      write( obj.modbus, 'holdingregs',0x51+4*n,uint16(round(i*1000)), obj.slaveId );
    end

    % get voltage protection in memory n
    function v = getDataOVP( obj, n )
      data = read( obj.modbus, 'holdingregs',0x52+4*n,1, obj.slaveId );
      v = double(data(1))*0.01;
    end

    % set voltage protection in memory n, voltage in V
    function setDataOVP( obj, n, v )
      write( obj.modbus, 'holdingregs',0x52+4*n,uint16(round(v*100)), obj.slaveId );
    end



    % get current protection in memory n, current in A
    function i = getDataOCP( obj, n )
      data = read( obj.modbus, 'holdingregs',0x53+4*n,1, obj.slaveId );
      i = double(data(1))*0.001;
    end

    % set current protection in memory n, current in A
    function setDataOCP( obj, n, i )
      write( obj.modbus, 'holdingregs',0x53+4*n,uint16(round(i*1000)), obj.slaveId );
    end


    % --------------------------------------------------------------------------
    %  High level Function

    % voltage sweep, according to vector us, fixed delay in s
    function [U,I] = voltageSweep( obj, us, delay )
      U=[];
      I=[];
      for u=us
        obj.setMaxVoltage(u);
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
        obj.setMaxCurrent(i);
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




