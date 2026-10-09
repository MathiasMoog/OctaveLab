% Try UDP connection with Stamol L-LS-60
% Copyright, 2021, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA
%
% Test von USB Netzteilen

% Maximaler Strom
Imax = 3; %in A
% Minimale Spannung
Umin = 4.4; % in V
% Schrittweite für Stromteilung
n=0.25;

sls = Sls60();
sls.debugLevel=0;

sls.connect("192.168.178.31",18190);

% Run Measurement
disp("Measure without load");
sls.setInput(false);
pause(0.1);
u0 = sls.measureVoltage()
i0 = sls.measureCurrent()
if (~isfinite(u0) || ~isfinite(i0))
    sls.disconnect();
    error("No valid measurments. Check load.");
end
if (u0<Umin)
    sls.disconnect();
    error("Voltage u0=%.2f V even without load to low!",u0);
end
if (i0>1e-3)
    sls.disconnect();
    error("Current in OFF mode too large i0=%.4f A!",i0);
end
U=[];
I=[];
for i=0:0.25:Imax
    % Configure constant current
    sls.setCcCurrent(i);
    % Switch load on, wait a moment ...
    sls.setInput(true);
    pause(0.5);
    % Measure Again
    ul = sls.measureVoltage()
    il = sls.measureCurrent()
    U=[U,ul];
    I=[I,il];
    % Switch off
    sls.setInput(false);
    % Check minimal voltage
    if (ul<Umin)
      warning("Voltage with load to low! Check Battery!");
      break;
    end
    plot(I,U);
    xlabel("current I in A");
    ylabel("voltage U in V");
end
% disconnect from load
sls.disconnect();

csvwrite("PowerSupply.csv",[U',I']);

