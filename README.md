# strbord
strbord: Octave program to obtain the shock wave from streak images.

## Usage:
Just call from the Octave console the program (strbord, from STReak shock wave BORDer) and it looks for the files with the streak data, in tif format, and gives as output the radial shock wave expansion, its raw values and a picture to check the results. Remember that the Octave functions must be in the same folder, too. check the strbord.m for more info, or the github repository.

## Needed Octave functions:

These functions must be in the same folder:

- supsmu.m  To smooth a vector. Used by strbord.m, the main program here.
- red_peaks.m	Octave function to eliminate noise points. Used by strbord.m, the main program here.
- display_rounded_matrix.m Octave function to present nicely data matrices.
