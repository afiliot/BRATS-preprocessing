#!/bin/bash


function Help {
    cat <<HELP

Usage:
bratsPreprocessing.sh -p PathToData -b BratsData -n NumberOfPatients -t TargetShape -f SkullThreshold -r RegistrationMethod -c Threads -v Verbose -o OutputSuffix -s CastImageType

Example Case:
bratsPreprocessing.sh -p /home/afiliot/LowDoseProject/ -b 1 -n -1 -t 240x240x155 -f 0.5 -r sr -c 4 -v 1 -o _final.nii.gz -s 0

Compulsory arguments:
     -p: path to the Brats data set. Data must be organized as the original data set (at least for patient -> patient_flair, patient_t1, patient_t1ce, patient_t2, patient_seg, HGG and LGG are optional)
         +----HGG
	 |	/----Brats18_2013_2_1
 	 |		/----Brats18_2013_2_1_flair.nii.gz
         |              /----Brats18_2013_2_1_t1.nii.gz
         |              /----Brats18_2013_2_1_t1ce.nii.gz
         |              /----Brats18_2013_2_1_t2.nii.gz
         |              /----Brats18_2013_0_1_seg.nii.gz
...
...
...
         +----LGG
         |      /----Brats18_2013_0_1
         |              /----Brats18_2013_0_1_flair.nii.gz
         |              /----Brats18_2013_0_1_t1.nii.gz
         |              /----Brats18_2013_0_1_t1ce.nii.gz
         |              /----Brats18_2013_0_1_t2.nii.gz
         |              /----Brats18_2013_0_1_seg.nii.gz

Optional arguments: 
    -h: get help.
    -m: additional information about the code.
    -b: if data is Brats data set (default=1).
    -n: number of patients (default=-1). Number of patients to process. Default correspond to all patients.
    -t: 3D shape of output images of type string: 'hxwxd' where h=height, w=width, d=depth (default=240x240x155).
    -f: fractional intensity threshold (0->1); smaller values give larger brain outline estimates (default=0.5).
    -r: transform type for registration method (default='s')
        t: translation (1 stage)
        r: rigid (1 stage)
        a: rigid + affine (2 stages)
        s: rigid + affine + deformable syn (3 stages)
        sr: rigid + deformable syn (2 stages)
        so: deformable syn only (1 stage)
        b: rigid + affine + deformable b-spline syn (3 stages)
        br: rigid + deformable b-spline syn (2 stages)
        bo: deformable b-spline syn only (1 stage)
    -c: number of threads (default=4).
    -v: Verbose, 0, 1 or 2 (default=0).
    -g: 1 if the segmentation is available, 0 otherwise (default=1).
    -o: end of output file name (default='_prep.nii.gz').
    -s: cast output image to a specific type (float64, uint8, etc...). s is an int >= -1. If s=-1, then no casting is done, if s>=0 then the output pixel type is equal to s (default=3). Default correspond to uin16. Here are the types:
	0: 8-bit signed integer
	1: 8-bit unsigned integer
	2: 16-bit signed integer
	3: 16-bit unsigned integer (default)
	4: 32-bit signed integer
	5: 32-bit unsigned integer
	6: 64-bit signed integer
	7: 64-bit unsigned integer
	8: 32-bit float
	9: 64-bit float
	10: complex of 32-bit float
	11: complex of 64-bit float
	12: vector of 8-bit signed integer
	13: vector of 8-bit unsigned integer
	14: vector of 16-bit signed integer
	15: vector of 16-bit unsigned integer
	16: vector of 32-bit signed integer
	17: vector of 32-bit unsigned integer
	18: vector of 64-bit signed integer
	19: vector of 64-bit unsigned integer
	20: vector of 32-bit float
	21: vector of 64-bit float
	22: label of 8-bit unsigned integer
	23: label of 16-bit unsigned integer
	24: label of 32-bit unsigned integer
	25: label of 64-bit unsigned integer
--------------------------------------------------------------------------------------
script by Alexandre Filiot, Guerbet. Not to be shared outside of Guerbet Group / IBM
--------------------------------------------------------------------------------------
HELP
    exit 1
}

