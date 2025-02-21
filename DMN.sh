
# MNI Co-oridinates in In LPI orientations

/mnt/NAS/fMRI/Rstate/NKIQpassed/


declare -a ROI=("PCC" "VMPFC" "AMPFC" "LSFG" "RSFG" "LITG" "RITG" "LPHG" "RPHG" "LLPC" "RLPC")

PCC="-2 -54 26"
VMPFC="2 56 0"
AMPFC="1 55 26"
LSFG="-14 36 59 "
RSFG="17 35 58"	 	
LITG="-62 -33 -20"
RITG="66 -17 -19"
LPHG="-22 -26 -21"	
RPHG="25 -26 -18"	 	
LLPC="-47 -71 35"
RLPC="54 -61 36"

r=5    # Choose the radius levelin mm

# A=(PCC,VMPFC,AMPFC,LSFG,RSFG,LITG,RITG,LPHG,RPHG,LLPC,RLPC)

for n in "${ROI[@]}"              #tLen=${#TR[@]}  ---To get the length of the array
 do

		echo ${!n} | 3dUndump -prefix ${n}mask -srad $r -master 10TS+tlrc.  -xyz -
		3dmaskave  -quiet -mask ${n}mask+tlrc. 10TS+tlrc. > ${n}_tsBF.1D
		3dfim+ -bucket ${n}_BF -out Correlation  -ideal_file ${n}_tsBF.1D  -input 10TS+tlrc.

done


# This function to extract the voxel time series from DMN areas


#SEED
		# Before Filtering
		#echo $PCC | 3dUndump -prefix PCC_maskBF -srad $r -master 10TS+tlrc.  -xyz -
		#3dmaskave  -quiet -mask PCC_maskBF+tlrc. 10TS+tlrc. > PCC_BF.1D
	
		# After Filtering
		#echo $PCC | 3dUndump -prefix PCC_maskAF -srad $r -master 11BPF_1+tlrc.  -xyz -
		#3dmaskave  -quiet -mask PCC_maskAF+tlrc. 11BPF_1+tlrc. > PCC_AF.1D
				
## VMPFC
		# Before Filtering
		echo $VMPFC | 3dUndump -prefix VMPFC_maskBF -srad $r -master 10TS+tlrc.  -xyz -
		3dmaskave  -quiet -mask VMPFC_maskBF+tlrc. 10TS+tlrc. > VMPFC_BF.1D

		
		# After Filtering
		#echo $VMPFC | 3dUndump -prefix VMPFC_maskAF -srad $r -master 11BPF_1+tlrc.  -xyz -
		#3dmaskave  -quiet -mask VMPFC_maskAF+tlrc. 11BPF_1+tlrc. > VMPFC_AF.1D

# AMPFC
		echo $AMPFC | 3dUndump -prefix AMPFC_maskBF -srad $r -master 10TS+tlrc.  -xyz -
		3dmaskave  -quiet -mask AMPFC_maskBF+tlrc. 10TS+tlrc. > AMPFC_BF.1D
	
		# After Filtering
		#echo $AMPFC | 3dUndump -prefix AMPFC_maskAF -srad $r -master 11BPF_1+tlrc.  -xyz -
		#3dmaskave  -quiet -mask AMPFC_maskAF+tlrc. 11BPF_1+tlrc. > AMPFC_AF.1D

# LSFG
		echo $LSFG | 3dUndump -prefix LSFG_maskBF -srad $r -master 10TS+tlrc.  -xyz -
		3dmaskave  -quiet -mask LSFG_maskBF+tlrc. 10TS+tlrc. > LSFG_BF.1D
	
		# After Filtering
		#echo $LSFG | 3dUndump -prefix LSFG_maskAF -srad $r -master 11BPF_1+tlrc.  -xyz -
		#3dmaskave  -quiet -mask LSFG_maskAF+tlrc. 11BPF_1+tlrc. > LSFG_AF.1D

