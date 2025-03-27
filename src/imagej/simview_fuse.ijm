//Simplified fusion menu options specific to the SiMView
// Start by getting the appropriate XML file
Dialog.create("Fusion Parameters");
Dialog.addFile("XML file to process","");
Dialog.show();
dataset_file = Dialog.getString();

// Get the number of time points
dirIm = File.getDirectory(dataset_file);
list = getFileList(dirIm);
maxT = 0;
for (i=0; i<list.length; ++i){  
	if (list[i].startsWith("TM")){
		tempT = substring(list[i],2,7);
		tempT = parseFloat(tempT);
		if (tempT>maxT){
			maxT = tempT;
		}
	}
}

// Set up the output directory
output_dir = File.getDirectory(dataset_file);
output_dir = output_dir + "fused";

Dialog.create("Fusion Parameters");
//Dialog.addFile("XML file to process","");
Dialog.addNumber("First frame to fuse", 0);
Dialog.addNumber("Last frame to fuse", maxT);
Dialog.addCheckbox("Fuse to BDV hdf5",true);
Dialog.addCheckbox("Fuse to BDV n5",false);
Dialog.addCheckbox("Fuse to individual tif files",false);
Dialog.addNumber("Downsample",1);
Dialog.addString("Bounding Box", "All Views");
Dialog.addDirectory("Folder to save fusion",output_dir);
Dialog.addMessage("For hdf5 or n5:")
Dialog.addString("Subsampling factors","{1,1,1}, {2,2,1}, {4,4,1}, {8,8,2}, {16,16,4}",30)
Dialog.show();
//dataset_file = Dialog.getString();
frameStart = Dialog.getNumber();
frameEnd = Dialog.getNumber();
Choose_hdf5 = Dialog.getCheckbox();
Choose_n5 = Dialog.getCheckbox();
Choose_tif = Dialog.getCheckbox();
box = Dialog.getString();
downsamp = Dialog.getNumber();
output_dir = Dialog.getString();
subsamp = Dialog.getString();

if (!File.exists(output_dir)){
	File.makeDirectory(output_dir);
	print("Making directory " + output_dir);
}

if (Choose_hdf5){

	run("Image Fusion", "select=[file:/" + dataset_file + "] process_angle=[All angles] process_channel=[All channels] process_illumination=[All illuminations] process_tile=[All tiles] process_timepoint=[Range of Timepoints (Specify by Name)] process_following_timepoints=" + frameStart + "-" + frameEnd + " bounding_box=[" + box + "] downsampling=" + downsamp + " interpolation=[Linear Interpolation] fusion_type=[Avg, Blending] pixel_type=[16-bit unsigned integer] interest_points_for_non_rigid=[-= Disable Non-Rigid =-] preserve_original produce=[Each timepoint & channel] fused_image=[OME-ZARR/N5/HDF5 export using N5-API] define_input=[Auto-load from input data (values shown below)] export=HDF5 compression=Zstandard create create_0 hdf5_file=[file:/" + output_dir + "fused.h5] xml_output_file=[file:/" + output_dir + "fused.xml] viewid_timepointid=0 viewid_setupid=0 subsampling_factors=[{ "+ subsamp +" }]");

    print("DONE\nWrote h5 and xml files to " + output_dir + "\n");

}

if (Choose_n5){

	run("Image Fusion", "select=[file:/" + dataset_file + "] process_angle=[All angles] process_channel=[All channels] process_illumination=[All illuminations] process_tile=[All tiles] process_timepoint=[Range of Timepoints (Specify by Name)] process_following_timepoints=" + frameStart + "-" + frameEnd + " bounding_box=[" + box + "] downsampling=" + downsamp + " interpolation=[Linear Interpolation] fusion_type=[Avg, Blending] pixel_type=[16-bit unsigned integer] interest_points_for_non_rigid=[-= Disable Non-Rigid =-] preserve_original produce=[Each timepoint & channel] fused_image=[OME-ZARR/N5/HDF5 export using N5-API] define_input=[Auto-load from input data (values shown below)] export=N5 compression=Zstandard create create_0 n5_dataset_path=[file:/" + output_dir + "fused.n5]  xml_output_file=[file:/" + output_dir + "fused.xml] subsampling_factors=[{ "+ subsamp +" }]");

    print("DONE\nWrote n5 folder and xml file to " + output_dir + "\n");

}

if (Choose_tif){

	run("Image Fusion", "select=[file:/" + dataset_file + "] process_angle=[All angles] process_channel=[All channels] process_illumination=[All illuminations] process_tile=[All tiles] process_timepoint=[Range of Timepoints (Specify by Name)] process_following_timepoints=" + frameStart + "-" + frameEnd + " bounding_box=[" + box + "] downsampling=" + downsamp + " interpolation=[Linear Interpolation] fusion_type=[Avg, Blending] pixel_type=[16-bit unsigned integer] interest_points_for_non_rigid=[-= Disable Non-Rigid =-] preserve_original produce=[Each timepoint & channel] fused_image=[Save as (compressed) TIFF stacks] define_input=[Auto-load from input data (values shown below)] output_file_directory=[" + output_dir + "] filename_addition=[]");

	print("DONE\nWrote tif files to " + output_dir + "\n");

}