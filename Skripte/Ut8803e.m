classdef Ut8803e < handle
  % Class for serial / usb communication with the UT8803e Multimeter
  %
  % Wrapper arround Python interface. Based on Pythonic package.
  % Uses pyexec and pyeval instead of py. notation. The latter is unstable.
  %
  %
  % Copyright, 2024, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA

  % Public methods
  methods (Access = public)

    % Create Instance and load pythonic package
    function obj = Ut8803e( )
      % Load pythonic package
      pkg load pythonic
      % Load UT 8xxx class
      pyexec ("from ut8800 import ut8000")
      % Create Instance
      pyexec("ut = ut8000()")
    end

    % Connect to UT8803e, at the moment only one instrument possible
    % Internally selected by vid and pid of usb interface
    function ok = connect( obj)
      pyexec("ut.connect()")
      ok = pyeval ("ut.isConnected()")
    end

    % Disconnect from power supply. Close com port
    function disconnect( obj )
      pyexec("ut.disconnect()")
    end

    % Messdaten abholen.
    % Nutzbar wenn das Gerät im USB Modus (regelmäßige Übertragung) ist.
    % Liefert den numerischen Wert (dezimale Vielfache eingerechnet) und die
    % Einheit.
    % Diese Funktion liefert das erste Ergebniss im Puffer des Seriellen Ports.
    function [value, unit] = getValue( obj )
      m = pyeval ("ut.getValue()")
      # m ist ein python tuple das umgewandelt und zerlegt werden muss:
      value = m{1}
      unit = char(m{2})
    end

    % Get last value
    % Nützlich im COMM Modus wenn nicht ganz regelmäßig Daten abgeholt werden,
    % Dann können mehrer Messwerte im Buffer des serial port liegen.
    % Lese alle weg, werte nur die letzte aus.
    function [value, unit] = getLastValue( obj );
      m = pyeval ("ut.getLastValue()")
      # m ist ein python tuple das umgewandelt und zerlegt werden muss:
      value = m{1}
      unit = char(m{2})
    endfunction

  % End of public methods
  end

end

