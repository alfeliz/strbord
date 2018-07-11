function peaks = red_peaks(piki)
#red_peaks: eliminate the noise peaks from a matrix with 2 columns
# and variable length.

resta = 100;

peaks = piki; #Initial value

while resta>0
	diffi01 = abs(diff(peaks(:,2)));

	su_dif01 = sum(diffi01);
	%~ su_dif01 = sum(diffi01)/length(diffi01);

	idx = find(diffi01>0.75);

	peaks(idx,:) = [];
	
	diffi02 = abs(diff(peaks(:,2)));

	su_dif02 = sum(diffi02);
	%~ su_dif02 = sum(diffi02)/length(diffi02);
	
	resta = su_dif01 -su_dif02;
endwhile;
