function ReadAndWriteRestructuredKLBs(imMetadata, currentImMetadata, lightsheetIndex, cameraIndex, scopeChannels, structured, outputDir, spm, frame)
    scopeChannelsForCurrentView = scopeChannels(lightsheetIndex:imMetadata.NumberOfLightSheets:end);
    currentImageData = SiMView.GetImages(imMetadata, structured, frame, scopeChannelsForCurrentView, cameraIndex, spm);
    
    if cameraIndex == 2
        currentImageData = flip(currentImageData,2); %Flipped because of how camera 2 acquires wrt camera 1
    end
    
    if (frame == currentImMetadata.NumberOfFrames && nnz(currentImageData) == 0)
        % If last frame is empty change the metadata to reflect this
        currentImMetadata.NumberOfFrames = currentImMetadata.NumberOfFrames - 1;
        MicroscopeData.CreateMetadata(outputDir,currentImMetadata);
    else        
        % Write KLB
        MicroscopeData.WriterKLB(currentImageData, 'path', outputDir, 'imageData', currentImMetadata, 'datasetName', currentImMetadata.DatasetName,'timeRange',[frame, frame],'filePerT',true,'filePerC',true,'writeJson', false);
        
        orthoSliceProjections = ImUtils.MakeOrthoSliceProjections(currentImageData, currentImMetadata.ChannelColors, currentImMetadata.PixelPhysicalSize(1), currentImMetadata.PixelPhysicalSize(3));
        orthoSliceProjections = ImUtils.MakeImageXYDimEven(orthoSliceProjections);
        
        if (~exist(fullfile(outputDir, 'MovieFrames'),'dir'))
            mkdir(fullfile(outputDir, 'MovieFrames'));
        end
        
        imwrite(orthoSliceProjections, fullfile(outputDir, 'MovieFrames', sprintf('%04d.tif',frame)));
    end
end