% Discharge a battery with the Stamos S-LS-60 electronic load.
% See slsControll class for communication details.
%
% Setup:
%  - Connect Stamos S-LS-60 with Computer (USB)
%  - Window / Linux: Check COM / tty Port
%  - Connect Battery to Electronic Load.
%
% Function call:
%  port - USB/serial Port
%  I    - Discharging current
%  Umin - Minimal Battery Voltage
%
% Example:
%  [td, cd, ed, t, u, i] = slsBatteryDischarge( "COM28",2,11)
%
% Result:
%  Estimate for the disharge time td in h, capacity cd in Ah and energy ed
%  in Wh.
%  Additional return curves t, u and i. The first and the last point in
%  these curves are without load.
%
% Measurement:
%  Discharge until Umin reached.
%
% Press ON/OFF on the load to interrupt the discarging process.
%
% Copyright, 2022, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA
function [td, cd, ed, t, u, i] = SlsBatteryDischarge( port, I, Umin )
  sls = Sls60();
  if (!sls.connect( port ))
    sls.disconnect();
    error("No connection to electronic load");
  endif

  % First point, no load ...
  t = -1/3600; % virtual start, -1 seconds ...
  u = sls.measureVoltage();
  i = sls.measureCurrent();
  p = sls.measurePower();
  if (u<1.0 || u<Umin)
    error("Voltage u=%.2f V even without load to low!",u0);
  end
  sls.setCcCurrent(I);
  % Switch load on, wait a moment ...
  sls.setInput(true);
  pause(0.5);
  T = time(); % Starting time in seconds since epoch.
  do
    % Measure
    t = [t,(time()-T)/3600.0];
    u = [u,sls.measureVoltage()];
    i = [i,sls.measureCurrent()];
    p = [p,sls.measurePower()];
    % Nice output
    % todo add debug level ...
    printf("t=%4.2f h, u=%5.3f V, i=%5.3f A, c=%5.3f Ah, e=%5.3f Wh\n", ...
      t(end),u(end),i(end),trapz(t,i),trapz(t,p));
    plot(t,u);
    % Wait one second
    pause(1);
  until (u(end)<=Umin || ~sls.getInput() );
  % Switch off
  sls.setInput(false);
  % Pimp up the plot
  xlabel("Entladezeit in h");
  ylabel("Spannung in V");
  title(sprintf("Entladen eines Akkus mit %.2f A bis auf %.2f V",I,Umin));
  % Estimate capacity and energy
  td = t(end);
  cd = trapz(t(2:end),i(2:end)); % ommit the first (virtual) point
  ed = trapz(t(2:end),p(2:end));
  % Add a last point to the curve, load switched off
  t = [t,(time()-T)/3600.0];
  u = [u,sls.measureVoltage()];
  i = [i,sls.measureCurrent()];
  % close connection
  sls.disconnect();
end
