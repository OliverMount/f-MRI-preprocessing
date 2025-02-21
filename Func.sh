#!/bin/bash 

# This program is for functional processing of NKI data
# Data orientation is assumed to be LPI for all the datasets


# Specify the MNI template here
cd /mnt/NAS/fMRI/Rstate/NKIQpassed/

echo -e "\n Beginning the functional Processing ...\n"
Template=/mnt/NAS/fMRI/templates/MNI152_T1_3mm_brain.nii.gz  # MNI template


declare -a arr=("645" "1400" "cap")       # Types of TR files 


subs=`ls -d *`
#subs=A00058685

for sub in $subs
do

echo -e "\n ================================================= "
echo -e "\n Processing Subject $sub ... \n "
echo -e " =================================================== \n "


cd $sub

for k in 0 1 2                # 3 TR files in each subject
do

echo -e "\n ================================================= "
echo -e "\n Processing TR $k ... \n "
echo -e " =================================================== \n "



if [ ! -d Func$k ]; then
	echo -e "\n Making directory Func$k for storing results... \n"
	mkdir Func$k
	else  
	echo -e "\n Directory Func$k already exits... \n"
fi

cd Func$k

# Parameter Initializations

        vd=5   # No. of initial volumes to be deleted 
	FDt=0.4  # Frame Displacement threshold
	cons=0.8725; #(50*3.141/180); # for converting motion angles to mm with (50 mm length assumption from head center to the cerebral cortex) 

	NoB=1 # No of bricks to censor before 
	NoA=2  # No of bricks to censor after
		

# Beginning of functional processing  
              
# Copying of original volumes
if [ ! -f 1F+orig.BRIK ]; then
        echo -e "\n Copying original volume ...\n"
	3dcopy ../rest_${arr[$k]}+orig. 1F
	else
	echo -e "\n fMRI volume already copied...\n"	
fi


# Removing first few volumes
if [ ! -f 2VolRe+orig.BRIK ]; then
	echo -e "\n Removing the first ${vd} volumes...\n"
	3dTcat 1F+orig'['$vd'..$]' -prefix 2VolRe    # give manually the initial number of slices to remove
	else
	echo -e "\n Already done with removing volumes...\n"	
fi

# Getting file information
if [ ! -f 1VolPara.1D ]; then

	echo -e "\n Getting file info ...\n "
	3dinfo -tr -ntimes -nk -is_oblique 2VolRe+orig.  > 1VolPara.1D
	TR=`awk '{print $1}'  1VolPara.1D`    # TR
	Len=`awk '{print $2}'  1VolPara.1D`   # Length of the Time series
	NS=`awk '{print $3}'  1VolPara.1D`   # Number of slices within each volume
	# MidSlice="$((${Fina}/2))"      # Midslice for Slice timing correction
	Ob=`awk '{print $4}'  1VolPara.1D`   # Oblicity of the data
	# Fina="$(($Len-$vd))"              # length after removing first vd volumes
	Mid="$((${Len}/2))"	          # Mid volume for motion correction
	Len1="$((${Len}-2))"	          # For calculating Friston 24 Parameter

	else
	echo -e "\n File information already obtained...\n"

fi

# Slice timing correction
if [ ! -f 3STC+orig.BRIK ]; then
	        
        echo -e "\n Performing slice-timing correction \n " # Interleaved data, so Slice timing followed by motion correction
	3dTshift -tzero 0 -TR ${TR}s -prefix 3STC  2VolRe+orig.
	else
	echo -e "\n Aldready done with slice time correction ...\n"

fi  

# Deoblique the data
if [ ! -f 3DeObli+orig.BRIK ]; then
	if [ $Ob ] ;then 
		echo -e "\n Data is oblique... Deobliquing... \n"
		3dWarp -deoblique -prefix 3DeObli  3STC+orig.   				
		filename=3DeObli+orig.
	else
		echo -e "\n Data is at plumb ... Skipping deobliquing ... \n"
		filename=3STC+orig.
	fi
