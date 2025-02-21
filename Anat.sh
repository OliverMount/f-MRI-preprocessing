#  Anatomical processing AFNI way (Rewritten on Jan 2018)
# Copyright Oliver
# This program for running the data in personal computer
# The pain of parting is nothing to the joy of meeting again!
# Remember -- Everything popular is wrong!

cd /mnt/NAS/fMRI/Rstate/NKIQpassed/      # Subjects directory

echo -e "\n Beginning the Anatomical processing ...\n"

# Specify the MNI template here
Template=/mnt/NAS/fMRI/templates/MNI152_T1_3mm_brain.nii.gz  # MNI template


MincPATH='/opt/minc'                                         # For BEaST algorithm 
source $MincPATH/1.9.15/minc-toolkit-config.sh
MincLibPATH="$MincPATH/share/beast-library-1.1"
MNItemplatePATH='/mnt/NAS/fMRI/Rstate/mni_icbm152_nlin_sym_09c_minc2'

subs=0106459
#subs=`ls -d *`

for sub in $subs
do

echo -e "\n ================================================= "
echo -e "\n Processing Subject $sub ... \n "
echo -e " =================================================== \n "


cd $sub

if [ ! -d Anat ]; then
	echo -e "\n Making directory Anat for storing results... \n"
	mkdir Anat
	else  
	echo -e "\n Directory Anat already exits... \n"
fi

cd Anat


# Copying of original anatomical volumes
if [ ! -f 1T1+orig.BRIK ]; then
	echo -e "\n Copying original volume... \n"
	3dcopy ../Anat+orig.   1T1
else  
	echo -e "\n Volume already exits... \n"
fi

if [ ! -f 1AnatPara.1D ]; then
	echo -e "\n Getting file info ...\n "
	3dinfo -nk -is_oblique 1T1+orig.  > 1AnatPara.1D
	NS=`awk '{print $1}'  1AnatPara.1D`   # Number of slices within each volume
	Ob=`awk '{print $2}'  1AnatPara.1D`   # Oblicity of the data
else
	echo -e "\n File info. already obtained... \n"
fi

# Deobliquing data
if [ ! -f 2DeOblique+orig.BRIK ]; then
	if [ $Ob ] ;then 
		echo -e "\n Data is oblique ... Deobliquing ... \n"
		3dWarp -deoblique -prefix 2DeOblique 1T1+orig   				
		filename=2DeOblique+orig.
	else
		echo -e "\n Data is at plumb ... Skipping oblique correction ... \n"
		filename=1T1+orig.
	fi
fi

# Reorienting to RPI

if [ ! -f 2ReOrient+orig.BRIK ]; then
	echo -e " \n Reorienting the data to RPI ... \n"
	3dresample -orient RPI -prefix 2ReOrient -inset  ${filename}
else
	echo -e "\n Already reoriented... \n"
fi

# Bias-field correction

if [ ! -f 3Bias+orig.BRIK ]; then
	echo -e "\n Correcting the bias field ... \n"
	3dUniformize -quiet -anat 2ReOrient+orig. -prefix 3Bias  
else
	echo -e "\n Bias correction already done... \n"
fi


# Skull stripping using BEaST

if [ ! -f 3SSbeastFinal+orig.BRIK ]; then
	echo -e "\n Beginning BEaST skull stripping...This will take time... \n"
       

	# AFNI to MINC file formating
	3dAFNItoMINC  -prefix 2Re 3Bias+orig.   # Bias field corrected is given as input

	# Normalize the input
	beast_normalize 2Re.mnc 2Re_mni.mnc anat2mni.xfm -modeldir $MNItemplatePATH

	# beast skull stripping
	mincbeast -fill -median -conf $MincLibPATH/default.1mm.conf $MincLibPATH 2Re_mni.mnc 2Remask_mni.mnc

	# Transform brain mask to it's original space
	mincresample -invert_transformation -like 2Re.mnc -transformation anat2mni.xfm 2Remask_mni.mnc 3SSbeast.mnc

	# Convert image back to AFNI from MNIC.
	mnc2nii 3SSbeast.mnc   # if there is a single command it would be better mnc to AFNI I mean
	3dcopy 3SSbeast.nii 3SSbeast
	3dresample -orient RPI -inset 3SSbeast+orig -prefix 3SSbeastmask

	# Generate and output brain image and brain mask
	3dcalc -a 3SSbeastmask+orig -b 2ReOrient+orig -expr "a*b" -prefix 3SSbeastFinal
	echo -e "\n Done with  BEaST skull stripping \n"
