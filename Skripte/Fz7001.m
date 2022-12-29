classdef Fz7001 < handle
  % Klasse für die serielle Kommunikation mit dem ELV FZ7001 Frequenzzähler
  %
  % Basiert auf der ELV V24 Dokumentation aus ELV Journal 8/89 S 9 ff. und dem
  % mit dem FZ7001 gelieferten Pascal Source Code.
  %
  % Den Pfad zu diesem Skript mit in den Suchpfad aufnehmen, z.B.
  % addpath( "OctaveElektro/Skripte" );
  %
  % Installation der instrument-control package mit
  % pkg -forge install instrument-control
  % Anleitung: https://octave.sourceforge.io/instrument-control/index.html
  %
  % Implemented:
  %  - Verbindung Aufbauen, Status abfragen, Auflösung setzen, messen.
  %
  % Fehlt:
  %  - Alles andere
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
    % Konstanten für die Kommunikation mit dem Gerät
    SOH           =  01; % Start of Header
    ETX           =  03; % End of Text
    CR            = 0x0D; % Carriage Return    C \r
    ACK           =  06; % Acknowledge
    NAK           = 0x15; % Negative Acknowledge
    EOT           =  04; % End of Transmit
    % Geräte Definition
    FZ7001        = 2;
    ADR			  = 0;		% Steht so als Vorgabe im Code ...
    % Übersetzungen ...
    statusTexte = { 'M', "Messung aktiv"; 'S', "Standby"};
    messartTexte = { ...
      'F', "Frequenzmessung";
      'T', "Periodendauer";
      'E', "Ereigniszählung";
      'P', "Positiver Impuls";
      'N', "Negativer Impuls";
      'V', "Verhältismessung";
      'A', "Additionsmessung" };
  endproperties

  % Public methods
  methods (Access = public)

    % Create Instance and load instrument-control package
    function obj = Fz7001( )
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
      obj.dprintf(2,"FZ 7001, connect with port %s\n",com);
      % siehe https://gnu-octave.github.io/packages/instrument-control/
      obj.serialPort = serialport( "\\\\.\\COM29", "BaudRate", 1200, "Timeout", 3, ...
          "DataBits", 8, "StopBits", 2, "Parity", "none" );
      % Die V24 Schnittstelle verwendet Hardware Handshake mit DTR und RTS
      setDTR( obj.serialPort, true );
      setRTS( obj.serialPort, true );
      % An dem Gerät anmelden
      obj.sendeBefehl( [ char(obj.SOH), char('0'+obj.FZ7001), ...
        char('0'+obj.ADR) ] );
      obj.checkAntwort( obj.ETX );
    end

    % Disconnect from FZ 7001. Close com port
    function disconnect( obj )
      % Sende Abmelde Zeichen
      obj.sendeBefehl( [char(obj.EOT), char(obj.CR)] );
      obj.checkAntwort( obj.ACK );
      % Lösche Verweis auf Port, damit schließt er sich.
      obj.serialPort = [];
    end

    % -------------------------------------------------------------------------
    % Abfragen, Einstellen und Messen
    % Noch nicht alles implementiert, nur das was ich brauchte.

    % Eine Messugn durchführen
    function [value,unit] = measure( obj )
      zeile = obj.abfrage( "w" );
      value = NA;
      unit  = NA;
      % Zerlege
      mantisse = str2double(substr( zeile, 1, 9));
      exponent = str2double(substr( zeile, 10, 3));
      einheit  = zeile(13);
      switch (einheit)
        case 'H'
          unit = "Hz";
        case 's'
          unit = "s";
          exponent= exponent-6; % Steht so im Pascal code Zeile 1049
        case ' '
          unit = ' ';
        otherwise
          obj.dprintf(0,"Error: unknown unit %c!",einheit);
          unit = '???';
      end

      value = mantisse*10^exponent;
    end

    % Frage Status ab
    function S = getStatus( obj )
      s = obj.abfrage( "z" );
      S = obj.translate(s(1),obj.statusTexte);
    end

    % Setze Status
    function setStatus( obj, standby=true )
      if (standby)
        obj.vorgabe("ZS",obj.ACK);
      else
        obj.vorgabe("ZM",obj.ACK);
      end
    end

    % Frage Auflösung ab, Ergebnis 1 bis 9
    function r = getResolution( obj )
      s = obj.abfrage( "a" );
      r = uint8( s(1)-'0' );
    end

    % Setze Auflösung resolution 1..9
    function setResolution( obj, resolution )
      obj.vorgabe( ["A", char( '0'+resolution)], obj.ACK );
    end

    % Frage Relais ab
    function r = getCoil( obj )
      s = obj.abfrage( "r" );
      r = false;
      if (s(1)=='E') r=true; end;
    end

    % Setze Relais - gibt es anscheinend nicht
    %function setCoil( obj, r )
    %  if (r)
    %    obj.vorgabe("RE",obj.ACK);
    %  else
    %    obj.vorgabe("RA",obj.ACK);
    %  end
    %end

    % Frage Messart ab
    function S = getMode( obj )
      s = obj.abfrage( "s" );
      S = obj.translate(s(1),obj.messartTexte);
    end

    % Setze Messart, mode ist einer der Buchstaben aus messartTexte
    function setMode( obj, mode )
      S = obj.translate(mode,obj.messartTexte);
      if (strcmp(S,"Unbekannt"))
        obj.dprintf("Unbekannte Messart %s, wird nicht gesetzt.\n",mode);
      else
        obj.vorgabe(["S", mode],obj.ACK);
      end
    end

  % End of public methods
  end

  % ---------------------------------------------------------------------------
  % Protected methods - at the moment public, change later on to protected
  methods (Access = public)

    % Übersetze Meldungen die aus einem Zeichen bestehen in lesbaren Text.
    function text = translate( obj, zeichen, tabelle )
      s = strcmp( zeichen, tabelle(:,1));
      if (sum(s)==0)
        text = "Unbekannt";
        obj.dprintf(0,"Fehler, Zeichen %c nicht in Tabelle\n",zeichen);
        return;
      end
      text = tabelle{s,2};
    end


    % Zum Debuggen, schöne Formatierung der Befehl und Antworten.
    % Steuerzeichen mit Namen in eckigen Klammern.
    function text = code2text( obj, code )
      text = ">";
      for i=1:length(code)
        switch code(i)
          case obj.SOH
            text = [text,"[SOH]"];
          case obj.ETX
            text = [text,"[ETX]"];
          case obj.CR
            text = [text,"[CR]"];
          case obj.ACK
            text = [text,"[ACK]"];
          case obj.NAK
            text = [text,"[NAK]"];
          case obj.EOT
            text = [text,"[EOT]"];
          otherwise
            text = [text,code(i)];
         endswitch
      endfor
      text = [text,"<"];
    endfunction


    % V24FZ.PAS Zeile 701
    function ok = sendeBefehl( obj, befehl )
      obj.dprintf(3,"Sende >%s<\n",obj.code2text(befehl));
      l = write(obj.serialPort, befehl);
      ok = l==length(befehl);
    end

    % V24FZ.PAs Zeile 719
    function line = leseAntwort( obj )
      ints = []; % create empty array
      i=1;
      while( 1 )
        v = read( obj.serialPort, 1); % read one character
        if (isempty(v)) % Nothing more to read, should not happen ...
          break;
        end
        if (v==obj.ACK || v==obj.NAK || v==obj.ETX) % Terminierungszeichen
          ints = [ints,uint8(v)];
          break;
        end
        ints = [ints,uint8(v)]; % add read character as uint8 to avoid cast problems
      end
      line = char(ints); % convert to text
      obj.dprintf(3,"Empfangen >%s<\n",obj.code2text(line));
    end

    % eine Abfrage stellen auf die eine Zeile als Antwort erwartet wird.
    % V24FZ.PAs Zeile 719
    % todo: Fehlerbehandlung, ACK am Ende der Antwort zeile herauslöschen.
    function zeile = abfrage( obj, zeile )
      obj.sendeBefehl( [zeile, char(obj.CR)] );
      zeile = obj.leseAntwort( );
    end

    % Vorgabe, überprüfe auf gewünschte antwort
    % Hängt automatisch CR an zeile an.
    function S = vorgabe( obj, zeile, antwortZeichen )
      obj.sendeBefehl( [zeile, char(obj.CR)] );
      obj.checkAntwort(antwortZeichen);
    end



    % Prüfe das Antwort Zeichen
    function checkAntwort( obj, zeichen )
      a = obj.leseAntwort();
      if ( !isempty(a) && a(1)==zeichen)
        obj.dprintf(2,"OK\n");
      else
        obj.dprintf("Fehler: erwarte %s, Empfangen %s\n", ...
        obj.code2text(zeichen), obj.code2text(a) );
      end
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

