% Joy-It JDS6600, Test for freqzency measurement
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


jds.setExtMeasure(1);
jds.setExtMeasureGateTime(1.0);
f = 12.34567;

for i=1:3
  jds.setFrequency(1,f);
  f_get = jds.getFrequency(1)
  rel   = abs(f-f_get)/max(2000,f)
  if ( rel > 1e-3 )
    warning(sprintf("Read back, frequency difference too large, set %f Hz, get %f Hz, abs %f Hz, rel %.2e", ...
      f,f_get,f-f_get,rel));
  end
  pause(3*jds.extGateTime+0.2);
  f_in  = jds.getFrequency(0)
  rel   = abs(f-f_in)/max(2000,f)
  if ( rel > 1e-3 )
    warning(sprintf("Measure, frequency difference too large, set %f Hz, get %f Hz, abs %f Hz, rel %.2e", ...
      f,f_in,f-f_in,rel));
  end
  f *= 10;
end

%jds.send('w',33,4);
%jds.send('r',36,2);


jds.disconnect();

