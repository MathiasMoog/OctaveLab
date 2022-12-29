% Joy-It JDS6600, Test for arbitrary wave forms
% See jdsControll class
% Run the test, check for errors, compare wave form in octave plot and on JDS
%
% Setup:
%  - Connect Joy-It JDS6600 with Computer
%  - Window / Linux: Check COM / tty Port, adopt in code see below
% Copyright, 2022, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA

% Usefull for development, clear classes, force a reload of the classdef file
clear classes; % delete all classes
fclose("all"); % close all files and ports


% Windows: Create Instance, adopt COM Port
jds = Jds6600();
jds.connect("COM27");
% Linux: adopt tty settings!
% jds.connect("/dev/ttyUSB0");

% Increase debug level
jds.debugLevel=3;

data = jds.getArbitraryWave(1);
jds.plotArbitraryWave(1);

% Set it back ..
jds.setArbitraryWave( 1, data )
jds.setWaveForm(1,101);


disp("Wait for anykey");
%pause;

% generate a new funtion
jds.setWaveForm(1,1);
jds.setArbitraryWaveFunction(1, @cos, 0, 2*pi)
jds.setWaveForm(1,101);
jds.plotArbitraryWave(1);


jds.disconnect();

