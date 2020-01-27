function RestructureData(rootDir, firstNFrames, submit)
%RestructureData takes input directory and reformats the microscope output
%tiffs into KLBs in the appropriate directory structure
%   This function rewrites the files with the appropriate dimensions and
%   outputs them into the appropriate directories, eg. LS1CM1, LS1CM2...
    if (~exist('firstNFrames','var'))
        firstNFrames = [];
    end
    if (~exist('submit','var'))
        submit = true;
    end
    
    %% Get the metadata from the last frame
    spmNums = SiMView.GetSpmIndices(rootDir);
    if isempty(spmNums)
        spmNums = 1;
    end
    
    if ~isempty(firstNFrames)
        imMetadata.NumberOfFrames = firstNFrames;
    end
    
    submittedJobNames = {};
    %% Create output directories and write out JSONs/KLBs
    for s=spmNums
        [imMetadata, structured] = SiMView.GetMetadata(rootDir, 'last',s);
        scopeChannels = 1:imMetadata.NumberOfChannels*imMetadata.NumberOfLightSheets; %CH1LS1, CH1LS2, CH2LS1, CH2LS2,...
        
        for lightsheetIndex = 1:imMetadata.NumberOfLightSheets
            for cameraIndex = 1:imMetadata.NumberOfCameras
                currentImMetadata = rmfield(imMetadata, {'NumberOfCameras', 'NumberOfLightSheets'});
                
                currentViewString = sprintf('LS%dCM%d', lightsheetIndex, cameraIndex);
                currentImMetadata.DatasetName = [imMetadata.DatasetName '_' currentViewString];
                
                % First, write the JSON for each directory
                outputDir = fullfile(rootDir,['Restructured_SPM',num2str(s,'%02d')],currentViewString);
                MicroscopeData.CreateMetadata(outputDir,currentImMetadata);
                
                % Read/write KLBs
                if submit
                    debugDir = fullfile(rootDir, 'Debug');
                    if (~exist(debugDir,'dir'))
                        mkdir(debugDir);
                    end
                    
                    bashScript = which('run_ClusterReadAndWriteRestructuredKLBs.sh');
                    runCompiledMatlabScript =  which('run_CompiledMatlab.sh');
                    
                    jobName = [imMetadata.DatasetName '_' currentViewString];
                    imMetadataFilename = fullfile(debugDir, [jobName '_imMetadata.mat']);
                    currentImMetadataFilename = fullfile(debugDir, [jobName '_currentImMetadata.mat']);
                    
                    save(imMetadataFilename, 'imMetadata');
                    save(currentImMetadataFilename, 'currentImMetadata');
                    
                    startTime = datetime(datetime,'format','yyyyMMdd_HHmmss');
                    logStr = sprintf('ReadAndWriteRestructuredKLBs_%s_%s', currentViewString,startTime);
                    
                    systemCommand = sprintf('bsub -We 5 -J "%s[1-%d]" -n 4 -o %s.o -e %s.e %s %s /usr/local/matlab-2018b/ %s %s %d %d %s %d %s %d',...
                        jobName, imMetadata.NumberOfFrames,...
                        fullfile(debugDir, logStr), fullfile(debugDir, logStr),...
                        runCompiledMatlabScript, bashScript,...
                        imMetadataFilename, currentImMetadataFilename, lightsheetIndex, cameraIndex, jsonencode(scopeChannels), structured, outputDir, s);
                    
                    fprintf('****Running: %s\n****\n',systemCommand);
                    system(systemCommand);
                    
                    submittedJobNames = [submittedJobNames(:); {jobName}];
                else
                    parfor frame=1:imMetadata.NumberOfFrames
                        SiMView.ReadAndWriteRestructuredKLBs(imMetadata, currentImMetadata, lightsheetIndex, cameraIndex, scopeChannels, structured, outputDir, s, frame)
                    end
                end
            end
        end
    end
    
    if submit
        fprintf('Waiting for restructure data jobs to finish...\n');
        pause(5);
        [~, cmdout] = system('bjobs -w');
        while contains(cmdout, submittedJobNames) %wait for it to finish
            pause(5);
            [~, cmdout] = system('bjobs -w');
        end
        fprintf('Restructure data jobs finished.\n');
    end
    
    for s=spmNums
        for lightsheetIndex = 1:imMetadata.NumberOfLightSheets
            for cameraIndex = 1:imMetadata.NumberOfCameras
                currentImMetadata = rmfield(imMetadata, {'NumberOfCameras', 'NumberOfLightSheets'});
                
                currentViewString = sprintf('LS%dCM%d', lightsheetIndex, cameraIndex);
                currentImMetadata.DatasetName = [imMetadata.DatasetName '_' currentViewString];
                
                % First, write the JSON for each directory
                outputDir = fullfile(rootDir,['Restructured_SPM',num2str(s,'%02d')],currentViewString);
                
                if (imMetadata.NumberOfFrames>15)
                    MovieUtils.MakeMP4_ffmpeg(1,imMetadata.NumberOfFrames,fullfile(outputDir,'MovieFrames'),15);
                end
            end
        end
    end
end
