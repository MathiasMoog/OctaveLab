% Estimate innner Resistor (Ri) for a battery with the
% Stamos S-LS-60 electronic load.
% See slsControll class for communication details.
%
% Setup:
%  - Connect Stamos S-LS-60 with Computer (USB)
%  - Window / Linux: Check COM / tty Port, adopt in code see below
%  - Connect Battery to Electronic Load.
%
% Function call:
%  port - USB Port
%  C    - Battery Capacity in Ah
%  Umin - Minimal Battery Voltage
%
% Example:
%  SlsBatteryRi("COM1",6.5,11.5)
%  8.4 V, NiMH: SlsBatteryRi("COM1",0.2,7.0) or SlsBatteryRi("192.168.178.64",0.2,7.0)
%    New 2 Ohm, old 13 Ohm
%  PB, 12 V, 7.2 Ah: SlsBatteryRi("COM28",7.2,11)
%
% Result:
%  Estimate for Ri and standard deviation of Ri (DeltaRi)
%
% Measurement:
%  Measure Voltage without load and with C*[0.1, 0.2 .. 1.5] current.
%  Estimate Ri for each current. Calculate mean and stdandard deviation at the end.
%
% ToDo:
%  Flag for debug and plot
%
% Copyright, 2022, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA
function [ Ri, DeltaRi ] = SlsBatteryRi( port, C, Umin )
  % load statistics package
  pkg load statistics
  % initialize load
  sls = Sls60();
  if (!sls.connect( port ))
    sls.disconnect();
    error("No connection to electronic load");
  endif

  % Set default result value
  Ri = NA;
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
  if (u0<1.0 || u0<Umin)
    sls.disconnect();
    error("Voltage u0=%.2f V even without load to low!",u0);
  end
  if (i0>1e-3)
    sls.disconnect();
    error("Current in OFF mode too large i0=%.4f A!",i0);
  end
  % run with several multipliers of C
  cm = [ 0.1, 0.2, 0.5, 1, 1.5 ];
  ri = zeros(size(cm))*NA;
  u  = zeros(size(cm))*NA;
  n=length(cm);
  for i=1:n
    printf("Check with C x %f\n",cm(i));
    u0 = sls.measureVoltage()
    i0 = sls.measureCurrent()
    % Configure constant current
    sls.setCcCurrent(C*cm(i));
    % Switch load on, wait a moment ...
    sls.setInput(true);
    pause(0.5);
    % Measure Again
    ul = sls.measureVoltage()
    il = sls.measureCurrent()
    % Switch off
    sls.setInput(false);
    % Check minimal voltage
    if (u0<Umin)
      warning("Voltage with load to low! Check Battery!");
      break;
    end
    % Estimate Ri
    ri(i) = (u0-ul)/(il-i0) % Ri should be positive ...
    u(i)  = ul;
  end
  % disconnect from load
  sls.disconnect();
  % Nice Plot
  plot(cm,ri,"*-");
  xlabel("C x ...");
  ylabel("Ri in Ohm");
  title(sprintf("Innenwiderstand, C=%.2f Ah, Umin=%.1f V",C,Umin));
  for i=1:n
    if (isfinite(u(i)))
      text(cm(i)+0.1,ri(i),sprintf("u=%.2f V",u(i)));
    end
  end
  % statistics ...
  Ri = nanmean(ri)
  DeltaRi = nanstd(ri)
end
