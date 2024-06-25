#!bin/sh

#uses mrtrix and fsl commands at the command line or wrapped in a loop/script
#replace commands below with your ${subject} ID and preferred organization

#generate fixels from single image
fod2fixel ${subject}_wmfod.mif fixel_output -mask ${subject}_mask_in_template.nii.gz -peak peaks.mif -dirpeak -afd afd.mif -disp 
disp.mif

fixel2voxel fixel_output/${subject}_afd.mif sum fixel_output/${subject}_afd_sum.nii.gz

#as per stikov et al 2015, by Mohammadi & Callaghan 2021 sqrt of 1 - mvf/avf+mvf

fslmaths T1T2_maps/${subject}_T1T2_map_in_template.nii.gz -add fixel_output/${subject}_afd_sum.nii.gz ${subject}_MVF_FVF.nii.gz
fslmaths T1T2_maps/${subject}_T1T2_map_in_template.nii.gz -div ${subject}_MVF_FVF.nii.gz ${subject}_MVF_div_FVF.nii.gz

fslmaths ${subject}_MVF_div_FVF.nii.gz -mul 0 -add 1 ${subject}_1.nii.gz #this is just an easy way to make a voxel-wise map where each voxel has a value of 1 but the grid matches your image

fslmaths ${subject}_1.nii.gz -sub ${subject}_MVF_div_FVF.nii.gz ${subject}_1_sub_MVFAVF.nii.gz
rm ${subject}_1.nii.gz

fslmaths ${subject}_1_sub_MVFAVF.nii.gz -sqrt gratio/${subject}_gratio.nii.gz

#This cleans up any voxels (typically around the outside of the brain or on the periphery that are not in the brain/have physiologically impossible values from subtracting each voxel from 1 above, you can just remask if you prefer or alter the value
fslmaths gratio/${subject}_gratio.nii.gz -uthr 0.95 gratio/${subject}_gratio_masked.nii.gz

#calculate conduction velocity from gratio according AVF*sqrt(-ln(gratio)) Ruston via Berman, Filo & Mezer Modeling conduction delays in the corups callosum using MRI-measured g-ratio
fslmaths gratio/${subject}_gratio_masked.nii.gz -log -mul -1 -sqrt -mul fixel_output/${subject}_afd_sum.nii.gz 
conduction_velocity/${subject}_conduction_velocity.nii.gz