fi

# Reorient the data as in Anatomical processing
if [ ! -f 3ReOri+orig.BRIK ]; then
	echo -e "\n Reorienting Template  and  Dataset to LPI view \n "
	3dresample -orient LPI -prefix MNITemp.nii.gz -inset $Template          # MNI template reorienting to LPI 
	3dresample -orient LPI -prefix 3ReOri -inset ${filename}           
	else
	echo -e "\n Aldready done with reorienting...\n"
fi
	    
# EPI Volume Alignment (Motion correction)
if [ ! -f 4RegtoMid+orig.BRIK ]; then
	echo -e "\n EPI volume alignment, estimating motion parameters ... \n"

	#3dvolreg -base ${Mid} -heptic -zpad 4 \   ## (EPI to EPI registration) # n  roll  pitch  yaw  dS  dL  dP  rmsold rmsnew
	#-prefix 4RegtoMid \   # (Output dataset)
	#-dfile MotionPara.1D \   #-1Dfile MotionFileIndex.1D \  #-rotcom \    # (Will display the 3drotate fragments)
	#-1Dmatrix_save Realign.1D  # Motion realignment file	
	# 3ReOri+orig   # (Input data set)

	3dvolreg -base ${Mid} -heptic -zpad 4 -prefix 4RegtoMid -dfile MotionPara.1D 3ReOri+orig   # (Input data set)	

	else
	echo -e "\n Aldready done with motion correction ...\n"	
fi
     
		
# Calculating framewise displacement (fd) ...

if [ ! -f Censor.1D ]; then
	
	echo -e "\n Calculating framewise displacement (fd) ... \n"	
	1d_tool.py -infile MotionPara.1D'[1..6]' -derivative -write D.1D  # (backward difference) set overwrite here #1d_tool.py -infile MotionPara.1D -forward_diff  -write D.1D 
1deval -expr 'abs(a)+abs(b)+abs(c)+'${cons}'*abs(d)+'${cons}'*abs(e)+'${cons}'*abs(f)' -a D.1D'[0]' -b D.1D'[1]' -c D.1D'[2]' -d D.1D'[3]' -e D.1D'[4]' -f D.1D'[5]' > FD.1D
	1deval -a FD.1D  -expr 'ispositive(a-'${FDt}')' > Censor.1D   # FD censored file
	# 1dplot FD.1D
	# Comparing with fsl FD
	# fsl_motion_outliers -i 3ReOri.nii -o MotionConfound.txt -s fd.txt -p plot_fd.png --fd --thresh=0.3
	else
	echo -e "\n Already done with FD calculation ... \n"
fi


# Brain only region
if [ ! -f 6MaskedBrain+orig.BRIK ]; then
	echo -e "\n Generating binary mask of the whole brain...\n"  
	3dAutomask -q -prefix 5BrainMask  4RegtoMid+orig
	3dcalc -a 4RegtoMid+orig. -b 5BrainMask+orig. -expr 'ispositive(b)*a' -prefix 6MaskedBrain
	else
	echo -e "\n Aldready done with obtaining Brain only regions ...\n"	
fi

# Mean volume
if [ ! -f 7MeanVol+orig.BRIK ]; then
	echo -e "\n Finding the mean volume...\n "
	3dTstat -mean -prefix 7MeanVol 6MaskedBrain+orig  # mean across time-- mean volume.  This function also contains autocorrelation, AR
	else
	echo -e "\n Aldready obtained the mean volume ...\n"	
fi


# Coregistration and Spatial Normalization  
if [ ! -f 8CoReg+orig.BRIK ]; then
	echo -e "\n Coregistering EPI with anatomical volume...\n "
	3dAllineate -quiet -base ../Anat/3SSFinal+orig -1Dmatrix_save 8CoReg.1D -input 7MeanVol+orig -EPI -warp aff   # Find transformation matrix (affine general 12 Para)
	3dAllineate -quiet -master ../Anat/3SSFinal+orig -1Dmatrix_apply 8CoReg.1D -prefix 8CoReg -input 6MaskedBrain+orig # Apply it to all 
 	# 3dcalc -a 8CoReg+orig -b ../Anat/3SSbeastmask+orig. -expr 'ispositive(b)*a' -prefix 8CoRegMasked  # Anatomical masking of the co-registered data
	else
	echo -e "\n Aldready done with Co-registration ...\n"	
