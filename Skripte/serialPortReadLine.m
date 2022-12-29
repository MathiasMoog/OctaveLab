% Read a single line terminates by LF \n (10) or CR \r (13), default \n
% Use with instrument control serialPort
% replace readline from instrument-control package which is buggy.
% Copyright, 2019, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA
function line = serialPortReadLine( s, terminator='\n' )
  ints = uint8(1); % create int array
  i=1;
  while( 1 )
    v = read( s, 1); % read one character
    if (isempty(v)) % Nothing to read
      line = [];
      return;
    end
    if (v==terminator) % wait for line termination
      break;
    end
    ints(i++)=v;
  end
  line = char(ints);
end