function ReadMe {
    cat <<README
--------------------------------------------------------------------------------------
Prerequisites:

1) Install ANTS on your Linux subsytem: https://github.com/ANTsX/ANTs/wiki/Compiling-ANTs-on-Linux-and-Mac-OS
2) You need to copy the Scripts into the /opt/ants/bin folder (see https://github.com/ANTsX/ANTs/wiki/Compiling-ANTs-on-Linux-and-Mac-OS#set-path-and-antspath)

3) Install FSL (see https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation/Linux):
	3.1) You need to download fslinstaller.py file (try https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py)
	3.2) Create a 2.7 Python conda environment.
	3.3) Some modifications have to be done on the file to run properly. The modified file is avaible at /mnt/weazsabrain/BratsPREP/fslinstaller.py. Modifications are: 
		+--- print '' replaced by print()
	        +---         if 'buster/sid' in v_vals:
				v_vals = ['18', '04']
        		     if 'stretch/sid' in v_vals:
            			v_vals = ['16', '04']
		+--- 'Exception, e' replaced by 'Exception as e'
	3.4) In command line: python fslinstaller.py
	3.5) Export to path (remove space between $ and {):
		>BRATSPREP=/mnt/weazrsabrain/BratsPREP/
		>PATH=$ {BRATSPREP}/:$ {PATH}
		>export BRATSPREP PATH

4) Run on command line: sudo apt-get install dc

5) Execute the command: mv /path/to/antsRegistrationSyN.sh /mnt/weazsabrain/BratsPREP/antsRegistrationSyN.sh
   to replace the build-in script antsRegistrationSyN.sh by one I modified and put in BratsPREP folder.
Before running this script:

1) Make sure the data folders have the same architecture than that of Brats data set (directly after download). You may refer to the basename with the parameter PathToData.
2) Make sure that you have mounted weazsabrain on your device, can access BratsPREP folder and see bratsPreprocessing.sh and adjust_res.py files.
3) Processed data will be stored directly in the original patient folders. Make sure you have enough memory available.
--------------------------------------------------------------------------------------
About the code:

There are several ways to speed up the preprocessing:
1) Put only 1 stage in BiasFieldReduction (-s 1)
2) Remove -R ans -S options in Skull stripping.
3) Set the registration method to 'r' (strongly recommended).
--------------------------------------------------------------------------------------
script by Alexandre Filiot, Guerbet. Not to be shared outside of Guerbet Group / IBM
--------------------------------------------------------------------------------------
README
    exit 1
}

BratsData=1
NumberOfPatients=-1
TargetShape='240x240x155'
SkullThreshold=0.5
SegmentationIsAvailable=1
RegistrationMethod='s'
Threads=4
Verbose=0
OutputSuffix='_prep.nii.gz'
CastImageType=-1
count=0

while getopts 'hmp:b:n:t:f:r:c:v:o:s:g:' flag; do
  case "${flag}" in
    h) Help ;;
    p) PathToData="${OPTARG}" ;;
    b) BratsData=${OPTARG} ;;
    n) NumberOfPatients=${OPTARG} ;;
    t) TargetShape=${OPTARG} ;;
    f) SkullThreshold=${OPTARG} ;;
    r) RegistrationMethod="${OPTARG}" ;;
    c) Threads=${OPTARG} ;;
    v) Verbose=${OPTARG} ;;
    g) SegmentationIsAvailable=${OPTARG} ;;
    o) OutputSuffix="${OPTARG}";;
    s) CastImageType=${OPTARG};;
    m) ReadMe ;;
  esac
done


cd $PathToData

if [ $BratsData == 1 ]
then
	patients=( $(ls -d {HGG,LGG}/Brats*) )
else
	patients=( $(ls -d */) )
fi

if [ $NumberOfPatients -ne -1 ] 
then
	patients=( ${patients[@]:0:$NumberOfPatients} )
fi

