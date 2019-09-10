function [optimalResults, registrationResults] = GetOptimalRegistrationTransform(view1Directory, view2Directory, channel, useECC, rigidOrTranslation, multimodalOrMonomodal, maximumIterations)
    parforArg = 0;
    numberOfLevels = 4;
    numberOfIterations = [60, 3, 3, 3];

    if useECC
        parforArg = Inf;
    end
    if isempty(rigidOrTranslation)
        rigidOrTranslation = 'rigid'; 
    end
    if isempty(multimodalOrMonomodal)
        multimodalOrMonomodal = 'multimodal'; 
    end

    [optimizer, metric] = imregconfig(multimodalOrMonomodal);

    if ~isempty(maximumIterations)
        optimizer.MaximumIterations = maximumIterations;
    end

    optimalResults.bestNormalizedCovariance = -1;
    metadata = MicroscopeData.ReadMetadata(view1Directory);
    registrationResults = [];

    for frame = [1 , round(metadata.NumberOfFrames/2) , metadata.NumberOfFrames]
        currentImageStackView1 = squeeze(MicroscopeData.Reader(view1Directory, 'chanList', channel, 'timeRange', [frame,frame]));
        currentImageStackView2 = squeeze(MicroscopeData.Reader(view2Directory, 'chanList', channel, 'timeRange', [frame,frame]));

        maxPerSlice = squeeze(max(max(currentImageStackView1,[],1))); %don't want to include zero padded sections
        numValidSlices = sum(maxPerSlice>0);

        normalizedCovariance = zeros(numValidSlices, 2);
        transforms = affine2d.empty(0,numValidSlices);
        transforms(1,numValidSlices) = affine2d();

        if frame == 1
            sizeFactor = round(size(currentImageStackView1)*.25);
            rRange = sizeFactor(1)*2-sizeFactor(1) : sizeFactor(1)*2+sizeFactor(1);
            cRange = sizeFactor(2)*2-sizeFactor(2) : sizeFactor(2)*2+sizeFactor(2);
        end

        parfor (slice = 1:numValidSlices, parforArg)
%         for slice = 1:numValidSlices
            currentImageSliceView1 = currentImageStackView1(:,:,slice);
            currentImageSliceView2 = currentImageStackView2(:,:,slice);

            if (nnz(currentImageSliceView1(:))==0 || nnz(currentImageSliceView2(:))==0)
                fprintf('%d continue\n',slice);
                drawnow
                continue
            end

            if useECC
                [~, sliceTransform, currentImageSliceView2Warped] = ECCFast.ecc(currentImageSliceView2, currentImageSliceView1, numberOfLevels, numberOfIterations, 'euclidean');
            else
                sliceTransform = imregtform(currentImageSliceView2, currentImageSliceView1, rigidOrTranslation, optimizer, metric);
                currentImageSliceView2Warped = imwarp(currentImageSliceView2, sliceTransform, 'outputview', imref2d(size(currentImageSliceView2)), 'interp', 'cubic');
            end
            
            transforms(1,slice) = sliceTransform;
            normalizedCovariance(slice,:) = [Math.NormalizedCovariance(currentImageSliceView1(rRange, cRange), currentImageSliceView2(rRange, cRange)), Math.NormalizedCovariance(currentImageSliceView1(rRange, cRange), currentImageSliceView2Warped(rRange, cRange))];
        end
        
        currentRegistrationResult = [];
        currentRegistrationResult.t = frame;
        currentRegistrationResult.normalizedCovariance = normalizedCovariance;
        currentRegistrationResult.transforms = transforms;
        
        registrationResults = [registrationResults; currentRegistrationResult];
        
        [maxNormalizedCovariance, maxIndex] = max(normalizedCovariance(:,2));
        if maxNormalizedCovariance >  optimalResults.bestNormalizedCovariance
            optimalResults.bestTransform = transforms(maxIndex).T;
            optimalResults.bestNormalizedCovariance = maxNormalizedCovariance;
            optimalResults.t = frame;
            optimalResults.slice = maxIndex;
        end
    end
end
