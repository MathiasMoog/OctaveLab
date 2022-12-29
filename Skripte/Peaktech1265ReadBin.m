% Einlesen der bin Dateien die das PeakTech 1265 schreibt
%
% Rudimentäre Format Spezifikation unter
%  http://bikealive.nl/owon-bin-file-format.html  -> BinFormat.odt
% OWON Oscilloscope PC Guidance Manual, Abschnit 3.2
%
% Berechne Amplitude durch x = bin.data - bin.offset
%
% Folgende Werte scheinen vernünftig:
%  bin.samples
%  bin.offset
%  bin.data
%
% Bei den restlichen Werten erschließt sich mir die Bedeutung noch nicht.
%
% Zur Verwendung in anderen Verzeichnissen: addpath( [ myhome "/Elektro/Geraete/Peaktech1265" ] );

function bin = Peaktech1265ReadBin( fname )
  fid = fopen( fname, "rb" );
  if (fid==0)
    printf(" Datei konnte nicht geöffnet werden \n");
    s=-1;
    return;
  endif;
  % Header einlesen                               Beginn
  bin.format      = char( fread(fid, 6, "char" )' );     % 0
  bin.number      = fread(fid, 1, "uint32" );            % 6
  bin.channel     = char( fread(fid, 3, "char")' );      % 10
  bin.x0d         = fread(fid, 1, "uint32" );            % 13 = 0x0d
  bin.x11         = fread(fid, 1, "uint32" );            % 17 = 0x11
  bin.disp_start  = fread(fid, 1, "uint32" );            % 21 = 0x15
  bin.disp_length = fread(fid, 1, "uint32" );            % 25 = 0x19
  bin.samples     = fread(fid, 1, "uint32" );            % 39 = 0x1d
  bin.x21         = fread(fid, 1, "uint32" );            % 17 = 0x21
  bin.timebase    = fread(fid, 1, "uint32" );            % 17 = 0x25
  bin.offset      = fread(fid, 1, "int32" );            % 17 = 0x29
  bin.vertical    = fread(fid, 1, "uint32" );            % 17 = 0x2d
  bin.attenuation = fread(fid, 1, "uint32" );            % 17 = 0x31
  bin.x35         = fread(fid, 1, "float32" );            % 17 = 0x35
  bin.x39         = fread(fid, 1, "float32" );            % 17 = 0x39
  bin.x3d         = fread(fid, 1, "float32" );            % 17 = 0x3d
  bin.x41         = fread(fid, 1, "float32" );            % 17 = 0x41
  % Daten einlesen
  bin.data        = fread(fid, bin.samples, "int8");

  fclose(fid);
endfunction
