//Move BigStitcher XML into appropriate coordinate system for camera registration

// Start by getting the appropriate XML file
Dialog.create("Transformation Parameters");
Dialog.addFile("XML file to process","");
Dialog.addCheckbox("Do not parse metadata. Values will be entered manually.",false);
Dialog.show();
parseMeta = Dialog.getCheckbox();
dataset_file = Dialog.getString();

// Default values are empty to make user fill in
width = NaN;
maxT = NaN;
maxZ = NaN;
zStep = NaN;
sepIllum = false;

if (!parseMeta){
	
	// Use the images from timepoint 0 to grab metadata
	print("Parsing metadata...");
		
	// Get the number of z-slices
	// Note: can't read maxZ from the XML because the XML will have a lower value if the zFlip is required
	dirIm = File.getDirectory(dataset_file);
	list = getFileList(dirIm + "/TM00000/ANG000/");
	maxZ = list[list.length-1];
	maxZ = substring(maxZ, 38,42);
	maxZ = parseFloat(maxZ)+1;
	
	// Get the number of time points
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
	maxT = maxT+1;
	
	// Get the z-spacing and x-size from the xml
	xmlData = File.openAsString(dataset_file);
	startIndx = indexOf(xmlData,"<voxelSize>");
	zStep = substring(xmlData,startIndx+68,startIndx+71);
	zStep = parseFloat(zStep);
	startIndx = indexOf(xmlData,"<size>");
	width = substring(xmlData,startIndx+6,startIndx+10);
	width = parseFloat(width);
	
	// Use the xml to check for multiple illuminations
	startIndx = indexOf(xmlData,"</Illumination></Attributes>");
	if (startIndx > 0){ //startIndx will be -1 for single illumination arms
		sepIllum = true;
	}

}

// Ask the user to confirm metadata
// Also choose which transforms
Dialog.create("Transformation Parameters")
Dialog.addNumber("Total Timepoints",maxT);
Dialog.addCheckbox("Multiple, separate illumination arms", sepIllum);
Dialog.addMessage(" ");
Dialog.addCheckbox("Flip camera 1 coordinate system",true);
Dialog.addNumber("Image X Dimension (pixels)",width);
Dialog.addMessage(" ");
Dialog.addMessage("The following parameters are only necessary for excluded z-slices.");
Dialog.addCheckbox("Transform the coordinate system for excluded z-slices", false);
Dialog.addNumber("XY Pixel Size (um)", 0.4125);
Dialog.addNumber("Z Pixel Size (um)", zStep);
Dialog.addNumber("Total z-slices (max PLN filename + 1)",maxZ);

Dialog.show();
// Get all the user inputs
// General set up
maxT = Dialog.getNumber();
sepIllum = Dialog.getCheckbox();
// Camera transform
flipCam = Dialog.getCheckbox();
xDim = Dialog.getNumber();
// Z transform
flipZ = Dialog.getCheckbox();
xyPix = Dialog.getNumber();
zPix = Dialog.getNumber();
maxZ = Dialog.getNumber();


// Confirm valid inputs
if (!flipCam && !flipZ){
	exit("No transformations requested. Exiting macro.")
}
if (isNaN(maxT) || maxT <= 0){
	exit("Invalid number of frames. Check your inputs and try again.")
}
if (flipCam){
	if (isNaN(xDim) || xDim <= 0){
		exit("Invalid image x dimension. Check your inputs and try again.")
	}
}
if (flipZ){	
	if (isNaN(xyPix) || xyPix <= 0){
		exit("Invalid XY pixel size. Check your inputs and try again.")
	}
	if (isNaN(zPix) || zPix <= 0){
		exit("Invalid Z pixel size. Check your inputs and try again.")
	}
	if (isNaN(maxZ) || maxZ <= 0){
		exit("Invalid number of z-slices. Check your inputs and try again.")
	}
	zShift = maxZ*zPix/xyPix;
}

