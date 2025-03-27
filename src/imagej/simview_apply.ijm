// Apply transforms from one view to another

// Start by getting the appropriate XML file
Dialog.create("Transformation Parameters");
Dialog.addFile("XML file to process","");

Dialog.addCheckbox("Copy from one channel to all others at one timepoint.", true);

Dialog.addNumber("Source (channel registered with interest points)", 488);
Dialog.addNumber("Time point to copy", 0);

Dialog.addCheckbox("Copy from one time point to all others.", true);

Dialog.addNumber("Time point to copy", 0);

Dialog.addCheckbox("Copy from one channel to all others timepoint-by-timepoint.", false);

Dialog.addNumber("Source (channel registered with interest points)", 488);

Dialog.show();
dataset_file = Dialog.getString();

copyChannel = Dialog.getCheckbox();
source = Dialog.getNumber();
refTimeC = Dialog.getNumber();

copyTime = Dialog.getCheckbox();
refTimeT = Dialog.getNumber();

copyChannelTime = Dialog.getCheckbox();
sourceCT = Dialog.getNumber();


if (copyChannel){
	// First apply the stitching from one channel to the other
	run("Duplicate Transformations", "apply=[One channel to other channels] select=[file:/" + dataset_file + "] apply_to_angle=[All angles] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] apply_to_timepoint=[Single Timepoint (Select from List)] processing_timepoint=[Timepoint "+refTimeC+"] source=" + source + " target=[All Channels] duplicate_which_transformations=[Replace all transformations]");	
}

if (copyTime){
	// Next apply this to all timepoints
	run("Duplicate Transformations", "apply=[One timepoint to other timepoints] select=[file:/" + dataset_file + "] apply_to_angle=[All angles] apply_to_channel=[All channels] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] source="+refTimeT+" target=[All Timepoints] duplicate_which_transformations=[Replace all transformations]");
}

if (copyChannelTime){
	// Apply across channels, timepoint by timepoint
	run("Duplicate Transformations", "apply=[One channel to other channels] select=[file:/" + dataset_file + "] apply_to_angle=[All angles] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] apply_to_timepoint=[All Timepoints] source=" + source + " target=[All Channels] duplicate_which_transformations=[Replace all transformations]");
}

print("Finished applying transforms.\n");
