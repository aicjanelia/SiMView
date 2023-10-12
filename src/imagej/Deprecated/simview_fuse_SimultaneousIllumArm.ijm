dataset_file = File.openDialog("Select xml file");
Dialog.create("Number of frames to fuse");
Dialog.addNumber("First Frame", 0);
Dialog.addNumber("Last Frame", 1);
Dialog.addCheckbox("Fuse to BDV hdf5",1)
Dialog.addCheckbox("Fuse to individual tif files",0)
Dialog.show();
frameStart = Dialog.getNumber();
frameEnd = Dialog.getNumber();
Choose_hdf5 = Dialog.getCheckbox();
Choose_tif = Dialog.getCheckbox();

// Set up the output directory
output_dir = File.getDirectory("[" + dataset_file + "]");
output_dir = output_dir + File.separator() + "fused";
if (!File.exists(output_dir))
{
	File.makeDirectory(output_dir);
	print("Making directory " + output_dir);
}

if (Choose_hdf5){

    // Create a string representing the requested time points
    timeString = "" + frameStart;
    for (i=frameStart+1; i<frameEnd+1; ++i){
        timeString = timeString + "," + i;
    }

    // Now Run fusion to export tif files for all requested timepoints
    run("Fuse dataset ...", "select=[" + dataset_file + "] process_angle=[All angles] process_channel=[All channels] process_illumination=[All illuminations] process_tile=[All tiles] process_timepoint=[Range of Timepoints (Specify by Name)] process_following_timepoints=" + timeString + " bounding_box=[All Views] downsampling=1 interpolation=[Linear Interpolation] pixel_type=[16-bit unsigned integer] interest_points_for_non_rigid=[-= Disable Non-Rigid =-] blend preserve_original produce=[Each timepoint & channel] fused_image=[ZARR/N5/HDF5 export using N5-API] define_input=[Auto-load from input data (values shown below)] min=0 max=65535 export=HDF5 create hdf5_file=" + output_dir + File.separator() + "fused.h5 xml_output_file=" + output_dir + File.separator() + "dataset.xml");

    print("DONE\nBDV-compatible HDF5 file created in " + output_dir + "\n");

}

if (Choose_tif){

    for (i=frameStart; i<frameEnd+1; ++i){

        run("Fuse dataset ...", "select=[" + dataset_file + "] process_angle=[All angles] process_channel=[Multiple channels (Select from List)] process_illumination=[All illuminations] process_tile=[All tiles] process_timepoint=[Single Timepoint (Select from List)] channel_488 processing_timepoint=[Timepoint " + i + "] bounding_box=[All Views] downsampling=1 pixel_type=[16-bit unsigned integer] interpolation=[Linear Interpolation] image=[Precompute Image] interest_points_for_non_rigid=[-= Disable Non-Rigid =-] blend produce=[All views together] fused_image=[Save as (compressed) TIFF stacks] output_file_directory=" + output_dir + " filename_addition=blended_t" + leftPad(i,4) + "_ch0");

        run("Fuse dataset ...", "select=[" + dataset_file + "] process_angle=[All angles] process_channel=[Multiple channels (Select from List)] process_illumination=[All illuminations] process_tile=[All tiles] process_timepoint=[Single Timepoint (Select from List)] channel_561 processing_timepoint=[Timepoint " + i + "] bounding_box=[All Views] downsampling=1 pixel_type=[16-bit unsigned integer] interpolation=[Linear Interpolation] image=[Precompute Image] interest_points_for_non_rigid=[-= Disable Non-Rigid =-] blend produce=[All views together] fused_image=[Save as (compressed) TIFF stacks] output_file_directory=" + output_dir + " filename_addition=blended_t" + leftPad(i,4) + "_ch1");

    }

print("DONE\nWrote tif files to " + output_dir + "\n");

}

// Converts 'n' to a string, left padding with zeros
// so the length of the string is 'width'
function leftPad(n, width) {
    s =""+n;
    while (lengthOf(s)<width)
        s = "0"+s;
    return s;
}
