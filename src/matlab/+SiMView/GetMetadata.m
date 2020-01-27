function [imMetadata, structured] = GetMetadata(rootDir,frame,spmNum)
    if (~exist('frame','var') || isempty(frame))
        frame = 'first';
    end
    if (~exist('spmNum','var') || isempty(spmNum))
        spmNum = 0;
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
    spm = sprintf('SPM%02d',spmNum);
    spmList = dir(fullfile(rootDir,spm));    
    if (~isempty(spmList))
        structured = true;
        if (exist(fullfile(rootDir,spm,'TM00000','ANG000'),'dir'))
            curDlist = dir(fullfile(rootDir,spm,'TM00000','ANG000','*.tif'));
            if (~isempty(curDlist))
                fileType = 'tif';
            else
                curDlist = dir(fullfile(rootDir,spm,'TM00000','ANG000','*.stack'));
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
        spm = '';
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
    xmlFiles = Utils.RecursiveDir(fullfile(rootDir,spm),'xml');
    
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
    elseif (isscalar(frame))
        frameDirs = regexpi({xmlFiles.folder},sprintf('TM%05d',frame-1),'match');
        framesMask = cellfun(@(x)(~isempty(x)),frameDirs);
        frame = find(framesMask,1,'first');
    else
        error('Unknown input for frame');
    end
    
    [~, zStep, mag,dimensions,datasetName] = SiMView.ParseXML(fullfile(xmlFiles(frame).folder,xmlFiles(frame).name));
    if frame == length(xmlFiles) && ~structured && strcmp(fileType,'tif')
        zSlices = Utils.GetNumsFromFiles(rootDir,'PLN(\d+)','tif');
        %TODO: treat stack files
        dimensions(3) = max(zSlices)+1;
    end
    
    for c=unique(chans)
        cMask = chans==c;
        i = find(cMask,1,'first');
        wavelength = SiMView.ParseXML(fullfile(xmlFiles(i).folder,xmlFiles(i).name));
        if ~ismember(wavelength, wavelengths)
            wavelengths = vertcat(wavelengths,wavelength);
            colors = vertcat(colors,colorsStd(c+1,:));
        end
    end
    
    if (~structured)
        frames = Utils.GetNumsFromFiles(rootDir,'TM(\d+)',fileType);
    else
        frames = Utils.GetNumsFromDirs(fullfile(rootDir,'SPM00'),'TM(\d+)');
    end
    
    if (length(wavelengths)==1)
        colors = [1,1,1];
    end
    
    xyPhysicalSize = 6.5 / mag;
    zPhysicalSize = zStep;
    
    numChans = numel(wavelengths);
    numFrames = max(frames) +1;
    numCams = max(cams) +1;
    
    if (numel(unique(chans))>length(wavelengths))
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