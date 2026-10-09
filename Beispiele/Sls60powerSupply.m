% Try UDP connection with Stamol L-LS-60
% Measure Voltage of a power supply with increasing current.
% Copyright, 2021, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA

sls = Sls60();
sls.debugLevel=17;

sls.connect("192.168.178.64",18190);

sls.setCcCurrent(0);
sls.setInput(true);
  pause(0.5);

I=[];
U=[];
for i=0:0.25:1.8
 i
 sls.setCcCurrent(i);
 pause(0.3);
 u = sls.measureVoltage()
 pause(0.1);
 I=[I,i];
 U=[U,u];
 plot(I,U,"*-");
 xlabel("Current in A");
 ylabel("Voltage in V");
end

sls.setInput(false);


sls.disconnect();