fi

if [ ! -f 9RegEPI+tlrc.BRIK ]; then
	echo -e "\n Spatial normalizing with MNI ...\n "
	3dAllineate -quiet -master MNITemp.nii.gz -1Dmatrix_apply ../Anat/4RegBeast_Allin.aff12.1D -input 8CoReg+orig -prefix 9RegEPI 8CoRegMasked 
	#3dAllineate -quiet -master MNITemp.nii.gz -1Dmatrix_apply ../Anat/4RegBeast_Allin.aff12.1D -input 8CoRegMasked+orig -float -final linear -prefix 9RegEPI 8CoRegMasked 
	else
	echo -e "\n Aldready done with spatial normalization ...\n"	
fi


# Extracting CSF and WM time series  (Using eroded CSF and WM )
if [ ! -f WM.1D ]; then
	echo -e "\n Extracting CSF time series...\n" 
	3dmaskave -q -mask ../Anat/CSFEdgemask+tlrc. 9RegEPI+tlrc. > CSF.1D   

	echo -e "\n Extracting WM time series...\n" 
	3dmaskave -q -mask ../Anat/WMEdgemask+tlrc. 9RegEPI+tlrc. > WM.1D

	else
	echo -e "\n Aldready extracted the CSF and WM time series for GLM regression ...\n"	

fi

# 24 parameter motion file creation

	echo -e "\n Calculating Friston 24 motion parameters ... \n"

	1dcat MotionPara.1D'[1..6]' > MotionFile1.1D  # 6 motion parameters
	echo 0 0 0 0 0 0 > MotionFile2.1D    
	1dcat MotionPara.1D'[1..6]{0..'$Len1'}' > MotionFile3.1D
	cat MotionFile2.1D MotionFile3.1D > MotionFile4.1D
	1dcat MotionFile1.1D MotionFile4.1D > MotionFile5.1D

	for kk in {0..11} 
	do
		1deval -expr 'a*b' -a MotionFile5.1D'['$kk']' -b MotionFile5.1D'['$kk']' > temp.1D
		1dcat MotionFile5.1D temp.1D > MotionFile6.1D
		mv MotionFile6.1D MotionFile5.1D
	done

	mv MotionFile5.1D Fris24.1D
	rm MotionFile*.1D


