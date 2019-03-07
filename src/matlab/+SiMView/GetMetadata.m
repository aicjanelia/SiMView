function [imMetadata, structured] = GetMetadata(rootDir)
    colorsStd = [0,1,0;1,0,1;0,1,1;1,0,0;1,1,0;0,0,1];
    
    imMetadata = MicroscopeData.GetEmptyMetadata();
    structured = false;
    
    if (~exist('rootDir','var') || isempty(rootDir))
        rootDir = uigetdir();
        if (rootDir == 0)
            return
        end
    end
    
    fileType = 'stack';
    
    %% check for unstructured files in root
    dList = dir(fullfile(rootDir,'*.stack'));
    if (isempty(dList))
        dList = dir(fullfile(rootDir,'*.tif'));
        if (~isempty(dList))
            fileType = 'tif';
        else
            fileType = '';
            structured = true;
        end
        cams = Utils.GetNumsFromFiles(rootDir,'CM(\d+)','tif');
    else
        cams = Utils.GetNumsFromFiles(rootDir,'CM(\d+)','stack');
    end
    
    %% Get metadata from files
    wavelengths = [];
    colors = [];
    if (~structured)
        chans = Utils.GetNumsFromFiles(rootDir,'ch(\d)','xml');
        [~, zStep, mag,dimensions,datasetName] = SiMView.ParseXML(fullfile(rootDir,'ch0.xml'));
        
        for c=unique(chans)
            wavelengths = vertcat(wavelengths,SiMView.ParseXML(fullfile(rootDir,sprintf('ch%d.xml',c))));
            colors = vertcat(colors,colorsStd(c+1,:));
        end
        switch fileType
            case 'stack'
                frames = Utils.GetNumsFromFiles(rootDir,'TM(\d+)','stack');
            case 'tif'
                frames = Utils.GetNumsFromFiles(rootDir,'TM(\d+)','tif');
            otherwise
                error('Malformed directory')
        end
    else
        error('TODO deal with structured data');
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