classdef Metrex4650Cr < handle
  % Class for serial / usb communication with the
  % (Voltcraft) Metrex 4650Cr Multimeter
  %
  % Based on the Metrex documentation.
  %
  % Uses the local instrument-control extension serialPortReadLine
  %
  % Den Pfad zu diesem Skript mit in den Suchpfad aufnehmen, z.B.
  % addpath( "OctaveElektro/Skripte" );
  %
  % Installation der instrument-control package mit
  % pkg -forge install instrument-control
  % Anleitung: https://octave.sourceforge.io/instrument-control/index.html
  %
  % Implemented:
  %  - aquire measurement
  %  - get values
  %
  % In normal operation mode every measurement must be aquired by sending
  % 'D'. In COMM mode the multimeter sends automatically.
  %
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
    function obj = Metrex4650Cr( )
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
      obj.dprintf(2,"Metrex4650Cr, connect with port %s\n",com);
      % siehe https://gnu-octave.github.io/packages/instrument-control/
      obj.serialPort = serialport( com, "BaudRate", 1200, "Timeout", 0.5, ...
        "DataBits", 7, "StopBits", 2, "Parity", "none" );
      setDTR( obj.serialPort, true );
      setRTS( obj.serialPort, false );
      % Probleme mit der readline Funktion aus der instrument control package
      %configureTerminator ( obj.serialPort, "cr" ); % CR, Asci 13, C \r
      % Use replacement serialPortReadLine instead.
      % Read the first line, get clean start for the next commands.
      serialPortReadLine( obj.serialPort, "\r" );
     end

    % Disconnect from power supply. Close com port
    function disconnect( obj )
      %fclose( obj.serialPort ); % war früher so, schließt automatisch wenn die Variable verschwindet.
      obj.serialPort = [];
    end

    % Messung Anfordern, Gerät nicht im COMM Modus
    function [value, unit] = acquireValue( obj )
      set( obj.serialPort, "TimeOut", 0.5 ); % Wait for answer
      flush( obj.serialPort, "input" ); % Input Flushend
      write( obj.serialPort, "D" );     % D Senden, damit wird eine Messung angestoßen
      flush( obj.serialPort, "output" );% Output Flushend

      [value,unit] = obj.getValue(); % Messdaten abholen
    endfunction

    % Messdaten abholen.
    % Wird aus aquireValue aufgerufen
    % Direkt nutzbar wenn das Gerät im COMM Modus (regelmäßige Übertragung) ist.
    % Aber dann aufpassen, es liest eine Zeile ... Die erste die angekommen ist.
    % vgl. getLastValue() !!
    % Liefert den numerischen Wert (dezimale Vielfache eingerechnet) und die
    % Einheit. An die Einheit wird ggf. (DC) oder (AC) angehängt.
    function [value, unit] = getValue( obj );
      % Read one line, terminated with CR
      set( obj.serialPort, "TimeOut", 2.5 ); % Wait for one automatically send data
      %l = readline( obj.serialPort ); % Bereite sporadische Probleme.
      l = serialPortReadLine( obj.serialPort, "\r" );

      [value, unit] = obj.parseLine( l );
    endfunction

    % Get last value
    % Nützlich im COMM Modus wenn nicht ganz regelmäßig Daten abgeholt werden,
    % Dann können mehrer Messwerte im Buffer des serial port liegen.
    % Lese alle weg, werte nur die letzte aus.
    function [value, unit] = getLastValue( obj );
      set( obj.serialPort, "TimeOut", 2.5 ); % Wait for one automatically send data
      l = [];
      do
         lastLine = l;
         %l = readline( obj.serialPort ); % Wäre schön, bereitet aber Probleme.
         l = serialPortReadLine( obj.serialPort, "\r" );
         set( obj.serialPort, "TimeOut", 0.1 ); % Just empty buffer
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
      obj.dprintf(3,"pareLine(%s)\n",l);
      value=NA;
      unit="";
      if (isempty(l))
        obj.dprintf(0,"Error: Nothing to parse, line is empty\n");
        unit="No Data";
        return;
      endif;
      if (length(l)<10)
        obj.dprintf(0,"Error: Expect 10 chars, but got only %d (%s)\n", ...
          length(l),l);
        unit=["Invalid Data: " l];
        return;
      endif

      mode = substr(l,1,2)
      wert = substr(l,4,6)
      unit = substr(l,10)
      % Ziehe den Dezimal Faktor aus der Einheit heraus
      factor=1;
      switch (unit(1))
        case "p"
          factor=1e-12; unit=substr(unit,2);
        case "n"
          factor=1e-9; unit=substr(unit,2);
        case "u"
          factor=1e-6; unit=substr(unit,2);
        case "m"
          factor=1e-3; unit=substr(unit,2);
        case "n"
          factor=1e-9; unit=substr(unit,2);
        case "k"
          factor=1e3; unit=substr(unit,2);
        case "M"
          factor=1e6; unit=substr(unit,2);
      endswitch
      % Numerischen Wert zur entsprechenden Einheit
      value = str2double(wert)*factor;
      % Modus mit an die Einheit anhängen
      if (mode(1)!=' ')
        unit = [ unit " (" mode ")" ];
      endif
    end

    % Debug output, like printf, but debug level as first argument.
    function dprintf(obj, level, varargin )
      if (level <= obj.debugLevel)
        printf(varargin{:});
      end
    end

  % End of protected methods
  end

end