# Nuisance regression
if [ ! -f 10TS+tlrc.BRIK ]; then
	echo -e "\n Beginning the GLM analysis ... \n"
  	3dDeconvolve -input 9RegEPI+tlrc. -polort 4 -num_stimts 26 \
	           -stim_file 1 CSF.1D -stim_label 1 CSF \
	           -stim_file 2 WM.1D -stim_label 2 WM \
	           -stim_file 3 Fris24.1D[0] -stim_base 3 -stim_label 3 trans_x \
	           -stim_file 4 Fris24.1D[1] -stim_base 4 -stim_label 4 trans_y \
	           -stim_file 5 Fris24.1D[2] -stim_base 5 -stim_label 5 trans_z \
	           -stim_file 6 Fris24.1D[3] -stim_base 6 -stim_label 6 rot_x \
	           -stim_file 7 Fris24.1D[4] -stim_base 7 -stim_label 7 rot_y \
	           -stim_file 8 Fris24.1D[5] -stim_base 8 -stim_label 8 rot_z \
	           -stim_file 9 Fris24.1D[6] -stim_base 9 -stim_label 9 trans_xdt \
	           -stim_file 10 Fris24.1D[7] -stim_base 10 -stim_label 10 trans_ydt \
	           -stim_file 11 Fris24.1D[8] -stim_base 11 -stim_label 11 trans_zdt \
	           -stim_file 12 Fris24.1D[9] -stim_base 12 -stim_label 12 rot_xdt \
	           -stim_file 13 Fris24.1D[10] -stim_base 13 -stim_label 13 rot_ydt \
	           -stim_file 14 Fris24.1D[11] -stim_base 14 -stim_label 14 rot_zdt \
	           -stim_file 15 Fris24.1D[12] -stim_base 15 -stim_label 15 trans_x2 \
	           -stim_file 16 Fris24.1D[13] -stim_base 16 -stim_label 16 trans_y2 \
	           -stim_file 17 Fris24.1D[14] -stim_base 17 -stim_label 17 trans_z2 \
	           -stim_file 18 Fris24.1D[15] -stim_base 18 -stim_label 18 rot_x2 \
	           -stim_file 19 Fris24.1D[16] -stim_base 19 -stim_label 19 rot_y2 \
	           -stim_file 20 Fris24.1D[17] -stim_base 20 -stim_label 20 rot_z2 \
	           -stim_file 21 Fris24.1D[18] -stim_base 21 -stim_label 21 trans_xdt2 \
	           -stim_file 22 Fris24.1D[19] -stim_base 22 -stim_label 22 trans_ydt2 \
	           -stim_file 23 Fris24.1D[20] -stim_base 23 -stim_label 23 trans_zdt2 \
	           -stim_file 24 Fris24.1D[21] -stim_base 24 -stim_label 24 rot_xdt2 \
	           -stim_file 25 Fris24.1D[22] -stim_base 25 -stim_label 25 rot_ydt2 \
	           -stim_file 26 Fris24.1D[23] -stim_base 26 -stim_label 26 rot_zdt2 \
	           -GOFORIT -errts 10TS


# One line version
#3dDeconvolve -input 9RegEPI+tlrc. -polort 2 -num_stimts 26 -stim_file 1 CSF.1D -stim_label 1 CSF -stim_file 2 WM.1D -stim_label 2 WM -stim_file 3 Fris24.1D[0] -stim_base 3 -#stim_label 3 trans_x -stim_file 4 Fris24.1D[1] -stim_base 4 -stim_label 4 trans_y -stim_file 5 Fris24.1D[2] -stim_base 5 -stim_label 5 trans_z -stim_file 6 Fris24.1D[3] -#stim_base 6 -stim_label 6 rot_x -stim_file 7 Fris24.1D[4] -stim_base 7 -stim_label 7 rot_y -stim_file 8 Fris24.1D[5] -stim_base 8 -stim_label 8 rot_z -stim_file 9 Fris24.1D[6] -#stim_base 9 -stim_label 9 trans_xdt -stim_file 10 Fris24.1D[7] -stim_base 10 -stim_label 10 trans_ydt -stim_file 11 Fris24.1D[8] -stim_base 11 -stim_label 11 trans_zdt -#stim_file 12 Fris24.1D[9] -stim_base 12 -stim_label 12 rot_xdt -stim_file 13 Fris24.1D[10] -stim_base 13 -stim_label 13 rot_ydt -stim_file 14 Fris24.1D[11] -stim_base 14 -#stim_label 14 rot_zdt -stim_file 15 Fris24.1D[12] -stim_base 15 -stim_label 15 trans_x2 -stim_file 16 Fris24.1D[13] -stim_base 16 -stim_label 16 trans_y2  -stim_file 17 #Fris24.1D[14] -stim_base 17 -stim_label 17 trans_z2 -stim_file 18 Fris24.1D[15] -stim_base 18 -stim_label 18 rot_x2 -stim_file 19 Fris24.1D[16] -stim_base 19 -stim_label 19 #rot_y2 -stim_file 20 Fris24.1D[17] -stim_base 20 -stim_label 20 rot_z2 -stim_file 21 Fris24.1D[18] -stim_base 21 -stim_label 21 trans_xdt2 -stim_file 22 Fris24.1D[19] -#stim_base 22 -stim_label 22 trans_ydt2 -stim_file 23 Fris24.1D[20] -stim_base 23 -stim_label 23 trans_zdt2 -stim_file 24 Fris24.1D[21] -stim_base 24 -stim_label 24 rot_xdt2 -#stim_file 25 Fris24.1D[22] -stim_base 25 -stim_label 25 rot_ydt2 -stim_file 26 Fris24.1D[23] -stim_base 26 -stim_label 26 rot_zdt2 -GOFORIT -censor MC.1D -errts 10TS


	else
	echo -e "\n Aldready done with Nuisance regression ...\n"	
