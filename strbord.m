################################################################################################
# strbord.m: Octave program to find with the streak ALEX images 
# the shock wave radial expansion over time by finding the borders...
#
# It uses the following functions, 
#		that should be in the same folder but for regdatasmooth:
# 			display_rounded_matrix		To ave the data in a proper and readable manner.
# 			supsmu						Cool data smoother.
# 			red_peaks						Litle function to eliminita noise from data, 
#											based on the separation between consecutive points.
# 			regdatasmooth from package "data_smoothing", that should be previously loaded.
################################################################################################



###############################################################################################
# INITIAL COMMANDS:
###############################################################################################

more off; %To make the lines display when they appear in the script, not at the end of it.

clear; %Just in case there is some data in memory.

tic; #Time controlling, used with toc;

pkg load data-smoothing #THE PACKAGE MUST BE INSTALLED BEFORE LOADING IT!!!!

#Angle of the gradient to be made on the image:
alpha = pi/4; %45 º

###############################################################################################
# LISTING ALL THE IMAGES TO PASS IN LOOP TO THE PROCESSING PART:
###############################################################################################
files = dir('ALEX*.tif'); #Take the *.tif files with an'ALEX' in. I
#The script assumes all the streak images to be analized are in the the same folder than the script
#	and of TIF extension. oTHER EXTENSION FILES COULD BE HERE, THEY WILL NOT BE LISTED.


