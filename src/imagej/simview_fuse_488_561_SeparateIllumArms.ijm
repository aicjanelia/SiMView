dataset_file = File.openDialog("Select xml file");
Dialog.create("Number of frames to fuse");
Dialog.addNumber("First Frame", 0);
Dialog.addNumber("Last Frame", 1);
Dialog.show();
frameStart = Dialog.getNumber();
frameEnd = Dialog.getNumber();

// First apply the stitching from 488 to 561 (assuming 488 for intrest points, need to make this an option)
run("Duplicate Transformations", "apply=[One channel to other channels] select=" + dataset_file + " apply_to_angle=[All angles] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] apply_to_timepoint=[Single Timepoint (Select from List)] processing_timepoint=[Timepoint 0] source=488 target=[Single Channel (Select from List)] processing_channel=561 duplicate_which_transformations=[Replace all transformations]");

run("Duplicate Transformations", "apply=[One channel to other channels] select=" + dataset_file + " apply_to_angle=[All angles] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] apply_to_timepoint=[Single Timepoint (Select from List)] processing_timepoint=[Timepoint 0] source=489 target=[Single Channel (Select from List)] processing_channel=562 duplicate_which_transformations=[Replace all transformations]");

// Next apply this to all timepoints
run("Duplicate Transformations", "apply=[One timepoint to other timepoints] select=" + dataset_file + " apply_to_angle=[All angles] apply_to_channel=[All channels] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] source=0 target=[All Timepoints] duplicate_which_transformations=[Replace all transformations]");

print("Finished applying transforms.\n");

// Now run fusion to export tif files for all timepoints
output_dir = File.getDirectory(dataset_file);
output_dir = output_dir + File.separator() + "fused";
if (!File.exists(output_dir))
{
	File.makeDirectory(output_dir);
	print("Making directory " + output_dir);
}

for (i=frameStart; i<frameEnd; ++i){
{

    run("Fuse dataset ...", "select=" + dataset_file + " process_angle=[All angles] process_channel=[Multiple channels (Select from List)] process_illumination=[All illuminations] process_tile=[All tiles] process_timepoint=[Single Timepoint (Select from List)] channel_488 channel_489 processing_timepoint=[Timepoint " + i + "] bounding_box=[All Views] downsampling=1 pixel_type=[16-bit unsigned integer] interpolation=[Linear Interpolation] image=[Precompute Image] interest_points_for_non_rigid=[-= Disable Non-Rigid =-] blend produce=[All views together] fused_image=[Save as (compressed) TIFF stacks] output_file_directory=" + output_dir + " filename_addition=blended_t" + leftPad(i,4) + "_ch0");

    run("Fuse dataset ...", "select=" + dataset_file + " process_angle=[All angles] process_channel=[Multiple channels (Select from List)] process_illumination=[All illuminations] process_tile=[All tiles] process_timepoint=[Single Timepoint (Select from List)] channel_561 channel_562 processing_timepoint=[Timepoint " + i + "] bounding_box=[All Views] downsampling=1 pixel_type=[16-bit unsigned integer] interpolation=[Linear Interpolation] image=[Precompute Image] interest_points_for_non_rigid=[-= Disable Non-Rigid =-] blend produce=[All views together] fused_image=[Save as (compressed) TIFF stacks] output_file_directory=" + output_dir + " filename_addition=blended_t" + leftPad(i,4) + "_ch1");

}

print("DONE\nWrote files to " + output_dir + "\n");

// Converts 'n' to a string, left padding with zeros
// so the length of the string is 'width'
function leftPad(n, width) {
    s =""+n;
    while (lengthOf(s)<width)
        s = "0"+s;
    return s;
}