// Transform in z first, if requested
if (flipZ){ 
	if (maxT==1){ // need to use special syntax for one timepoint
		if (sepIllum){ // need to use syntax for multiple illuminations
			// Flip Z
			run("Apply Transformations", "select=[file:/" + dataset_file + "] apply_to_angle=[Single angle (Select from List)] apply_to_channel=[All channels] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] apply_to_timepoint=[All Timepoints] processing_angle=[angle 0-1] transformation=Affine apply=[Current view transformations (appends to current transforms)] same_transformation_for_all_channels same_transformation_for_all_illuminations timepoint_0_all_channels_all_illuminations_angle_0-1=[1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, -1.0, 0.0]");
			
			// Shift appropriately in Z
			run("Apply Transformations", "select=[file:/" + dataset_file + "] apply_to_angle=[Single angle (Select from List)] apply_to_channel=[All channels] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] apply_to_timepoint=[All Timepoints] processing_angle=[angle 0-1] transformation=Translation apply=[Current view transformations (appends to current transforms)] same_transformation_for_all_channels same_transformation_for_all_illuminations timepoint_0_all_channels_all_illuminations_angle_0-1=[0.0, 0.0, "+ zShift+ "]");
		} else {
			// Flip Z
			run("Apply Transformations", "select=[file:/" + dataset_file + "] apply_to_angle=[Single angle (Select from List)] apply_to_channel=[All channels] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] apply_to_timepoint=[All Timepoints] processing_angle=[angle 0-1] transformation=Affine apply=[Current view transformations (appends to current transforms)] same_transformation_for_all_channels timepoint_0_all_channels_illumination_0_angle_0-1=[1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, -1.0, 0.0]");
			
			// Shift appropriately in Z
			run("Apply Transformations", "select=[file:/" + dataset_file + "] apply_to_angle=[Single angle (Select from List)] apply_to_channel=[All channels] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] apply_to_timepoint=[All Timepoints] processing_angle=[angle 0-1] transformation=Translation apply=[Current view transformations (appends to current transforms)] same_transformation_for_all_channels timepoint_0_all_channels_illumination_0_angle_0-1=[0.0, 0.0, "+ zShift+ "]");
			
		}
	} else { // can use all timepoints syntax
		if (sepIllum){ // need to use syntax for multiple illuminations
			// Flip Z
			run("Apply Transformations", "select=[file:/" + dataset_file + "] apply_to_angle=[Single angle (Select from List)] apply_to_channel=[All channels] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] apply_to_timepoint=[All Timepoints] processing_angle=[angle 0-1] transformation=Affine apply=[Current view transformations (appends to current transforms)] same_transformation_for_all_timepoints same_transformation_for_all_channels same_transformation_for_all_illuminations all_timepoints_all_channels_all_illuminations_angle_0-1=[1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, -1.0, 0.0]");
			
			// Shift appropriately in Z
			run("Apply Transformations", "select=[file:/" + dataset_file + "] apply_to_angle=[Single angle (Select from List)] apply_to_channel=[All channels] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] apply_to_timepoint=[All Timepoints] processing_angle=[angle 0-1] transformation=Translation apply=[Current view transformations (appends to current transforms)] same_transformation_for_all_timepoints same_transformation_for_all_channels same_transformation_for_all_illuminations all_timepoints_all_channels_all_illuminations_angle_0-1=[0.0, 0.0, "+ zShift+ "]");
		} else {
			// Flip Z
			run("Apply Transformations", "select=[file:/" + dataset_file + "] apply_to_angle=[Single angle (Select from List)] apply_to_channel=[All channels] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] apply_to_timepoint=[All Timepoints] processing_angle=[angle 0-1] transformation=Affine apply=[Current view transformations (appends to current transforms)] same_transformation_for_all_timepoints same_transformation_for_all_channels all_timepoints_all_channels_illumination_0_angle_0-1=[1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, -1.0, 0.0]");
			
			// Shift appropriately in Z
			run("Apply Transformations", "select=[file:/" + dataset_file + "] apply_to_angle=[Single angle (Select from List)] apply_to_channel=[All channels] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] apply_to_timepoint=[All Timepoints] processing_angle=[angle 0-1] transformation=Translation apply=[Current view transformations (appends to current transforms)] same_transformation_for_all_timepoints same_transformation_for_all_channels all_timepoints_all_channels_illumination_0_angle_0-1=[0.0, 0.0, "+ zShift+ "]");
			
		}
	}

	print("Camera 1 z-dimension flipped and shifted.");
}


