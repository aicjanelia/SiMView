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
    
    outputDir = fullfile(rootDir, 'Processed');
    debugDir = fullfile(rootDir, 'Debug');
    
    [imMetadata,~,spmNums] = SiMView.GetMetadata(rootDir, 'last'); %Get overall metadata and number of spms
    if ~isempty(firstNFrames)
        imMetadata.NumberOfFrames = firstNFrames;
    end
    
    submittedJobNames = {};
    for s=spmNums
        curOutputDir = sprintf('%s_SPM%02d',outputDir,s);
        MicroscopeData.CreateMetadata(curOutputDir,imMetadata);
        restrucName = ['Restructured_SPM',num2str(s,'%02d')];
        
        for currentChannel = 1:imMetadata.NumberOfChannels
            % Get Transforms for Camera Fusion
            fprintf('Calculating registration for channel %d...\n', currentChannel);
            optimalResults = [];
            registrationResults = [];
            
            if imMetadata.NumberOfCameras>1
                for currentLightsheet = 1:imMetadata.NumberOfLightSheets
                    view1Directory = fullfile(rootDir, restrucName, sprintf('LS%dCM1', currentLightsheet));
                    view2Directory = fullfile(rootDir, restrucName, sprintf('LS%dCM2', currentLightsheet));
                    
                    [currentOptimalResults, currentRegistrationResults] = SiMView.GetOptimalRegistrationTransform(view1Directory, view2Directory, currentChannel, useECC, rigidOrTranslation, multimodalOrMonomodal, maximumIterations);
                    
                    optimalResults = [optimalResults; currentOptimalResults];
                    registrationResults = [registrationResults; currentRegistrationResults];
                end
            end
            fprintf('Finished calculating registration for channel %d.\n', currentChannel);
            
            if (~isfield(optimalResults,'bestTransform'))
                warning('Could not register SPM%02d Channel %d in %s', s, currentChannel, rootDir);
                continue
            end
            
            [~,bestIndex] = max([optimalResults.bestNormalizedCovariance]);
            bestTransform = optimalResults(bestIndex).bestTransform;
            
            % Blend Images
            if submit
                if (~exist(debugDir,'dir'))
                    mkdir(debugDir);
                end
                
                bashScript =  which('run_ClusterFuseViews.sh');
                runCompiledMatlabScript =  which('run_CompiledMatlab.sh');
                
                fName = sprintf('FuseViews_spm%02d_%s',s,datetime(datetime,'format','yyyyMMdd_HHmmss'));
                
                jobName = sprintf('%s_c%d_spm%02d',imMetadata.DatasetName, currentChannel,s);
                
                systemCommand = sprintf('bsub -We 15 -J "%s[1-%d]" -n 8 -o %s.o -e %s.e %s %s /usr/local/matlab-2018b/ %s %s %d %d', jobName, imMetadata.NumberOfFrames, fullfile(debugDir, fName), fullfile(debugDir, fName),...
                    runCompiledMatlabScript, bashScript,...
                    fullfile(rootDir,restrucName), jsonencode(bestTransform), currentChannel, s);
                
                fprintf('****Running: %s\n****\n',systemCommand);
                system(systemCommand);
                
                submittedJobNames = [submittedJobNames(:); {jobName}];
            else
                for currentFrame = 1:imMetadata.NumberOfFrames
                    SiMView.FuseViews(fullfile(rootDir,restrucName), bestTransform, currentChannel, s, currentFrame);
                end
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
    
    for s=spmNums
        curOutputDir = sprintf('%s_SPM%02d',outputDir,s);
        movieDir = fullfile(curOutputDir, 'movieFrames');
       
        metadata = MicroscopeData.ReadMetadata(curOutputDir);
        
        for t=1:metadata.NumberOfFrames
            try
                im = imread(fullfile(movieDir,sprintf('c1_%04d.tif',t)));
            catch err
                warning(err.message);
                continue
            end
            
            im = im(:,:,1);
            
            for c=2:metadata.NumberOfChannels
                curIm = imread(fullfile(movieDir,sprintf('c%d_%04d.tif',c,t)));
                im(:,:,c) = curIm(:,:,1);
            end
            
            imC = ImUtils.ColorImages(im,metadata.ChannelColors);
            imwrite(imC,fullfile(movieDir,sprintf('%04d.tif',t)));
        end
        
        if (10 <= metadata.NumberOfFrames)
            fps = min(max(round(metadata.NumberOfFrames/2),5),15);
            MovieUtils.MakeMP4_ffmpeg(1,metadata.NumberOfFrames,movieDir,fps);
            
            dirTok = regexpi(rootDir,filesep,'split');
            mainRoot = '';
            for i=1:length(dirTok)-2
                if (isempty(dirTok{i}))
                    mainRoot = [mainRoot, filesep];
                else
                    mainRoot = fullfile(mainRoot, dirTok{i});
                end
            end
            
            dateStr = dirTok{end-1};
            dataName = dirTok{end};

            if (~exist(fullfile(mainRoot,'movies')))
                mkdir(fullfile(mainRoot,'movies'));
            end
            
            copyfile(fullfile(movieDir,'movieFrames.mp4'),fullfile(mainRoot,'movies',[dateStr,'_',dataName,'_spm',num2str(s,'%02d'),'.mp4']));
        end
    end
end
