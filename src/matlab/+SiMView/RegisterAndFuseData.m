function [optimalResults, registrationResults] = RegisterAndFuseData(rootDir, firstNFrames, useECC, rigidOrTranslation, multimodalOrMonomodal, maximumIterations, submit)
    if (~exist('firstNFrames','var'))
        firstNFrames = [];
    end
    if (~exist('useECC','var') || isempty(useECC))
        useECC = true;
        rigidOrTranslation = [];
        multimodalOrMonomodal = [];
        maximumIterations = [];
    end
    if (~exist('rigidOrTranslation','var'))
        rigidOrTranslation = [];
    end
    if (~exist('multimodalOrMonomodal','var'))
        multimodalOrMonomodal = [];
    end
    if (~exist('maximumIterations','var'))
        maximumIterations = [];
    end
    if (~exist('submit','var'))
        submit = true;
    end
    outputDir = fullfile(fileparts(rootDir), 'Processed');
    debugDir = fullfile(fileparts(rootDir), 'Debug');
    imMetadata = SiMView.GetMetadata(fileparts(rootDir), 'last'); %Get overall metadata
    if ~isempty(firstNFrames)
        imMetadata.NumberOfFrames = firstNFrames;
    end
    MicroscopeData.CreateMetadata(outputDir,imMetadata);
    submittedJobNames = {};
    for currentChannel = 1:imMetadata.NumberOfChannels
        %% Get Transforms for Camera Fusion
        fprintf('Calculating registration for channel %d...\n', currentChannel);
        optimalResults = [];
        registrationResults = [];
        if imMetadata.NumberOfCameras>1
            for currentLightsheet = 1:imMetadata.NumberOfLightSheets
                view1Directory = fullfile(rootDir, sprintf('LS%dCM1', currentLightsheet));
                view2Directory = fullfile(rootDir, sprintf('LS%dCM2', currentLightsheet));
                [currentOptimalResults, currentRegistrationResults] = SiMView.GetOptimalRegistrationTransform(view1Directory, view2Directory, currentChannel, useECC, rigidOrTranslation, multimodalOrMonomodal, maximumIterations);
                optimalResults = [optimalResults; currentOptimalResults];
                registrationResults = [registrationResults; currentRegistrationResults];
            end
        end
        fprintf('Finished calculating registration for channel %d.\n', currentChannel);
        [~,bestIndex] = max([optimalResults.bestNormalizedCovariance]);
        bestTransform = optimalResults(bestIndex).bestTransform;
        %% Blend Images
        if submit
            if (~exist(debugDir,'dir'))
                mkdir(debugDir);
            end
            bashScript =  which('run_ClusterFuseViews.sh');
            runCompiledMatlabScript =  which('run_CompiledMatlab.sh');
            fName = sprintf('FuseViews_%s',datetime(datetime,'format','yyyyMMdd_HHmmss'));
            jobName = sprintf('%s_c%d',imMetadata.DatasetName, currentChannel);
            systemCommand = sprintf('bsub -We 15 -J "%s[1-%d]" -n 8 -o %s.o -e %s.e %s %s /usr/local/matlab-2018b/ %s %s %d', jobName, imMetadata.NumberOfFrames, fullfile(debugDir, fName), fullfile(debugDir, fName),...
                runCompiledMatlabScript, bashScript,...
                rootDir, jsonencode(bestTransform), currentChannel);
            system(systemCommand);
            submittedJobNames = [submittedJobNames(:); {jobName}];
        else
            for currentFrame = 1:imMetadata.NumberOfFrames
                SiMView.FuseViews(rootDir, bestTransform, currentChannel, currentFrame);
            end
        end
    end

    if submit
        fprintf('Waiting for registration and fusion jobs to finish...\n');
        pause(5);
        [~, cmdout] = system('bjobs -w');
        while contains(cmdout, submittedJobNames) %wait for it to finish
            pause(5);
            [~, cmdout] = system('bjobs -w');
        end
        fprintf('Registration and fusion finished.\n');
    end
    
    movieDir = fullfile(outputDir, 'movieFrames');
    MovieUtils.MakeMP4_ffmpeg(1,imMetadata.NumberOfFrames,movieDir,15,'c1_'); %TODO This is a hack and should blend colors together
end
