% Try UDP connection with Stamol L-LS-60
% Copyright, 2021, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA

sls = Sls60();
sls.debugLevel=17;

sls.connect("192.168.178.64",18190);


u = sls.measureVoltage()


%sls.disconnect();