NumberOfPatients=${#patients[*]}

rm -rf patients.txt
echo ${patients[*]} > patients.txt
#rm -rf mycommand.txt

for i in $(cat patients.txt);do

pat_prefix=$(basename ${i})
t1=${i}/${pat_prefix}_t1.nii.gz
t1ce=${i}/${pat_prefix}_t1ce.nii.gz
t2=${i}/${pat_prefix}_t2.nii.gz
flair=${i}/${pat_prefix}_flair.nii.gz
seg=${i}/${pat_prefix}_seg.nii.gz	


start_b=$(date +%s.%N)
# First bias correction

if [ ${Verbose} -ge 1 ]
then
	start=$(date +%s.%N)
	echo "Bias correction..."
fi

if [ ${Verbose} -eq 2 ]
then
	VerboseTemp=1
else
	VerboseTemp=0
fi

N4BiasFieldCorrection -d 3 -i ${t1} -s 2 -v ${VerboseTemp} -o ${i}/${pat_prefix}_t1_bc.nii.gz
N4BiasFieldCorrection -d 3 -i ${t1ce} -s 2 -v ${VerboseTemp} -o ${i}/${pat_prefix}_t1ce_bc.nii.gz
N4BiasFieldCorrection -d 3 -i ${t2} -s 2 -v ${VerboseTemp} -o ${i}/${pat_prefix}_t2_bc.nii.gz
N4BiasFieldCorrection -d 3 -i ${flair} -s 2 -v ${VerboseTemp} -o ${i}/${pat_prefix}_flair_bc.nii.gz

if [ ${Verbose} -ge 1 ]
then
	dur=$(echo "$(date +%s.%N) - $start" | bc)
	echo "Done (${dur} secs)."
fi

# Skull stripping

if [ ${Verbose} -ge 1 ]
then
	start=$(date +%s.%N)
	echo "Skull stripping..."
fi

if [ ${Verbose} -eq 2 ]
then
	# you can add -R -S for more robustness (-R) and eye, optic nerve cleaning (-S)
	bet ${i}/${pat_prefix}_t1_bc.nii.gz ${i}/${pat_prefix}_t1_skstp.nii.gz -f $SkullThreshold -R -v
	bet ${i}/${pat_prefix}_t1ce_bc.nii.gz ${i}/${pat_prefix}_t1ce_skstp.nii.gz -f $SkullThreshold -R -v
	bet ${i}/${pat_prefix}_t2_bc.nii.gz ${i}/${pat_prefix}_t2_skstp.nii.gz -f $SkullThreshold -R -v
	bet ${i}/${pat_prefix}_flair_bc.nii.gz ${i}/${pat_prefix}_flair_skstp.nii.gz -f $SkullThreshold -R -v
	

else
        bet ${i}/${pat_prefix}_t1_bc.nii.gz ${i}/${pat_prefix}_t1_skstp.nii.gz -f $SkullThreshold
        bet ${i}/${pat_prefix}_t1ce_bc.nii.gz ${i}/${pat_prefix}_t1ce_skstp.nii.gz -f $SkullThreshold
        bet ${i}/${pat_prefix}_t2_bc.nii.gz ${i}/${pat_prefix}_t2_skstp.nii.gz -f $SkullThreshold
        bet ${i}/${pat_prefix}_flair_bc.nii.gz ${i}/${pat_prefix}_flair_skstp.nii.gz -f $SkullThreshold
fi

if [ ${Verbose} -ge 1 ]
then
	dur=$(echo "$(date +%s.%N) - $start" | bc)
	echo "Done (${dur} secs)."
fi

# Rename variables

t1=${i}/${pat_prefix}_t1_skstp.nii.gz
t1ce=${i}/${pat_prefix}_t1ce_skstp.nii.gz
t2=${i}/${pat_prefix}_t2_skstp.nii.gz
flair=${i}/${pat_prefix}_flair_skstp.nii.gz


# Then registration (T1ce is taken as the reference in BRATS preprocessing).

if [ ${Verbose} -ge 1 ]
then
	start=$(date +%s.%N)
	echo "Co-registration..."
fi


# T1 to T1CE
antsRegistrationSyN.sh -v ${VerboseTemp} -d 3 -m ${t1} -f ${t1ce} -t $RegistrationMethod -n $Threads -o "${i}/${pat_prefix}_t1_to_t1ce_" 
antsApplyTransforms -v ${VerboseTemp} -d 3 -i ${t1} -r ${t1ce} -o ${i}/${pat_prefix}_t1_corg.nii.gz -n Linear -t "${i}/${pat_prefix}_t1_to_t1ce_0GenericAffine.mat"  


# FLAIR to T1CE
antsRegistrationSyN.sh -v ${VerboseTemp} -d 3 -m ${flair} -f ${t1ce} -t $RegistrationMethod -n $Threads -o "${i}/${pat_prefix}_flair_to_t1ce_"
antsApplyTransforms -v ${VerboseTemp} -d 3 -i ${flair} -r ${t1ce} -o ${i}/${pat_prefix}_flair_corg.nii.gz -n Linear -t "${i}/${pat_prefix}_flair_to_t1ce_0GenericAffine.mat"


# T2 to T1CE
antsRegistrationSyN.sh -v ${VerboseTemp} -d 3 -m ${t2} -f ${t1ce} -t $RegistrationMethod -n $Threads -o "${i}/${pat_prefix}_t2_to_t1ce_"
antsApplyTransforms -v ${VerboseTemp} -d 3 -i ${t2} -r ${t1ce} -o ${i}/${pat_prefix}_t2_corg.nii.gz -n Linear -t "${i}/${pat_prefix}_t2_to_t1ce_0GenericAffine.mat" 


if [ ${SegmentationIsAvailable} -eq 1 ]
then
	# SEG to T1CE
	antsRegistrationSyN.sh -v ${VerboseTemp} -d 3 -m ${seg} -f ${t1ce} -t $RegistrationMethod -n $Threads -o "${i}/${pat_prefix}_seg_to_t1ce_"
	antsApplyTransforms -v ${VerboseTemp} -d 3 -i ${seg} -r ${flair} -o ${i}/${pat_prefix}_seg_corg.nii.gz -n NearestNeighbor -t "${i}/${pat_prefix}_seg_to_t1ce_0GenericAffine.mat" 
fi

if [ ${Verbose} -ge 1 ]
then
	dur=$(echo "$(date +%s.%N) - $start" | bc)
	echo "Done (${dur} secs)."
fi

# Resampling 

if [ ${Verbose} -ge 1 ]
then
	start=$(date +%s.%N)
	echo "Adjust resolution..."
fi

python /mnt/weazrsabrain/BratsPREP/adjust_res.py -p $PathToData -i ${t1ce} -o "${i}/${pat_prefix}_t1ce${OutputSuffix}" -t $TargetShape -c $CastImageType
python /mnt/weazrsabrain/BratsPREP/adjust_res.py -p $PathToData -i ${i}/${pat_prefix}_t1_corg.nii.gz -o "${i}/${pat_prefix}_t1${OutputSuffix}" -t $TargetShape -c $CastImageType
python /mnt/weazrsabrain/BratsPREP/adjust_res.py -p $PathToData -i ${i}/${pat_prefix}_flair_corg.nii.gz -o "${i}/${pat_prefix}_flair${OutputSuffix}" -t $TargetShape -c $CastImageType
python /mnt/weazrsabrain/BratsPREP/adjust_res.py -p $PathToData -i ${i}/${pat_prefix}_t2_corg.nii.gz -o "${i}/${pat_prefix}_t2${OutputSuffix}" -t $TargetShape -c $CastImageType

if [ ${SegmentationIsAvailable} -eq 1 ]
then	
	python /mnt/weazrsabrain/BratsPREP/adjust_res.py -p $PathToData -i ${i}/${pat_prefix}_seg_corg.nii.gz -o "${i}/${pat_prefix}_seg${OutputSuffix}" -t $TargetShape -c $CastImageType
fi

if [ ${Verbose} -ge 1 ]
then
	dur=$(echo "$(date +%s.%N) - $start" | bc)
	echo "Done (${dur} secs)."
fi

count=$((count + 1))
dur_b=$(echo "$(date +%s.%N) - $start_b" | bc)
echo "
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
PATIENT ${count}/${NumberOfPatients} DONE (${dur_b} SECS).
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
"
done;