else
	echo -e "\n BEaST Skull stripping already done... \n"
fi


# Reorienting to LPI for better connectivity viewing and seed regions in MNI templates

if [ ! -f 3SSFinal+orig.BRIK ]; then
	echo -e " \n Reorienting Template and the data to RPI ... \n"
	3dresample -orient LPI -prefix MNITemp.nii.gz -inset $Template 
	3dresample -orient LPI -prefix 3SSFinal -inset  3SSbeastFinal+orig
else
	echo -e "\n Already reoriented... \n"
fi


# Non-linear registration to an MNI template
if [ ! -f 4RegBeast+tlrc.BRIK ]; then
	echo -e "\n Registering the anatomical volume to MNI... \n"
         # Registration Data (Anat,Func)  to template (this program outputs the *.1D transformation matrix in a single line)
else
	echo -e "\n Registration already done... \n"
fi

# Segmentation of tissue types	
if [ ! -d SegBeast ]; then
       echo -e "\n Segmentation of brain tissues (Segmented data are stored in the folder SegBeast) \n"
       3dSeg  -anat 4RegBeast+tlrc  -mask AUTO  -classes 'CSF ; GM ; WM' -bias_classes 'GM ; WM'  -bias_fwhm 25 -mixfrac UNI -main_N 5  -blur_meth BFT -prefix SegBeast
       #3dSeg  -anat 4RegBeast+tlrc -mask AUTO  -classes 'CSF ; GM ; WM' -bias_classes 'GM ; WM' -mixfrac UNI -main_N 5 -prefix SegBeast
else
	echo -e "\n Segmentation already done.. \n"
fi
        
# Creating tissue MASKs
if [ ! -f CSFmaskB+tlrc.BRIK ]; then
	echo -e "\n Creating tissue (CSF, GM, WM)  masks...\n"
	3dcalc -a SegBeast/Classes+tlrc. -expr 'equals(a,1)' -prefix CSFmaskB   # B for Beast
else
	echo -e "\n CSF mask already obtained... \n"
fi

if [ ! -f GMmaskB+tlrc.BRIK ]; then
	3dcalc -a SegBeast/Classes+tlrc. -expr 'equals(a,2)' -prefix GMmaskB
else
	echo -e "\n GM mask already obtained... \n"

fi

if [ ! -f WMmaskB+tlrc.BRIK ]; then
	3dcalc -a SegBeast/Classes+tlrc. -expr 'equals(a,3)' -prefix WMmaskB

	# Finding the edge-masks  (After registration)  # this is used in GLM
	3dcalc -a CSFmaskB+tlrc -b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'a*(1-amongst(0,b,c,d,e,f,g))' -prefix CSFEdgemask 
	3dcalc -a GMmaskB+tlrc -b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'a*(1-amongst(0,b,c,d,e,f,g))' -prefix GMEdgemask
	3dcalc -a WMmaskB+tlrc -b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'a*(1-amongst(0,b,c,d,e,f,g))' -prefix WMEdgemask

else
	echo -e "\n WM mask and eroded (CSF,GM, WM) masks already obtained... \n"

fi


echo -e "\n ================================================= "
echo -e "\n Done Anatomical processing of subject $sub ... \n "
echo -e " =================================================== \n "


cd ..
cd ..
done




# End of anatomical processing
# Functional processsing

#cd /mnt/NAS/fMRI/Preprocessing/
#./FuncNKL.sh








	


