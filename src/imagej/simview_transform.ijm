dataset_file = File.openDialog("Select xml file");
Dialog.create("X dimension");
Dialog.addNumber("X dimension", 2048);
Dialog.show();
x_dimension = Dialog.getNumber();

run("Apply Transformations", "select=" +
dataset_file + 
" apply_to_angle=[Single angle (Select from List)] apply_to_channel=[All channels] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] apply_to_timepoint=[All Timepoints] processing_angle=[angle 0-1] transformation=Affine apply=[Current view transformations (appends to current transforms)] same_transformation_for_all_timepoints same_transformation_for_all_channels all_timepoints_all_channels_illumination_0_angle_0-1=[-1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0]");

run("Apply Transformations", "select=" +
dataset_file +
" apply_to_angle=[Single angle (Select from List)] apply_to_channel=[All channels] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] apply_to_timepoint=[All Timepoints] processing_angle=[angle 0-1] transformation=Translation apply=[Current view transformations (appends to current transforms)] same_transformation_for_all_timepoints same_transformation_for_all_channels all_timepoints_all_channels_illumination_0_angle_0-1=[" + x_dimension + ", 0.0, 0.0]");

print("Done applying transforms.\nSet registration for first frame and then run fuse macro.");
