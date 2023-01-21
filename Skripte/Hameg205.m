classdef Hameg205 < handle
  % Class for serial communiction with the Hameg 205-3 Scope and the
  % Arduino Nano Interface
  %
  % See my HamegNanoInterface project.
  %
  % The instrument control package is required for serial communication.
  % See https://gnu-octave.github.io/packages/instrument-control/
  %
  % Implemented:
  %  - read scope data
  %
  % Missing:
  %  - Everything else
  %
  % Copyright, 2023, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA

  properties
    % COM Port Handle
    serialPort=[];
    % Debug Level, default is 0 (erros)( 1- warning, 2- info, during developement up to 3)
    debugLevel=3;

    % Data read from scope
    % voltage, raw data, columns for channels, rows for data, see n
    u=[];
  end

  properties (Constant = true)
	  % Number of points per channel for Hameg 205-3
	  n=2048;
  end


  % Public methods
  methods (Access = public)

    % Create Instance and load instrument-control package
    function obj = Hameg205( )
      % Lade die package
      pkg load instrument-control
    end

    % Connect to scope. Open com port, correct windows com port, set interal port handle
    function ok = connect( obj, com )
      % Window COM Port correction
      % Open com port on windows with \\.\ correction.
      % Applies only if com starts with "COM", otherwise the port is passed
      if (startsWith(com,"COM"))
        com =  [ "\\\\.\\" com ] ;
      end
      obj.dprintf(2,"Hameg 205, connect with port %s\n",com);
      % siehe https://gnu-octave.github.io/packages/instrument-control/
      obj.serialPort = serialport( com, "BaudRate", 115200, "Timeout", 0.1 );
      % wait for connection
      pause(0.5);
	    % set to binary mode
	    write(obj.serialPort,"b\n");
	    % Read some junk, there is a bug in the instrument-control readline and
      % and the configureTerminator for "lf/cr" combinations
      while (!isempty(d = serialPortReadLine( obj.serialPort, "\r" )))
        disp(d);
        pause(0.1);
      end
     end

    % Disconnect from scope.
    function disconnect( obj )
      obj.serialPort = [];
    end

    % read curve data from scope, 1 or two channels
    function ok = getCurves( obj, channels )
	    % set to binary mode - repeat it ...
	    write(obj.serialPort,"b\n");
      % Ask for data in binary format
      write(obj.serialPort, sprintf("r%d\n",channels) );
	    % Number of data to read
	    ndata = obj.n*channels;
	    data = read( obj.serialPort, ndata, "uint8" );
      %printf("%d\n",data); % debug output
	    % check data
	    if (length(data)!=ndata)
	      obj.dprintf(0,"Error, expected %d bytes, but got %d\n",ndata,length(data));
		    obj.u=[];
		    ok = false;
		    return;
	    end
	    % Convert data, matrix with 1 or 2 columns according to channnels setting
	    obj.u = reshape( data*1.0, obj.n, channels );
	    ok = true;
    end

    % Zeichne die abgefragten Daten
    function plot( obj )
	  if (isempty(obj.u))
	    obj.dprintf(0,"Error, nothing to plot, read data first!\n");
      return
	  endif;
      % Empty legend
      L={};
      % Alle Kanäle zeichnen
      for l=1:size(obj.u,2)
        % restliche Kanäle hinzu
        plot( obj.u(:,l) );
        % Plot offen lassen
        hold on;
        % Legende merken
        L=[L, {sprintf("Ch. %d",l)}];
      end
      hold off;
      xlabel( "points" );
      ylabel("voltage");
      legend( L );
      title("Hameg 205 - 3");
    end

  % End of public methods
  end

  % ----------------------------------------------------------------------------
  % Protected methods
  methods (Access = protected)


    % Debug output, like printf, but debug level as first argument.
    function dprintf(obj, level, varargin )
      if (level <= obj.debugLevel)
        printf(varargin{:});
      end
    end

  % End of protected methods
  end

end




