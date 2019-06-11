function ClusterReadAndWriteRestructuredKLBs(imMetadata, currentImMetadata, lightsheetIndex, cameraIndex, scopeChannels, structured, outputDir, frame)
load(imMetadata); 
load(currentImMetadata);
lightsheetIndex = str2num(lightsheetIndex);
cameraIndex = str2num(cameraIndex);
scopeChannels = jsondecode(scopeChannels);
structured = str2num(structured);
frame = str2num(frame);
SiMView.ReadAndWriteRestructuredKLBs(imMetadata, currentImMetadata, lightsheetIndex, cameraIndex, scopeChannels, structured, outputDir, frame);