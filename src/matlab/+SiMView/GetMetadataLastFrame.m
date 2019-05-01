function [imMetadata, structured] = GetMetadataLastFrame(rootDir)
    colorsStd = [0,1,0;1,0,1;0,1,1;1,0,0;1,1,0;0,0,1];
    
    imMetadata = MicroscopeData.GetEmptyMetadata();
    structured = false;
    
    if (~exist('rootDir','var') || isempty(rootDir))
        rootDir = uigetdir();
        if (rootDir == 0)
            return
        end
    end
            
    %% Get metadata from files    
    cams = Utils.GetNumsFromFiles(rootDir,'CM(\d+)','klb');
    
    wavelengths = [];
    colors = [];
    
    xmlFilenameStructs = Utils.RecursiveDir(rootDir, 'xml');
    xmlFilenames = {xmlFilenameStructs.name};
    frames = Utils.GetNumFromStr(xmlFilenames,'TM(\d+)');
    lastFrame = max(frames);
    lastFrameNames = xmlFilenames(frames == lastFrame);
    chans = Utils.GetNumFromStr(xmlFilenames,'CHN(\d)');

    [~, zStep, mag,dimensions,datasetName] = SiMView.ParseXML(fullfile(rootDir,lastFrameNames{1}));
    
    for i=1:length(lastFrameNames)
        wavelengths = vertcat(wavelengths,SiMView.ParseXML(fullfile(rootDir,lastFrameNames{i})));
        colors = vertcat(colors,colorsStd(i+1,:));
%        colors = vertcat(colors,colorsStd(c+1,:));
    end
    
    if (length(wavelengths)==1)
        colors = [1,1,1];
    end
    
    xyPhysicalSize = 6.5 / mag;
    zPhysicalSize = zStep;
    
    numChans = max(chans) +1;
    numFrames = max(frames) +1;
    numCams = max(cams) +1;
    
    if (numChans>length(wavelengths))
        numSheets = 2;
    else
        numSheets = 1;
    end
    
    pos = regexpi(datasetName,' ');
    datasetName(pos) = '_';
    
    %% set output
    imMetadata.ChannelColors =  colors;
    imMetadata.ChannelNames = wavelengths;
    imMetadata.Dimensions = dimensions;
    imMetadata.NumberOfChannels = numChans;
    imMetadata.NumberOfFrames = numFrames;
    imMetadata.PixelPhysicalSize = [xyPhysicalSize,xyPhysicalSize,zPhysicalSize];
    imMetadata.PixelFormat = 'uint16';
    imMetadata.DatasetName = datasetName;
    imMetadata.imageDir = rootDir;
    imMetadata.NumberOfCameras = numCams;
    imMetadata.NumberOfLightSheets = numSheets;
end