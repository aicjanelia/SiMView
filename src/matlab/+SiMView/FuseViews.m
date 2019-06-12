function finalFusedImage = FuseViews(rootDir, transform, channel, frame)
outputDir = fullfile(fileparts(rootDir), 'Processed');
imMetadata = MicroscopeData.ReadMetadata(outputDir);
numValidSlices = imMetadata.Dimensions(3);
for currentLightsheet = 1:imMetadata.NumberOfLightSheets
    if imMetadata.NumberOfCameras>1
        view1Directory = fullfile(rootDir, sprintf('LS%dCM1', currentLightsheet));
        view2Directory = fullfile(rootDir, sprintf('LS%dCM2', currentLightsheet));       
        image1 = squeeze(MicroscopeData.Reader(view1Directory, 'chanList', channel, 'timeRange', [frame,frame]));
        image2 = squeeze(MicroscopeData.Reader(view2Directory, 'chanList', channel, 'timeRange', [frame,frame]));
        warpedImage2 = imwarp(image2, affine2d(transform), 'outputview', imref2d(size(image2)),'interp','cubic');
        fusedCameraImage = zeros(imMetadata.Dimensions([2,1,3]), imMetadata.PixelFormat);
        maxPerSlice = squeeze(max(max(image1,[],1))); %don't want to include zero padded sections
        numValidSlices = sum(maxPerSlice>0);
        for slice = 1:numValidSlices
            fusedCameraImage(:,:,slice) = wfusimg(image1(:,:,slice), warpedImage2(:,:,slice), 'db4', 5, 'mean', 'max');
        end
        imagesByLightsheet(currentLightsheet).image = fusedCameraImage;
    else
        viewDirectory = sprintf('LS%dCM1', lightsheet);
        imagesByLightsheet(currentLightsheet).image = squeeze(MicroscopeData.Reader(viewDirectory, 'chanList', channel, 'timeRange', [frame,frame]));
        maxPerSlice = squeeze(max(max(imagesByLightsheet(currentLightsheet).image,[],1))); %don't want to include zero padded sections
        numValidSlices = sum(maxPerSlice>0);
    end
end

if imMetadata.NumberOfLightSheets>1
    finalFusedImage = zeros(imMetadata.Dimensions([2,1,3]), imMetadata.PixelFormat);
    for slice = 1:numValidSlices
        finalFusedImage(:,:,slice) = wfusimg(imagesByLightsheet(1).image(:,:,slice), imagesByLightsheet(2).image(:,:,slice), 'db4', 5, 'mean', 'max');
    end
else
    finalFusedImage = imagesByLightsheet(1).image;
end
MicroscopeData.WriterKLB(finalFusedImage, 'path', outputDir, 'imageData', imMetadata,'timeRange',[frame, frame],'chanList', channel, 'filePerT',true,'filePerC',true,'writeJson', false);

    imOrtho = ImUtils.MakeOrthoSliceProjections(finalFusedImage,[1,1,1],imMetadata.PixelPhysicalSize(1),imMetadata.PixelPhysicalSize(3));
    if (~exist(fullfile(outputDir,'movieFrames')))
        mkdir(fullfile(outputDir,'movieFrames'));
    end
    imwrite(imOrtho,sprintf('c%d_%04d.tif',channel,frame));
end

