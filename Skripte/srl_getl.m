% Read a single line terminates by \n
% Copyright, 2019, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA
function line = srl_getl( s, terminator='\n' )
  ints = uint8(1); % create int array
  i=1;
  while( 1 )
    v = srl_read( s, 1); % read one character
    if (isempty(v)) % Nothing to read
      line = -1;
      return;
    end
    if (v==terminator) % wait for line termination
      break;
    end
    ints(i++)=v;
  end
  line = char(ints);
end