fi



# Brain only region Before temporal filtering. Needed in R for DOF mask calculation

if [ ! -f 10MaskedBrain+tlrc.BRIK ]; then
	echo -e "\n Generating binary mask of the MNI BF time serues...\n"  
	3dAutomask -q -prefix 10MaskedBrain  10TS+tlrc.
	else
	echo -e "\n Aldready done with obtaining Brain only regions ...\n"	
fi


# Network anallysis before temporal filtering

echo -e "\n Beginning connectivity analysis for various resting state networks (Before Filtering) ... \n" 

#PCC seed

echo -e "\n \n Default Mode Network ... \n \n" 
echo "-2 -54 26" | 3dUndump -prefix PCCmask -srad 5 -master 10TS+tlrc.  -xyz -
3dmaskave  -quiet -mask PCCmask+tlrc. 10TS+tlrc. > PCC_tsBF.1D
3dfim+ -bucket PCC_BF -out Correlation  -ideal_file PCC_tsBF.1D  -input 10TS+tlrc.

# EXEC NEtwork
echo "-24 40 32" | 3dUndump -prefix dlPFCmask -srad 5 -master 10TS+tlrc.  -xyz -
3dmaskave  -quiet -mask dlPFCmask+tlrc. 10TS+tlrc. > dlPFC_tsBF.1D
3dfim+ -bucket dlPFC_BF -out Correlation  -ideal_file dlPFC_tsBF.1D  -input 10TS+tlrc.


# IPS seed
echo "-23 -70 46" | 3dUndump -prefix IPSmask -srad 5 -master 10TS+tlrc.  -xyz -
3dmaskave  -quiet -mask IPSmask+tlrc. 10TS+tlrc. > IPS_tsBF.1D
3dfim+ -bucket IPS_BF -out Correlation  -ideal_file IPS_tsBF.1D  -input 10TS+tlrc.

# PVC seed
echo "-2 -82 4" | 3dUndump -prefix PVCmask -srad 5 -master 10TS+tlrc.  -xyz -
3dmaskave  -quiet -mask PVCmask+tlrc. 10TS+tlrc. > PVC_tsBF.1D
3dfim+ -bucket PVC_BF -out Correlation  -ideal_file PVC_tsBF.1D  -input 10TS+tlrc.

# PAC seed
echo "-48 -24 9" | 3dUndump -prefix PACmask -srad 5 -master 10TS+tlrc.  -xyz -
3dmaskave  -quiet -mask PACmask+tlrc. 10TS+tlrc. > PAC_tsBF.1D
3dfim+ -bucket PAC_BF -out Correlation  -ideal_file PAC_tsBF.1D  -input 10TS+tlrc.

# PMC seed
echo "-38 -22 60" | 3dUndump -prefix PMCmask -srad 5 -master 10TS+tlrc.  -xyz -
3dmaskave  -quiet -mask PMCmask+tlrc. 10TS+tlrc. > PMC_tsBF.1D
3dfim+ -bucket PMC_BF -out Correlation  -ideal_file PMC_tsBF.1D  -input 10TS+tlrc.

# Putamen seed
echo "25 -1 0" | 3dUndump -prefix Putamask -srad 5 -master 10TS+tlrc.  -xyz -
3dmaskave  -quiet -mask Putamask+tlrc. 10TS+tlrc. > Puta_tsBF.1D
3dfim+ -bucket Puta_BF -out Correlation  -ideal_file Puta_tsBF.1D  -input 10TS+tlrc.

