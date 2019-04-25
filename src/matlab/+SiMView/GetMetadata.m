function [imMetadata, structured] = GetMetadata(rootDir,frame)
    if (~exist('frame','var') || isempty(frame))
        frame = 1;
    end

    colorsStd = [0,1,0;1,0,1;0,1,1;1,0,0;1,1,0;0,0,1];
    
    imMetadata = MicroscopeData.GetEmptyMetadata();
    structured = false;
    fileType = 'stack';
    
    if (~exist('rootDir','var') || isempty(rootDir))
        rootDir = uigetdir();
        if (rootDir == 0)
            return
        end
    end
    
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
    xmlFiles = Utils.RecursiveDir(rootDir,'xml');
    
    chans = Utils.GetNumFromStr({xmlFiles.name},'ch(\d)');
    
    if (ischar(frame))
        switch frame
            case 'first'
                frame = 1;
            case 'last'
                frame = length(xmlFiles);
            otherwise
                error('Unknown frame string')
        end
    end
    
    [~, zStep, mag,dimensions,datasetName] = SiMView.ParseXML(fullfile(xmlFiles(frame).folder,xmlFiles(frame).name));
    
    for c=unique(chans)
        cMask = chans==c;
        i = find(cMask,1,'first');
        wavelengths = vertcat(wavelengths,SiMView.ParseXML(fullfile(xmlFiles(i).folder,xmlFiles(i).name)));
        colors = vertcat(colors,colorsStd(c+1,:));
    end
    
    switch fileType
        case 'stack'
            frames = Utils.GetNumsFromFiles(rootDir,'TM(\d+)','stack');
        case 'tif'
            if (~structured)
                frames = Utils.GetNumsFromFiles(rootDir,'TM(\d+)','tif');
            else
                curDlist = dir(fullfile(rootDir,'SPM00','TM*'));
                frames = Utils.GetNumFromStr({curDlist.name},'TM(\d+)');
            end
        otherwise
            error('Malformed directory');
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