# RSFG
		echo $RSFG | 3dUndump -prefix RSFG_maskBF -srad $r -master 10TS+tlrc.  -xyz -
		3dmaskave  -quiet -mask RSFG_maskBF+tlrc. 10TS+tlrc. > RSFG_BF.1D
	
		# After Filtering
		#echo $RSFG | 3dUndump -prefix RSFG_maskAF -srad $r -master 11BPF_1+tlrc.  -xyz -
		#3dmaskave  -quiet -mask RSFG_maskAF+tlrc. 11BPF_1+tlrc. > RSFG_AF.1D

# LITG
		echo $LITG | 3dUndump -prefix LITG_maskBF -srad $r -master 10TS+tlrc.  -xyz -
		3dmaskave  -quiet -mask LITG_maskBF+tlrc. 10TS+tlrc. > LITG_BF.1D
	
		# After Filtering
		echo $LITG | 3dUndump -prefix LITG_maskAF -srad $r -master 11BPF_1+tlrc.  -xyz -
		3dmaskave  -quiet -mask LITG_maskAF+tlrc. 11BPF_1+tlrc. > LITG_AF.1D

# RITG
		echo $RITG | 3dUndump -prefix RITG_maskBF -srad $r -master 10TS+tlrc.  -xyz -
		3dmaskave  -quiet -mask RITG_maskBF+tlrc. 10TS+tlrc. > RITG_BF.1D
	
		# After Filtering
		echo $RITG | 3dUndump -prefix RITG_maskAF -srad $r -master 11BPF_1+tlrc.  -xyz -
		3dmaskave  -quiet -mask RITG_maskAF+tlrc. 11BPF_1+tlrc. > RITG_AF.1D


# LPHG
		echo $LPHG | 3dUndump -prefix LPHG_maskBF -srad $r -master 10TS+tlrc.  -xyz -
		3dmaskave  -quiet -mask LPHG_maskBF+tlrc. 10TS+tlrc. > LPHG_BF.1D
	
		# After Filtering
		echo $LPHG | 3dUndump -prefix LPHG_maskAF -srad $r -master 11BPF_1+tlrc.  -xyz -
		3dmaskave  -quiet -mask LPHG_maskAF+tlrc. 11BPF_1+tlrc. > LPHG_AF.1D

# RPHG
		echo $RPHG | 3dUndump -prefix RPHG_maskBF -srad $r -master 10TS+tlrc.  -xyz -
		3dmaskave  -quiet -mask RPHG_maskBF+tlrc. 10TS+tlrc. > RPHG_BF.1D
	
		# After Filtering
		echo $RPHG | 3dUndump -prefix RPHG_maskAF -srad $r -master 11BPF_1+tlrc.  -xyz -
		3dmaskave  -quiet -mask RPHG_maskAF+tlrc. 11BPF_1+tlrc. > RPHG_AF.1D

# LLPC
		echo $LLPC | 3dUndump -prefix LLPC_maskBF -srad $r -master 10TS+tlrc.  -xyz -
		3dmaskave  -quiet -mask LLPC_maskBF+tlrc. 10TS+tlrc. > LLPC_BF.1D
	
		# After Filtering
		echo $LLPC | 3dUndump -prefix LLPC_maskAF -srad $r -master 11BPF_1+tlrc.  -xyz -
		3dmaskave  -quiet -mask LLPC_maskAF+tlrc. 11BPF_1+tlrc. > LLPC_AF.1D

# RLPC
		echo $RLPC | 3dUndump -prefix RLPC_maskBF -srad $r -master 10TS+tlrc.  -xyz -
		3dmaskave  -quiet -mask RLPC_maskBF+tlrc. 10TS+tlrc. > RLPC_BF.1D
	
		# After Filtering
		echo $RLPC | 3dUndump -prefix RLPC_maskAF -srad $r -master 11BPF_1+tlrc.  -xyz -
		3dmaskave  -quiet -mask RLPC_maskAF+tlrc. 11BPF_1+tlrc. > RLPC_AF.1D


		
