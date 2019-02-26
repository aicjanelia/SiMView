function im = GetImages(imMetadata,structured,frames,chans,cameras)
    if (~exist('imMetadata','var') || isempty(imMetadata) || ~exist('structured','var') || isempty(structured))        
        rootDir = uigetdir();
        if (rootDir==0)
            im = [];
            return
        end
        [imMetadata, structured] = SiMView.GetMetadata(rootDir);
    end
    if (~exist('frames','var') || isempty(frames))
        frames = 1:imMetadata.NumberOfFrames;
    end
    if (~exist('chans','var') || isempty(chans))
        chans = 1:imMetadata.NumberOfChannels;
    end
    if (~exist('cameras','var') || isempty(cameras))
        cameras = 1:imMetadata.NumberOfCameras;
    end
    
    if (~structured)
        dList = dir(fullfile(imMetadata.imageDir,'*.stack'));
        if (~isempty(dList))
            ext = 'stack';
        else
            ext = 'tif';
        end
        [frameList,dList] = Utils.GetNumsFromFiles(imMetadata.imageDir,'TM(\d+)',ext);
        chanList = Utils.GetNumsFromFiles(imMetadata.imageDir,'CHN(\d+)',ext);
        camList = Utils.GetNumsFromFiles(imMetadata.imageDir,'CM(\d+)',ext);
        
        frameMask = frameList==frames(1)-1;
        chanMask = chanList==chans(1)-1;
        camMask = camList==cameras(1)-1;
        
        filePath = fullfile(imMetadata.imageDir,dList(frameMask & chanMask & camMask).name);
        
        switch ext
            case 'stack'
                im = MicroscopeData.ReaderRawStack(imMetadata.Dimensions,filePath,imMetadata.PixelFormat);
            case 'tif'
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % TODO
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            otherwise
                error('Unknown file type');
        end
        
        im = zeros([size(im),length(chans),length(frames),length(cameras)],'like',im);
        
        for cm=1:length(cameras)
            for t=1:length(frames)
                for c=1:length(chans)
                    
                    frameMask = frameList==frames(t)-1;
                    chanMask = chanList==chans(c)-1;
                    camMask = camList==cameras(cm)-1;
                    
                    filePath = fullfile(imMetadata.imageDir,dList(frameMask & chanMask & camMask).name);
                    
                    switch ext
                        case 'stack'
                            im(:,:,:,c,t,cm) = MicroscopeData.ReaderRawStack(imMetadata.Dimensions,filePath,imMetadata.PixelFormat);
                        case 'tif'
                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            % TODO
                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        otherwise
                            error('Unknown file type');
                    end
                end
            end
        end
        
    else
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % TODO
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
end
