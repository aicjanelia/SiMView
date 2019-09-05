function ClusterReadAndWriteRestructuredKLBs(imMetadata, currentImMetadata, lightsheetIndex, cameraIndex, scopeChannels, structured, outputDir, spm, frame)
    load(imMetadata); 
    load(currentImMetadata);
    
    lightsheetIndex = str2num(lightsheetIndex);
    cameraIndex = str2num(cameraIndex);
    
    scopeChannels = jsondecode(scopeChannels);
    structured = str2num(structured);
    
    frame = str2num(frame);
    spm = str2double(spm);
    SiMView.ReadAndWriteRestructuredKLBs(imMetadata, currentImMetadata, lightsheetIndex, cameraIndex, scopeChannels, structured, outputDir, spm, frame);
end
