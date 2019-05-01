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
    curDlist = [];
    spmList = dir(fullfile(rootDir,'SPM*'));
    if (~isempty(spmList))
        structured = true;
        if (exist(fullfile(rootDir,'SPM00','TM00000','ANG000'),'dir'))
            curDlist = dir(fullfile(rootDir,'SPM00','TM00000','ANG000','*.tif'));
            if (~isempty(curDlist))
                fileType = 'tif';
            else
                curDlist = dir(fullfile(rootDir,'SPM00','TM00000','ANG000','*.stack'));
                if (~isempty(curDlist))
                    fileType = 'stack';
                else
                    error('Unknown filetype');
                end
            end
        else
            error('Unknown directory structure');
        end
    else
        curDlist = dir(fullfile(rootDir,'*.stack'));
        if (~isempty(curDlist))
            fileType = 'stack';
        else
            curDlist = dir(fullfile(rootDir,'*.tif'));
            if (~isempty(curDlist))
                fileType = 'tif';
            else
                error('Unknown filetype');
            end
        end
    end
    
    %% Get metadata from files
    cams = Utils.GetNumFromStr({curDlist.name}','CM(\d+)');
    
    wavelengths = [];
    colors = [];
    if (~structured)
        chans = Utils.GetNumsFromFiles(rootDir,'ch(\d)','xml');
        [~, zStep, mag,dimensions,datasetName] = SiMView.ParseXML(fullfile(rootDir,'ch0.xml'));
    else
        chans = Utils.GetNumsFromFiles(fullfile(rootDir,'SPM00','TM00000','ANG000'),'ch(\d)','xml');
        [~, zStep, mag,dimensions,datasetName] = SiMView.ParseXML(fullfile(rootDir,'SPM00','TM00000','ANG000','ch0.xml'));
    end
    
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