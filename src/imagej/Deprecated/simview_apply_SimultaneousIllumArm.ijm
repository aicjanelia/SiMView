dataset_file = File.openDialog("Select xml file");
Dialog.create("Channels");
Dialog.addNumber("Source (channel registered with interest points)", 488);
Dialog.addNumber("Target (channel to apply the registration to)", 561);
Dialog.show();
source = Dialog.getNumber();
target = Dialog.getNumber();

// First apply the stitching from 488 to 561 (assuming 488 for intrest points, need to make this an option)
run("Duplicate Transformations", "apply=[One channel to other channels] select=[" + dataset_file + "] apply_to_angle=[All angles] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] apply_to_timepoint=[Single Timepoint (Select from List)] processing_timepoint=[Timepoint 0] source=" + source + " target=[Single Channel (Select from List)] processing_channel=" + target + " duplicate_which_transformations=[Replace all transformations]");

// Next apply this to all timepoints
run("Duplicate Transformations", "apply=[One timepoint to other timepoints] select=[" + dataset_file + "] apply_to_angle=[All angles] apply_to_channel=[All channels] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] source=0 target=[All Timepoints] duplicate_which_transformations=[Replace all transformations]");

print("Finished applying transforms.\n");
