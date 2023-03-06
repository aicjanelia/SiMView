dataset_file = File.openDialog("Select xml file");
Dialog.create("Number of frames to fuse");
Dialog.addNumber("Number of Frames", 1);
Dialog.show();
num_frames = Dialog.getNumber();

run("Duplicate Transformations", "apply=[One timepoint to other timepoints] select=" +
dataset_file +
" apply_to_angle=[All angles] apply_to_channel=[All channels] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] source=0 target=[All Timepoints] duplicate_which_transformations=[Replace all transformations]");

print("Finished applying transforms.\n");

output_dir = File.getDirectory(dataset_file);
output_dir = output_dir + File.separator() + "fused";
if (!File.exists(output_dir))
{
	File.makeDirectory(output_dir);
	print("Making directory " + output_dir);
}

for (i=1; i<num_frames; ++i)
{
	run("Fuse dataset ...", "select=" + dataset_file + " process_angle=[All angles] process_channel=[All channels] process_illumination=[All illuminations] process_tile=[All tiles] process_timepoint=[Single Timepoint (Select from List)] processing_timepoint=[Timepoint " + i + "] bounding_box=[Currently Selected Views] downsampling=1 pixel_type=[16-bit unsigned integer] interpolation=[Linear Interpolation] image=[Precompute Image] produce=[All views together] fused_image=[Save as (compressed) TIFF stacks] output_file_directory=" + output_dir + " filename_addition=fused_" + i + "t");
}

print("DONE\nWrote files to " + output_dir + "\n");
