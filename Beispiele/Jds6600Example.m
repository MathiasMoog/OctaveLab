% Joy-It JDS6600, example
% See jdsControll class
% Check for warnings in the output!
% Take care, the frequency measurement is not stable and there is no
% automatic range selection.
%
% Setup:
%  - Connect Joy-It JDS6600 with Computer
%  - Window / Linux: Check COM / tty Port, adopt in code see below
%  - Connect Ch1 output to Ext. IN
% Copyright, 2022, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA

% Usefull for development, clear classes, force a reload of the classdef file
clear classes; % delete all classes
fclose("all"); % close all files and ports


% Windows: Create Instance, adopt COM Port
jds = Jds6600();
jds.connect("COM27");
% Linux: adopt tty settings!
% jds.connect("/dev/ttyUSB0");


jds.getBasicSettings();

jds.setAmplitude(1,2.1)
jds.setFrequency(1,12345);

jds.setWaveForm(1,3);

jds.disconnect();