// Transform camera if requested
if (flipCam){ 
	if (maxT==1){ // need to use special syntax for one timepoint
		if (sepIllum){ // need to use separate syntax for multiple illuminations
			// Flip in X
			run("Apply Transformations", "select=[file:/" + dataset_file + "] apply_to_angle=[Single angle (Select from List)] apply_to_channel=[All channels] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] apply_to_timepoint=[All Timepoints] processing_angle=[angle 0-1] transformation=Affine apply=[Current view transformations (appends to current transforms)] same_transformation_for_all_channels same_transformation_for_all_illuminations timepoint_0_all_channels_all_illuminations_angle_0-1=[-1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0]");
			
			// Shift appropriately in X
			run("Apply Transformations", "select=[file:/" + dataset_file + "] apply_to_angle=[Single angle (Select from List)] apply_to_channel=[All channels] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] apply_to_timepoint=[All Timepoints] processing_angle=[angle 0-1] transformation=Translation apply=[Current view transformations (appends to current transforms)] same_transformation_for_all_channels same_transformation_for_all_illuminations timepoint_0_all_channels_all_illuminations_angle_0-1=["+xDim+", 0.0, 0.0]");
		} else {
			// Flip in X
			run("Apply Transformations", "select=[file:/" + dataset_file + "] apply_to_angle=[Single angle (Select from List)] apply_to_channel=[All channels] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] apply_to_timepoint=[All Timepoints] processing_angle=[angle 0-1] transformation=Affine apply=[Current view transformations (appends to current transforms)] same_transformation_for_all_channels timepoint_0_all_channels_illumination_0_angle_0-1=[-1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0]");
			
			// Shift appropriately in X
			run("Apply Transformations", "select=[file:/" + dataset_file + "] apply_to_angle=[Single angle (Select from List)] apply_to_channel=[All channels] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] apply_to_timepoint=[All Timepoints] processing_angle=[angle 0-1] transformation=Translation apply=[Current view transformations (appends to current transforms)] same_transformation_for_all_channels timepoint_0_all_channels_illumination_0_angle_0-1=["+xDim+", 0.0, 0.0]");
		}
		
	} else { // can use all timepoints syntax
		if (sepIllum){ // need to use separate syntax for multiple illuminations
			// Flip in X
			run("Apply Transformations", "select=[file:/" + dataset_file + "] apply_to_angle=[Single angle (Select from List)] apply_to_channel=[All channels] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] apply_to_timepoint=[All Timepoints] processing_angle=[angle 0-1] transformation=Affine apply=[Current view transformations (appends to current transforms)] same_transformation_for_all_timepoints same_transformation_for_all_channels same_transformation_for_all_illuminations all_timepoints_all_channels_all_illuminations_angle_0-1=[-1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0]");
			
			// Shift appropriately in X
			run("Apply Transformations", "select=[file:/" + dataset_file + "] apply_to_angle=[Single angle (Select from List)] apply_to_channel=[All channels] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] apply_to_timepoint=[All Timepoints] processing_angle=[angle 0-1] transformation=Translation apply=[Current view transformations (appends to current transforms)] same_transformation_for_all_timepoints same_transformation_for_all_channels same_transformation_for_all_illuminations all_timepoints_all_channels_all_illuminations_angle_0-1=["+xDim+", 0.0, 0.0]");
		
		} else {
			// Flip in X
			run("Apply Transformations", "select=[file:/" + dataset_file + "] apply_to_angle=[Single angle (Select from List)] apply_to_channel=[All channels] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] apply_to_timepoint=[All Timepoints] processing_angle=[angle 0-1] transformation=Affine apply=[Current view transformations (appends to current transforms)] same_transformation_for_all_timepoints same_transformation_for_all_channels all_timepoints_all_channels_illumination_0_angle_0-1=[-1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0]");
			
			// Shift appropriately in X
			run("Apply Transformations", "select=[file:/" + dataset_file + "] apply_to_angle=[Single angle (Select from List)] apply_to_channel=[All channels] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] apply_to_timepoint=[All Timepoints] processing_angle=[angle 0-1] transformation=Translation apply=[Current view transformations (appends to current transforms)] same_transformation_for_all_timepoints same_transformation_for_all_channels all_timepoints_all_channels_illumination_0_angle_0-1=["+xDim+", 0.0, 0.0]");
			
		}
	}
	
	print("Camera 1 x-dimension flipped and shifted.");
}


print("Done applying transforms.\nProceed to the next step in the SiMView workflow.");