for l=1:numel(files) #Begining of the image loop
	###############################################################################################
	# INITIAL LOAD OF THE IMAGE AND FIND AN APPROXIMATE "CENTER" TO POSTERIOR IMAGES PROCESSING:
	###############################################################################################

	disp(files(l).name); #Shot identification
	file = files(l).name;
	#Image load(It must be in a graphical format[ PNG, TIF, JPG, BMP tested] ):
	streak = imread(file);

	#Remove the mean of the first 10 temporal lines to avoid the laser light lines in the image:
	streak02 = streak - mean(streak(1:10,:));

	#Finding a center by adding all the temporal lines and from the resulting peak,
	#	chhose the borders with 30% of maximun intensity :
	center_vec =sum(streak02);
	[foo,idx_cen] = find(center_vec>=0.3*max(center_vec));
	#Approximate center:
	center = round( (idx_cen(end)-idx_cen(1))/2 + idx_cen(1));



	###############################################################################################
	# IMAGE PROCESSING ALGORITHM:
	###############################################################################################

	#First, it is done the gradient of the image at angle alpha(currently 45º) to enhance the borders:
	for i=1:1023
		for j=1:1343
			streak_mod(i,j) = sin(alpha).*(streak02(i,j) - streak02(i+1,j)) + cos(alpha).*(streak02(i,j) - streak02(i,j+1));
		endfor;
		streak_mod(i,:) =supsmu([1:1343],streak_mod(i,:),'Span',1e-2); %Smoothing to avoid most of the noise.
	endfor;

	#Now, the image is divided by the center in left and right part. 
	#	Generally, left part has more laser lines.
	left = streak_mod(:,1:center);
	right = streak_mod(:,center+1:end);

	#First attempt, discarded: Just the maximum at any temporal line.
	# [foo, l_max] = max(left,[],2);
	# [foo, r_max] = max(right,[],2);
	# r_max = r_max + center;

	#Initialization of radial expansion vectors:
	left_peaks = [];
	right_peaks = [];

	#Now, the images intensity is 'rescaled' in a logarithm,
	#	from were the less intense points are removed. 
	#	Then, only the borders of the shock wave and more things 
	#		inside of the images remaind.

	#Choosing intensitiy thresholds for the logarithm of the intensity images, 
	#	based on the total intensity of each part. 
	#	Larger thresholds for the more intense part:
	lsum = sum(sum(left)); #Total intensity counts of left side
	rsum = sum(sum(right));#Total intensity counts of right side
	if rsum > lsum #0.65 and 0.75 works fine, in principle
		rlimit = 0.75;
		llimit = 0.65;
	else
		rlimit = 0.75;
		llimit = 0.65;
	endif;
	#Images logarithms:
	left02 = log(left);
	right02 = log(right);
	#Maiking cero the less intense points, so the gradient is stronger and easier to find:
	left02(left02<=llimit*max(max(left02))) = 0;
	right02(right02<=rlimit*max(max(right02))) = 0;

	#Vemos la intensidad en tiempo de cada línea:
	left_int = sum(left02');
	right_int = sum(right02');

	#Let's use a simple addition to find were the hell the laser lines are:
	leffi = sum(left_int(1:10));
	riggy = sum(right_int(1:10));
	[foo,right_lines] = find(right_int==0);
	[foo,left_lines] = find(left_int==0);

	#It is taken as shock wave border the first point larger than 0 in the image(left or right), 
	#	but for the laser lines region, were it is taken the last one
	for i=1:rows(left02)
		if leffi > riggy #Definitely initial laser lines are in the left part...
			if i < left_lines(1)#Lines region, finding the shock wave with a  different method
				[foo, idx] = find(left02(i,:)>0);
				if length(idx)>0
					left_peaks = [left_peaks; i, idx(end)];
				endif;
			else #Out of lines region
				[foo, idx] = find(left02(i,:)>0);
				if length(idx)>0
					left_peaks = [left_peaks; i, idx(1)];
				endif;			
			endif;
		else #Initial laser lines are in the right part...
			[foo, idx] = find(left02(i,:)>0);
			if length(idx)>0
				left_peaks = [left_peaks; i, idx(1)];
			endif;	
		endif;
	endfor;
	#To the right side radius the addition of the center is necessary:
	for i=1:rows(right02)
		if riggy > leffi #Laser initial lines in the right part...
			if i < right_lines(1)#Lines region, finding the shock wave with a  different method
				[foo, idx] = find(right02(i,:)>0);
				if length(idx)>0
					right_peaks = [right_peaks; i, idx(end)+center];
				endif;
			else #Out of lines region
				[foo, idx] = find(right02(i,:)>0);
				if length(idx)>0
					right_peaks = [right_peaks; i, idx(1)+center];
				endif;			
			endif;
		else #Laser initial lines in the left image:
			[foo,idx] = find(right02(i,:)>0);
			if length(idx)>0
				right_peaks = [right_peaks; i, idx(end)+center];
			endif;
		endif;
	endfor;

	#Averaging the obtained points to have a better points system:
	left_peaks(:,2) =supsmu([1:length(left_peaks(:,2))],left_peaks(:,2),'span',0.01);
	right_peaks(:,2) =supsmu([1:length(right_peaks(:,2))],right_peaks(:,2),'span',0.01);

	#Removing too noisy data by removing the data with an excess of difference between consecutive values:
	right_peaks = red_peaks(right_peaks);
	left_peaks = red_peaks(left_peaks);

	#Finding the real center by averaging some central part of the image:
	center_peaks = [];
	if rows(left_peaks)>rows(right_peaks) #More points in the left....
		pos_left = round(rows(left_peaks)/2);
		time = left_peaks(pos_left,1);
		j = 0;

		for i=1:rows(right_peaks)
			if right_peaks(i,1) > time && j<20
				j = j+1;
				center_peaks = [center_peaks; (right_peaks(i,2) + left_peaks(pos_left+j,2))*0.5];
			endif;
		endfor;
	else #More points in the right
		pos_left = round(rows(left_peaks)/2);
		time = left_peaks(pos_left,1);
		j = 0;

		for i=1:rows(left_peaks)
			if right_peaks(i,1) > time && j<20
				j = j+1;
				center_peaks = [center_peaks; (right_peaks(i,2) + left_peaks(pos_left+j,2))*0.5];
			endif;
		endfor;
	endif;
	#Better value for the center:
	center = mean(center_peaks);



	###############################################################################################
	# RADIAL EXPANSION PROCESSING TO OBTAIN A SMOOTH AND NICE RADIAL VECTOR:
	###############################################################################################

	#Final radial shock wave expansion vector from the streak (Both sides 'tujeder'):
	radial_raw_sw = [left_peaks(:,1), abs(left_peaks(:,2)-center) ; right_peaks(:,1), abs(right_peaks(:,2)-center)];
	radial_raw_sw = sort(radial_raw_sw);

	#Version to compute, based in 'hacer equiespacial' the previous vector:
	t_pix = linspace(1,1023,1023)'; #time vector in pixels: 1023 points. PAY ATTENTION TO THE '
	#Smoothed final SW radius:
	radial_sw = [t_pix, regdatasmooth( radial_raw_sw(:,1)', radial_raw_sw(:,2)', "xhat", t_pix, "lambda", 0.7 )];



	###############################################################################################
	# MAKING A CHECKING RESULTS PLOT AND SAVING IT TO A PNG IMAGE:
	###############################################################################################

	f = figure('visible','off'); #not visible plot(in a loop is a pain to see the plot)
	imagesc(streak'); #Original image
	hold;
	plot(radial_sw(:,1),radial_sw(:,2)+center,'-w'); #Plotting the final radial SW expansion
	plot(radial_raw_sw(:,1),radial_raw_sw(:,2)+center,'*r'); #Points from were the previous expansion was find

	#Nice info on the plot:
	legend('Smoothed radial + Center','Raw radial + Center');
	title(file);
	xlabel('time (px)');
	ylabel('space (px)'),

	#Printing the plot at 150 points per inch resolution:
	print(f,'-r150','-dpng',horzcat(file(1:end-4),'-check.png'));



	###############################################################################################
	# SAVING DATA VECTORS:
	###############################################################################################

	#Saving the final radial data:
	#Output file name:
	name = horzcat(file,"_sw_radius.txt"); %Adding the right sufix to the shot name.
	output = fopen(name,"w"); %Opening the file.
	#First line:
	fdisp(output,"time(px)  sw_rad(px)");
	redond = [3 6]; %Saved precision 
	display_rounded_matrix(radial_sw, redond, output); %This function is not made by my.
	fclose(output); %Closing the file.
	disp(horzcat(name,' saved.'));

	#Saving the raw radial data:
	#Output file name:
	name = horzcat(file,"_sw_raw_radius.txt"); %Adding the right sufix to the shot name.
	output = fopen(name,"w"); %Opening the file.
	#First line:
	fdisp(output,"time(px)  sw_raw_rad(px)");
	redond = [3 6]; %Saved precision 
	display_rounded_matrix(radial_raw_sw, redond, output); %This function is not made by my.
	fclose(output); %Closing the file.
	disp(horzcat(name,' saved.'));

endfor; #End of the image loop



timing = toc;
###
# Total processing time
###

disp("Program strbord.m execution time:");
disp(timing /60);
disp(" min.");


more on;



#And tha...tha...that's all folks!!!!

