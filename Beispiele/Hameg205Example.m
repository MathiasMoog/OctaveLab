% Example Code for Hameg 205-3
%
% Preparation:
%  - Switch Scope on, activete "STOR" and "DUAL"
%  - Apply some signals ...
%  - Connect the Scope with the computer, adopt the serial port below.
%
% Copyright, 2023, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA
clear classes;

% Create instance
hm = Hameg205();

% Connect, adopt serial port!
hm.connect("COM22");

% Ask for two channels
% If "DUAL" is inactive, the channel is returned twice
hm.getCurves( 2 )
% Plot data
hm.plot( );

% Disconnect, don't forget otherwise the port is blocked
hm.disconnect();

% Store data if you like
%csvwrite("Scope.csv",hm.u)
