function ReadAndWriteRestructuredKLBs(imMetadata, currentImMetadata, lightsheetIndex, cameraIndex, scopeChannels, structured, outputDir, frame)
scopeChannelsForCurrentView = scopeChannels(lightsheetIndex:imMetadata.NumberOfChannels:end);
currentImageData = SiMView.GetImages(imMetadata, structured, frame, scopeChannelsForCurrentView, cameraIndex);
if cameraIndex == 2
    currentImageData = flip(currentImageData,2); %Flipped because of how camera 2 acquires wrt camera 1
end
% Write KLB
MicroscopeData.WriterKLB(currentImageData, 'path', outputDir, 'imageData', currentImMetadata, 'datasetName', currentImMetadata.DatasetName,'timeRange',[frame, frame],'filePerT',true,'filePerC',true,'writeJson', false);
orthoSliceProjections = ImUtils.MakeOrthoSliceProjections(currentImageData, currentImMetadata.ChannelColors, currentImMetadata.PixelPhysicalSize(1), currentImMetadata.PixelPhysicalSize(3));
if (~exist(fullfile(outputDir, 'MovieFrames'),'dir'))
    mkdir(fullfile(outputDir, 'MovieFrames'));
end
imwrite(orthoSliceProjections, fullfile(outputDir, 'MovieFrames', sprintf('%04d.tif',frame)));
end