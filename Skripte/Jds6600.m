classdef Jds6600 < handle
  % Klasse zur Kommunikation mit dem Joy-it JDS6600 Signal Generator
  %
  % Den Pfad zu diesem Skript mit in den Suchpfad aufnehmen, z.B.
  % addpath( "OctaveElektro/Skripte" );
  %
  % Installation der instrument-control package mit
  % pkg -forge install instrument-control
  % Anleitung: https://octave.sourceforge.io/instrument-control/index.html
  %
  % Implemented:
  %  - Basic settings for signal generator
  %  - Measure frequencies at Ext. IN (neither comfortable nor accurate)
  %  - Arbritary wave forms
  %
  % Missing:
  %  - Sweep Functionality
  %  - Counting
  %
  % Copyright, 2022, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA

  properties
    % Serial Port Handle
    serialPort=[];
    % -----------------------------------------------------------------------
    % Remember all read properties for channel 1 and channel t
    %
    % Version number, r00, function code r00
    version=[];
    % Serial number, r01, function code r00
    serialNumber=[];
    % Wave form, function code 21 and 22
    waveForm=[NA,NA];
    % Frequency in Hz for both channels, function codes 23 and 24
    frequency=[NA,NA];
    % Amplitude in V for both channels, function codes 25 and 26
    amplitude=[NA,NA];
    % Offset in V for both channels, function codes 27 and 28
    offset=[NA,NA];
    % duty for both channels, function codes 29 and 30
    duty=[NA,NA];
    % phase for second channel (compared to first channel), function code 31
    phase=NA;

    % -----------------------------------------------------------------------
    % Arbitary waves
    %

    arbitraryWaves = [];

    % -----------------------------------------------------------------------
    % Remember all read properties for Ext.IN
    %
    % Extension function, see extFunctionText, function code 33
    extFunction = NA;
    % Coupling for Ext. IN (AC=0, DC=1), see extCouplingText, function code 36
    extCoupling = NA;
    % Gate Time for Ext. IN, function code 37
    % Default 1 (results in Hz), below 0.4 results in kHz
    extGateTime = NA;
    % Measuring Mode for Ext. IN (Frequency=0, Period=1), see extModeText,
    % function code 38
    extMode = NA;
    % Measured frequency, function code 81
    extFrequency = NA;
    % Measured duration positive halv wave, function code 83
    extPWplus = NA;
    % Measured duration positive halv wave, function code 83
    extPWminus = NA;
    % Measured period time, function code 85
    extT = NA;
    % Measured duty, function code 86
    extDuty = NA;

    % Debug Level, default is 0 (erros)( 1- warning, 2- info, during developement up to 3)
    debugLevel=3;

  endproperties

  properties (Constant = true)

    % Wave Forms, see JDS6600 Protocoll p. 2
    % Take care, index starts with 1 in octave, but with 0 in JDS
    % Arbitrary waves string from index 101 in JDS
    waveFormText = { "Sine wave"; "Square wave"; "Pulse wave"; "Triangular wave"; ...
      "Partial sine"; "CMOS wave"; "DC level"; "Half wave"; "Full wave"; ...
      "Positive step wave"; "Negative step wave"; "Noise wave"; "Exponential-"; ...
      "Exponential-Decay"; "Multi-Tone"; "Sinc"; "Lorenz pulse"};

    % Frequency conversion, see JDS 6600 Protocoll p. 3
    % Take care, index starts with 1 in octave, but with 0 in JDS
    % Misstake in data sheet for kHz and MHz
    frequencyFactors = [1e-2,1e1,1e4,1e-5,1e-8];

    % maximal number of arbitrary waves, JDS6600 p 6 (rows in matrix)
    nArbitraryWaves = 60;
    % length of one wave (columns in matrix)
    lArbitraryWave = 2048;

    % Ext. IN, coupling strings
    extCouplingText = { "AC", "DC" };
    % Ext. IN, Mode strings
    extModeText = { "Frequency", "Period" };
    % Function, command 33, take care octave starts with 1, jds with 0
    extFunctionText = { "Channel 1", "Channel 2", "Settings", "(3) ???", "Measure", ...
      "Count" };
  end


  % Public methods
  methods (Access = public)

    % Create Instace, initialize internal fields.
    function obj = Jds6600( )
      % Allocate Memory
      obj.arbitraryWaves = zeros(obj.nArbitraryWaves,obj.lArbitraryWave);
      % Lade die package
      pkg load instrument-control
    end

    % Open com port, windows com port corrections, set interal port handle
    function connect( obj, com )
      % Window COM Port correction
      % Open com port on windows with \\.\ correction.
      % Applies only if com starts with "COM", otherwise the port is passed
      if (startsWith(com,"COM"))
        com =  [ "\\\\.\\" com ] ;
      end
      obj.dprintf(2, "Connect to Joy-It JDS6600 Signal Generator via %s\n",com);
      % 1 als timeout ca. 100 ms, siehe http://wiki.octave.org/Instrument_control_package
      obj.serialPort = serial(  com , 115200, 2 );
      set(obj.serialPort, "bytesize", 8);
      set(obj.serialPort, "stopbits", 1);
      obj.getVersion();
      % todo, check version ..
      % Basic settings, like original Software from Joy It
      obj.send('w',33,0); % Measurement off ?
      obj.send('w',32,[0,0,0,0]); % ???
      obj.getBasicSettings();
    end

    % Close com port
    function disconnect( obj )
      fclose( obj.serialPort );
      obj.serialPort = [];
    end

    % Get version and serial number
    function [version,serialNumber] = getVersion( obj )
      obj.send('r',00,1);
      version=obj.version;
      serialNumber=obj.serialNumber
    end

    % get Basic settings
    function getBasicSettings( obj );
      obj.send('r',21,10); % Read basic settings
    end

    % Get frequency of given channel (0 for Ext. IN, output channels 1 or 2)
    % Activeate external measurement first, see setExt* methods
    % return frequency in Hz
    function f = getFrequency( obj, channel )
      if (channel==0)
        obj.extFrequency=NA;
        obj.send('r',81,5); % only 81 to 86 known ...
        f=obj.extFrequency;
      else
        obj.send('r',22+channel,1); % channel 1 function code 23, ch. 2 -> 24
        f = obj.frequency(channel);
      end
    end

    % Set frequency in Hz for given channel (1 or 2)
    function setFrequency( obj, channel, f )
      obj.dprintf(2,"jds setFrequency channel %d to %f Hz\n",channel,f);
      % Manually convert to a usefull range
      if (f>1e8)
        fn=3;
      elseif (f>1e5)
        fn=2;
      elseif (f>1e2) % Problem with send, see comments for printing the arguments
        fn=1;
      elseif (f>1e-1)
        fn=4;
      else
        fn=5;
      end
      fi=f/obj.frequencyFactors(fn);
      obj.send('w',22+channel,[fi,fn-1]); % channel 1 function code 23, ch. 2 -> 24
    end

    % Set wave form, see waveForms cell array
    function setWaveForm( obj, channel, number )
      obj.send('w',20+channel,number);
    end

    % Set amplitude
    function setAmplitude( obj, channel, amplitude )
      obj.send('w',24+channel,amplitude*1000);
    end

    % Set offset (bias)
    function setOffset( obj, channel, bias )
      obj.send('w',26+channel,1000+bias*100);
    end

    % Set duty
    function setDuty( obj, channel, duty )
      obj.send('w',28+channel,duty*1000);
    end

    % Set phase
    function setPhase( obj, phase )
      obj.send('w',31,phase*10);
    end

    % --------------------------------------------------------------------------
    % arbritare waves

    % Set arbritare wave
    function setArbitraryWave( obj, number, data )
      assert( length(data)==obj.lArbitraryWave );
      obj.send('a',number,4095*(min(1,max(-1,data))+1.0)/2);
    end

    % Evaluate function f from t0 to t1
    function setArbitraryWaveFunction( obj, number, f, t0, t1 )
      t = linspace(t0,t1,obj.lArbitraryWave );
      data = f(t);
      obj.setArbitraryWave( number, data );
    end

    % Get arbritare wave
    function data = getArbitraryWave( obj, number )
      obj.send('b',number,0);
      data = obj.arbitraryWaves(number,:);
    end

    % Plot arbritare wave
    function plotArbitraryWave( obj, number )
      data = obj.arbitraryWaves(number,:);
      plot(data);
      title(sprintf("Arbitrary wave number %d",number));
    end

    % --------------------------------------------------------------------------
    % Measurements on Ext. IN

    % Get measurement settings for Ext. IN (Coupling, Mode, GateTime)
    function getExtMeasureSettings( obj)
      obj.send('r',36,2);
    end

    % Set measurement on / off for Ext. IN, dc=0 -> AC, dc=1 -> DC
    function setExtMeasure( obj, on=1)
      if (on)
        obj.send('w',33,4);  % Activate Measurement
        obj.getExtMeasureSettings(); % Read settings
      else
        obj.send('w',33,0);
      endif
    end


    % Set coupling for Ext. IN, dc=0 -> AC, dc=1 -> DC
    function setExtMeasureCoupling( obj, dc=0)
      obj.send('w',36,dc);
    end

    % Set gate time in s for Ext. IN, gateTime in s, take care cast to int in cs
    function setExtMeasureGateTime( obj, gateTime)
      obj.send('w',37,round(gateTime*100));
    end

    % Set mode for Ext. IN, mode=0 -> Frequency, mode=1 -> Period
    function setExtMeasureMode( obj, mode=0)
      obj.send('w',38,mode);
    end

  % End of public methods
  endmethods

  % Protected methods - at the moment public, change later on to protected
  methods (Access = public)

    % Read a single line terminates by \r\n
    function line = readLine( obj )
      ints = uint8(1); % create int array
      i=1;
      while( 1 )
        v = srl_read( obj.serialPort, 1); % read one character
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
        if (i>1 || !isspace(v)) % Ommit white spaces at the beginning
          ints(i++)=v;
        end
      end
      line = char(ints);
    end

    function ok = readResponse(obj )
      ok = true;
      while ( (line=obj.readLine())!=-1 )
        obj.dprintf(3,"received: %s\n", line);
        ok &= obj.parseLine(line);
      end
    end

    % Wait for an OK after a write command
    function ok = checkOK( obj )
     ok = false;
     while ( (line=obj.readLine())!=-1 && ~ok )
        obj.dprintf(3,"received: %s\n", line);
        if (line(1)!=':')
          obj.dprintf(0,"Error: Response doesn't start with a colon : in <%s>\n",line);
        elseif strcmp(line,":ok")
          obj.dprintf(2,"Set command accepted\n");
          ok = true;
        else
          obj.dprintf(0,"Warning: Didn't expect this response: %s\n",line);
          obj.parseLine(line);
        end
      end
    end

    function ok = parseLine(obj,line)
      ok = true;
      hasFunctionCode=false;
        if (line(1)!=':')
        obj.dprintf(0,"Error: Response doesn't start with a colon : in <%s>",line);
        ok = false;
      else
        instructionCharacter = line(2);
        functionCode = str2num( substr(line,3,2) );
        [dataFields,count]=sscanf(substr(line,6),"%d,");
        % check character and start debug output
        switch(instructionCharacter)
          case 'w'
            obj.dprintf(2,"Set (%02d) ",functionCode);
            hasFunctionCode=true;
          case 'r'
            obj.dprintf(2,"Get (%02d) ",functionCode);
            hasFunctionCode=true;
          case 'b'
            obj.dprintf(2,"Get arbitrary wave %02d with %d points\n",functionCode,count);
            assert(count==size(obj.arbitraryWaves,2));
            obj.arbitraryWaves(functionCode,:)=2.*dataFields/4095.0-1;
          case 'a'
            obj.dprintf(2,"Set arbitrary wave %02d with %d points\n",functionCode,count);
            obj.arbitraryWaves(functionCode,:)=2.*dataFields/4095.0-1;
          otherwise
            obj.dprintf(0,"Error: unknown instruction character %c\n??? (%02d) ", ...
              instructionCharacter,functionCode);
            ok = false;
        end
      end
      if (hasFunctionCode)
        % interprete results according to the function code
        switch (functionCode)
          case 00
            obj.dprintf(2,"Version %d\n",dataFields(1));
            obj.version=dataFields(1);
          case 01
            obj.dprintf(2,"Serial Number %d\n",dataFields(1));
            obj.serialNumber=dataFields(1);
          % -------------------------------------------------------------------
          % Signal generator, basic settings for channel 1 and 2
          case 21
            obj.waveForm(1)=dataFields(1);
            obj.dprintf(2,"Set wave form for channel 1 to %d = %s\n", ...
              obj.waveForm(1),obj.waveFormToText(obj.waveForm(1)) );
          case 22
            obj.waveForm(2)=dataFields(1);
            obj.dprintf(2,"Set wave form for channel 2 to %d = %s\n", ...
              obj.waveForm(2),obj.waveFormToText(obj.waveForm(1))  );
          case 23
            obj.frequency(1)=dataFields(1)*obj.frequencyFactors(dataFields(2)+1);
            obj.dprintf(2,"Frequency channel 1: %d,%d -> %f\n", ...
              dataFields(1),dataFields(2),obj.frequency(1));
          case 24
            obj.frequency(2)=dataFields(1)*obj.frequencyFactors(dataFields(2)+1);
            obj.dprintf(2,"Frequency channel 2: %d,%d -> %f\n", ...
              dataFields(1),dataFields(2),obj.frequency(2));
          case 25
            obj.amplitude(1)=dataFields(1)*1e-3;
            obj.dprintf(2,"Amplitude channel 1: %d -> %.3f V\n", ...
              dataFields(1),obj.amplitude(1));
          case 26
            obj.amplitude(2)=dataFields(1)*1e-3;
            obj.dprintf(2,"Amplitude channel 2: %d -> %.3f V\n", ...
              dataFields(1),obj.amplitude(2));
          case 27
            obj.offset(1)=dataFields(1)*1e-2-1;
            obj.dprintf(2,"Offset channel 1: %d -> %.3f V\n", ...
              dataFields(1),obj.offset(1));
          case 28
            obj.offset(2)=dataFields(1)*1e-2-1;
            obj.dprintf(2,"Offset channel 1: %d -> %.3f V\n", ...
              dataFields(1),obj.offset(2));
          case 29
            obj.duty(1)=dataFields(1)*1e-3;
            obj.dprintf(2,"Duty channel 1: %d -> %.3f\n", ...
              dataFields(1),obj.duty(1));
          case 30
            obj.duty(2)=dataFields(1)*1e-3;
            obj.dprintf(2,"Duty channel 2: %d -> %.3f\n", ...
              dataFields(1),obj.duty(2));
          case 31
            obj.phase=dataFields(1)*1e-1;
            obj.dprintf(2,"Phase: %d -> %.1f °\n", ...
              dataFields(1),obj.phase);
          case 32
            % todo ???
          % --------------------------------------------------------------------
          % External
          case 33
            obj.extFunction = dataFields(1);
            obj.dprintf(2,"Extension function %d -> %s\n", ...
              dataFields(1),obj.extFunctionText{dataFields(1)+1} );
          case 36
            obj.extCoupling=dataFields(1);
            obj.dprintf(2,"Ext. IN Coupling: %d %s\n",obj.extCoupling,...
              obj.extCouplingText{obj.extCoupling+1});
          case 37
            obj.extGateTime=dataFields(1)*1e-2;
            obj.dprintf(2,"Ext. IN gate time: %.2f s\n",obj.extGateTime);
          case 38
            obj.extMode=dataFields(1);
            obj.dprintf(2,"Ext. IN Mode: %d %s\n",obj.extMode,...
              obj.extModeText{obj.extMode+1});
          case 81
            obj.extFrequency=dataFields(1)*0.1;
            obj.dprintf(2,"Ext. In Frequency %f Hz\n",obj.extFrequency);
          case 82
            obj.dprintf(2,"Ext. 82 ?? %d\n",dataFields(1));
          case 83
            obj.extPWplus=dataFields(1)*1e-5;
            obj.dprintf(2,"Ext. In PW+ %f mus\n",obj.extPWplus);
          case 84
            obj.extPWminus=dataFields(1)*1e-5;
            obj.dprintf(2,"Ext. In PW- %f mus\n",obj.extPWminus);
          case 85
            obj.extT=dataFields(1)*1e-5;
            obj.dprintf(2,"Ext. In T %f mus\n",obj.extT);
          case 86
            obj.extDuty=dataFields(1)*1e-3;
            obj.dprintf(2,"Ext. In Duty %.3f \n",obj.extDuty);
          otherwise
            obj.dprintf(0,"Error: Unknown Function Code %d in %s\n",...
              functionCode,line);
            ok = false;
        end
      end
    end

    % See Communication Protocoll p 1
    function ok = send(obj, instructionCharacter, functionCode, dataFields)
      % Assemble instruction and send..
      s = sprintf(":%c%02d=",instructionCharacter, functionCode);
      n = length( dataFields );
      assert(n>0);
      for i=1:(n-1)
        % strange, 1.23e7 in s, but not if I run the command on the commandline !?
        % tried %d, %ld and %u In the end I used %.0f ....
        s = [s,sprintf("%.0f,",dataFields(i))];
      end
      s = [s,sprintf("%.0f.",dataFields(n)),"\r\n"];
      srl_write(obj.serialPort,s);
      obj.dprintf("jds send: %s",s);
      % Try to understand the command and adopt object properties
      if (instructionCharacter=='w' || instructionCharacter=='a')
        obj.parseLine(s);
        ok = obj.checkOK();
      end
      % Try to understand the response
      ok = obj.readResponse();
    end

    function dprintf(obj, level, varargin )
      if (level <= obj.debugLevel)
        printf(varargin{:});
      end
    end

    % Wave Form to Text conversion
    % Check known wave Forms, above 100 arbritary wave forms
    function t = waveFormToText( obj, n )
      if (n<length(obj.waveFormText))
         t = obj.waveFormText{n+1};
      elseif (n>100)
         t = sprintf("Arbritary Wave Form %d",n-100);
      else
         t = "Unknown";
      end
    end

  % End of protected methods
  endmethods

endclassdef