# IFG seed
echo "50 23 2" | 3dUndump -prefix IFGmask -srad 5 -master 10TS+tlrc.  -xyz -
3dmaskave  -quiet -mask IFGmask+tlrc. 10TS+tlrc. > IFG_tsBF.1D
3dfim+ -bucket IFG_BF -out Correlation  -ideal_file IFG_tsBF.1D  -input 10TS+tlrc.



# Temporal bandpass filtering

echo -e "\n Bandpass filtering for various bandwidths \n"
f_low=0.009                                             # Fixed low cut-off frequency
MaxFreq=$(awk -v n=$TR 'BEGIN { print 1/(2*n) }')      # Finding the maximum analysis frequency
echo "\n Max. Analysis frequency  for TR of ${TR} is ${MaxFreq} Hz \n"
fhigh=($(seq 0.05 0.05 ${MaxFreq}))


	for f_high in "${fhigh[@]}"
	do
	   BW=$(awk -v fh=${f_high} -v fl=${f_low}  'BEGIN { print 2*(fh-fl) }')
	   

		if [ ! -f 11BPF_${BW}+tlrc.BRIK ]; then
	
			echo -e "\n Temporal filtering for bandwidth=$BW (flow=0.009 and f_high=${f_high})...\n"
			3dFourier -ignore 0 -lowpass ${f_high} -highpass ${f_low} -prefix 11BPF_${BW} 10TS+tlrc. # Start filtering from 0
			else
			echo -e "\n Aldready done with temporal filtering ...\n"	
		fi

		
		echo -e "\n Beginning connectivity analysis for various resting state networks (After Filtering) ... \n" 
			
				# After Filtering
				echo -e "\n \n Default Mode Network ... \n \n" 
				3dmaskave  -quiet -mask PCCmask+tlrc 11BPF_${BW}+tlrc. > PCC_tsAF_${BW}.1D
				3dfim+ -bucket PCC_AF_${BW} -out Correlation  -ideal_file PCC_tsAF_${BW}.1D  -input 11BPF_${BW}+tlrc.

				# IPS seed
				3dmaskave  -quiet -mask IPSmask+tlrc 11BPF_${BW}+tlrc. > IPS_tsAF_${BW}.1D
				3dfim+ -bucket IPS_AF_${BW} -out Correlation  -ideal_file IPS_tsAF_${BW}.1D  -input 11BPF_${BW}+tlrc.

				# PVC seed
				3dmaskave  -quiet -mask PVCmask+tlrc 11BPF_${BW}+tlrc. > PVC_tsAF_${BW}.1D
				3dfim+ -bucket PVC_AF_${BW} -out Correlation  -ideal_file PVC_tsAF_${BW}.1D  -input 11BPF_${BW}+tlrc.

				# PAC seed
				3dmaskave  -quiet -mask PACmask+tlrc 11BPF_${BW}+tlrc. > PAC_tsAF_${BW}.1D
				3dfim+ -bucket PAC_AF_${BW} -out Correlation  -ideal_file PAC_tsAF_${BW}.1D  -input 11BPF_${BW}+tlrc.

				# PMC seed
				3dmaskave  -quiet -mask PMCmask+tlrc 11BPF_${BW}+tlrc. > PMC_tsAF_${BW}.1D
				3dfim+ -bucket PMC_AF_${BW} -out Correlation  -ideal_file PMC_tsAF_${BW}.1D  -input 11BPF_${BW}+tlrc.

				# Putamen seed
				3dmaskave  -quiet -mask Putamask+tlrc 11BPF_${BW}+tlrc. > Puta_tsAF_${BW}.1D
				3dfim+ -bucket Puta_AF_${BW} -out Correlation  -ideal_file Puta_tsAF_${BW}.1D  -input 11BPF_${BW}+tlrc.

				# IFG seed
				3dmaskave  -quiet -mask IFGmask+tlrc 11BPF_${BW}+tlrc. > IFG_tsAF_${BW}.1D
				3dfim+ -bucket IFG_AF_${BW} -out Correlation  -ideal_file IFG_tsAF_${BW}.1D  -input 11BPF_${BW}+tlrc.
		


	done


