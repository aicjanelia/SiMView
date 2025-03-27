//Add pixel calibration to a BigStitcher xml
Dialog.create("Calibration Parameters");
Dialog.addFile("XML file to process","");
Dialog.addMessage("SiMView Aquisition Pixel Sizes");
Dialog.addNumber("XY Pixel Size", 0.4125);
Dialog.addNumber("Z Pixel Size", NaN);
Dialog.addMessage("If previously downsampled, add the factor here.");
Dialog.addNumber("Downsample",1);

Dialog.show();
dataset_file = Dialog.getString();
xyPix = Dialog.getNumber();
zPix = Dialog.getNumber();
downsamp = Dialog.getNumber();

if (isNaN(zPix)){
	exit("Error: Z Pixel Size must be entered.")
}

run("Specify Calibration", "select=[file:/" + dataset_file + "] process_angle=[All angles] process_channel=[All channels] process_illumination=[All illuminations] process_tile=[All tiles] process_timepoint=[All Timepoints] calibration_x=" + downsamp*xyPix + " calibration_y=" + downsamp*xyPix + " calibration_z=" + downsamp*zPix + " unit=um");

run("Apply Transformations", "select=[file:/" + dataset_file + "] apply_to_angle=[All angles] apply_to_channel=[All channels] apply_to_illumination=[All illuminations] apply_to_tile=[All tiles] apply_to_timepoint=[All Timepoints] transformation=[Identity (no transformation)] apply=[Calibration (removes any existing transforms)] same_transformation_for_all_timepoints same_transformation_for_all_channels");