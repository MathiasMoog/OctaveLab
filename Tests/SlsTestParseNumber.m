% Stamos S-LS-60, Test for parsing numbers
% Answer i.e. "0005V"
% Copyright, 2023, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA

% Try some typical values
line = "0035V"
unit = "V"

% code fragment from Ssl60.parseNumber( obj, unit)

% Adopt for Octave 9 !
        f = sprintf("%%f%s",unit)
        [v,c] = sscanf(line,f)
        if (c<1)
          printf("Error: No numerical Value in Answer %s\n",line);
          v=NA
        else
          v=v(1)
        end

% Check
assert(c>=1);