# intensity normalization  (usually done in the last stage)

# Intensity normalization to whole brain mode value of 1000: which means, finding modal value across time and space for voxels within the brain, dividing each voxel by this modal value and multiplying by 1000.Mean intensity of the whole dataset changes between subjects and sessions (due to various uninteresting factors (e.g. caffeine levels)). Aim to have the same mean signal level for each subject (taken over all voxels and all timepoints: i.e. 4D).  Scale each 4D dataset by a single value to get the overall 4D mean (dotted line) to be the same
#Normalized intensity = (TrueValue*10000)/global4Dmean.....This is so that higher-level analyses are valid....

# Intensity normalisation forces every FMRI volume to have the same mean intensity. For each volume it calculates the mean intensity and then scales the intensity across the whole volume so that the global mean becomes a preset constant. This step is normally discouraged - hence is turned off by default. When this step is not carried out, the whole 4D data set is still normalised by a single scaling factor ("grand mean scaling") - each volume is scaled by the same amount. This is so that higher-level analyses are valid.


echo -e "\n ================================================= "
echo -e "\n Done with processing TR $k ... \n "
echo -e " =================================================== \n "


cd ..
done

echo -e "\n ================================================= "
echo -e "\n Done with processing subject $sub ... \n "
echo -e " =================================================== \n "


cd ..
done


echo -e "\n ================================================= "
echo -e "\n Beginning voxel-wise correlation process for 7 RSNs  \n "
echo -e " =================================================== \n "


./RSN_DMN.sh       	# Default Mode Network  
./RSN_SMN.sh        	# Sensory Motor network
./RSN_Auditory.sh   	# Auditory Network
./RSN_Visual.sh     	# Visual Network
./RSN_BGN.sh        	# Basal Ganglia Network
./RSN_FN.sh         	# Frontal Network
./RSN_FPN.sh        	# Frontal-parietal network  
./RSN_EXEC.sh       	# Executive Network (Write this function)
./RSN_SALI.sh       	# Saliance Network  (Write this function)

echo -e "\n ================================================= "
echo -e "\n Done with voxel-wise correlation process for 7 RSNs  \n "
echo -e " =================================================== \n "


# Testing with different radius


# Posterior DMN  (PCC seed)
BW=0.182  
echo "-2 -54 26" | 3dUndump -prefix PCCmask3mmC1 -srad 3 -master 10TS+tlrc.  -xyz -   #3mm mask USUAL coordinate
3dmaskave  -quiet -mask PCCmask3mmC1+tlrc 11BPF_${BW}+tlrc. > PCC_tsAF_${BW}_3mmC1.1D
3dfim+ -bucket PCC_AF_${BW}_3mmC1 -out Correlation  -ideal_file PCC_tsAF_${BW}_3mmC1.1D  -input 11BPF_${BW}+tlrc.


echo "-2 -52 26" | 3dUndump -prefix PCCmask3mmC2 -srad 3 -master 10TS+tlrc.  -xyz -   #3mm mask  Literature coordinate
3dmaskave  -quiet -mask PCCmask3mmC2+tlrc 11BPF_${BW}+tlrc. > PCC_tsAF_${BW}_3mmC2.1D
3dfim+ -bucket PCC_AF_${BW}_3mmC2 -out Correlation  -ideal_file PCC_tsAF_${BW}_3mmC2.1D  -input 11BPF_${BW}+tlrc.


# Anterior DMN

