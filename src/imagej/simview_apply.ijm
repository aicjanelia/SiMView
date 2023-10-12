// Apply transforms from one view to another

// Start by getting the appropriate XML file
Dialog.create("Transformation Parameters");
Dialog.addFile("XML file to process","");

Dialog.addCheckbox("Copy from one channel to another.", true);
Dialog.addCheckbox("Copy from one time point to all others.", true);

Dialog.addNumber("Source (channel registered with interest points)", 488);
Dialog.addNumber("Target (channel to apply the registration to)", 561);
Dialog.addNumber("Time point to copy", 0);

Dialog.show();
dataset_file = Dialog.getString();
copyChannel = Dialog.getCheckbox();
copyTime = Dialog.getCheckbox();
source = Dialog.getNumber();
target = Dialog.getNumber();
refTime = Dialog.getNumber();

if (copyChannel){
	// First apply the stitching from one channel to the other
	run("Duplicate Transformations", "apply=[One channel to other channels] select=[" + dataset_file + "] apply_to_angle=[All angles] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] apply_to_timepoint=[Single Timepoint (Select from List)] processing_timepoint=[Timepoint "+refTime+"] source=" + source + " target=[Single Channel (Select from List)] processing_channel=" + target + " duplicate_which_transformations=[Replace all transformations]");	
}

if (copyTime){
	// Next apply this to all timepoints
	run("Duplicate Transformations", "apply=[One timepoint to other timepoints] select=[" + dataset_file + "] apply_to_angle=[All angles] apply_to_channel=[All channels] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] source="+refTime+" target=[All Timepoints] duplicate_which_transformations=[Replace all transformations]");
}

print("Finished applying transforms.\n");
