function CreateSandboxData(rootDir)
%CreateSandboxData Takes input directory from original clusterPT and
%puts it in desired form
%   Using output generated by Keller's clusterPT, this function rewrites
%   the files with the appropriate dimensions and outputs them into the
%   appropriate directories, eg. LS1CM1, LS1CM2...

%% Get the metadata from the last frame, used to get the max image size
imageMetadata = SiMView.GetMetadataLastFrame(rootDir);

%% Create output directories and write out JSONs/KLBs
% For this dataset, only have two views: LS1CM1 and LS1CM2
viewStrings = {'LS1CM1'; 'LS1CM2'};
for cameraIndex=1:2
    currentViewString = viewStrings{cameraIndex};
    imageMetadata.DatasetName = [imageMetadata.DatasetName '_' currentViewString]; 
    
    % First, write the JSON for each directory
    outputDir = fullfile(rootDir,'Original',currentViewString);
    MicroscopeData.CreateMetadata(outputDir,imageMetadata);
    
    % Read/write KLBs
    currentViewKlbFileStructs = dir(fullfile(rootDir,['*CM0' num2str(cameraIndex-1) '*.klb']));
    parfor i=1:length(currentViewKlbFileStructs)
        % Read KLB
        currentKlbFile = fullfile(currentViewKlbFileStructs(i).folder, currentViewKlbFileStructs(i).name);
        outputImageData = zeros(imageMetadata.Dimensions([2,1,3])); %xyz to rcz
        currentImageData = MicroscopeData.KLB.readKLBstack(currentKlbFile);
        outputImageData(1:size(currentImageData,1), 1:size(currentImageData,2), 1:size(currentImageData,3)) = currentImageData;
        
        % Write KLB
        currentTime = Utils.GetNumFromStr(currentViewKlbFileStructs(i).name, 'TM(\d+)')+1;
        MicroscopeData.WriterKLB(outputImageData, 'path', outputDir, 'imageData', imageMetadata, 'datasetName', imageMetadata.DatasetName, 'chanList',1,'timeRange',[currentTime, currentTime],'filePerT',true,'filePerC',true,'writeJson', false);        
    end
end

