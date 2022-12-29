% Stamos S-LS-60, Test for measurements
% See slsControll class
% Check for warnings in the output!
% The first test is a manual test. Compare display frequency and test output
%
% Setup:
%  - Connect Joy-It JDS6600 with Computer
%  - Window / Linux: Check COM / tty Port, adopt in code see below
% Copyright, 2022, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA

% Usefull for development, clear classes, force a reload of the classdef file
clear classes; % delete all classes
fclose("all"); % close all files and ports


sls = Sls60();
% Windows: Create Instance, adopt COM Port
sls.connect("COM28");
% Linux: adopt tty settings!
% sls.connect("/dev/ttyUSB0");


disp("Try Measurements, compare with device ... ");
u = sls.measureVoltage()
i = sls.measureCurrent()
p = sls.measurePower()
f = sls.getFunction()

disp("Press anykey");
%pause;
sls.setFunction("CURR");
f = sls.getFunction()
sls.setCcCurrent(0.01);
icc = sls.getCcCurrent()
sls.setInput(true);
pause(0.5);
u = sls.measureVoltage()
i = sls.measureCurrent()
p = sls.measurePower()
sls.setInput(false);
inp = sls.getInput()

sls.disconnect();