# ventro-medial prefrontal cortex (-4,53,-3)
BW=0.182  
echo "-4 53 -3" | 3dUndump -prefix vMPFCmask3mm -srad 3 -master 10TS+tlrc.  -xyz -   #3mm mask USUAL coordinate
3dmaskave  -quiet -mask vMPFCmask3mm+tlrc 11BPF_${BW}+tlrc. > vMPFC_tsAF_${BW}_3mm.1D
3dfim+ -bucket vMPFC_AF_${BW}_3mm -out Correlation  -ideal_file vMPFC_tsAF_${BW}_3mm.1D  -input 11BPF_${BW}+tlrc.


# ventro-medial prefrontal cortex (4,55,-8)
BW=0.182  
echo "4 54 -8" | 3dUndump -prefix vMPFCmask3mm1 -srad 3 -master 10TS+tlrc.  -xyz -   #3mm mask USUAL coordinate
3dmaskave  -quiet -mask vMPFCmask3mm1+tlrc 11BPF_${BW}+tlrc. > vMPFC_tsAF_${BW}_3mm1.1D
3dfim+ -bucket vMPFC_AF_${BW}_3mm1 -out Correlation  -ideal_file vMPFC_tsAF_${BW}_3mm1.1D  -input 11BPF_${BW}+tlrc.

# dorsal-medial PFC 

echo "-11 14 50" | 3dUndump -prefix dMPFCmask3mm -srad 3 -master 10TS+tlrc.  -xyz -   #3mm mask USUAL coordinate
3dmaskave  -quiet -mask dMPFCmask3mm+tlrc 11BPF_${BW}+tlrc. > dMPFC_tsAF_${BW}_3mm.1D
3dfim+ -bucket dMPFC_AF_${BW}_3mm -out Correlation  -ideal_file dMPFC_tsAF_${BW}_3mm.1D  -input 11BPF_${BW}+tlrc.


##### Executive network 

# dlPFC (Dorsal lateral prefrontal cortex) (left dlPFC)
# echo "-24 40 32" | 3dUndump -prefix dlPFCmask -srad 5 -master 10TS+tlrc.  -xyz -   #3mm mask USUAL coordinate
3dmaskave  -quiet -mask dlPFCmask+tlrc 11BPF_${BW}+tlrc. > dlPFC_tsAF_${BW}.1D
3dfim+ -bucket dlPFC_AF_${BW} -out Correlation  -ideal_file dlPFC_tsAF_${BW}.1D  -input 11BPF_${BW}+tlrc.


##### Saliance network  (Amygdala and insular cortex)
R. Amygdala (22, 3,-19)(22 -2 -15)   L. amygdala (-22,3,-19)(-20,-4,-15)  L.insula (-36 -5 15)  R. Insula (33,-6,15)

# R. Amygdala
echo "22 -2 -15" | 3dUndump -prefix AMYrmask -srad 5 -master 10TS+tlrc.  -xyz -   #3mm mask USUAL coordinate
3dmaskave  -quiet -mask AMYrmask+tlrc 11BPF_${BW}+tlrc. > AMYr_tsAF_${BW}.1D
3dfim+ -bucket AMYr_AF_${BW} -out Correlation  -ideal_file AMYr_tsAF_${BW}.1D  -input 11BPF_${BW}+tlrc.

# L. Amygdala
echo "-20 -4 -15" | 3dUndump -prefix AMYlmask -srad 5 -master 10TS+tlrc.  -xyz -   #3mm mask USUAL coordinate
3dmaskave  -quiet -mask AMYlmask+tlrc 11BPF_${BW}+tlrc. > AMYl_tsAF_${BW}.1D
3dfim+ -bucket AMYl_AF_${BW} -out Correlation  -ideal_file AMYl_tsAF_${BW}.1D  -input 11BPF_${BW}+tlrc.


# 3dmaskdump -mask PCCmask+tlrc. -index -o hi1.txt PCCmask+tlrc.  # Gives xyz coordinates around PCC voxels
                                                                  # Totally 19 voxels 


# Mouse 

echo "34 43 2" | 3dUndump -prefix S1 -srad 5 -master trial_concat.nii.gz  -xyz -
 






