% Joy-It JDS6600, Test for signal generator settings
% See jdsControll class
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


% Windows: Create Instance, adopt COM Port
jds = Jds6600();
jds.connect("COM27");
% Linux: adopt tty settings!
% jds.connect("/dev/ttyUSB0");

% Increase debug level
jds.debugLevel=2;


disp("Manual tests, get settings, check display .. ");
jds.getBasicSettings();

disp("Wait for anykey");
pause;

jds.setAmplitude(1,2.1)
disp("Wait for anykey");
pause;

jds.setOffset(1,-0.5)
disp("Wait for anykey");
pause;

jds.setOffset(1,1.5)
disp("Wait for anykey");
pause;

jds.setOffset(1,0)
disp("Wait for anykey");
pause;

jds.setDuty(1,0.3)
disp("Wait for anykey");
pause;

jds.setDuty(2,0.5)
disp("Wait for anykey");
pause;

jds.setPhase(90)
disp("Wait for anykey");
pause;

disp("Try Waveforms");
% Triangular and Partial sine gehen nicht in der Schleife aber auf der Kommandozeile.
n=length(jds.waveFormText)
for i=1:n
  jds.setWaveForm(1,i-1);
  disp("Wait for anykey");
  pause;
end;


jds.disconnect();
