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
    
    isStack = true;
    if (~structured)
        dList = dir(fullfile(imMetadata.imageDir,'*.stack'));
        if (~isempty(dList))
            ext = 'stack';
        else
            dList = dir(fullfile(imMetadata.imageDir,'*.tif'));
            ext = 'tif';
            isStack = false;
        end
        
        dNames = {dList.name}';
        [~,frameMask] = Utils.GetNumFromStr(dNames,'TM(\d+)');
        [~,chanMask] = Utils.GetNumFromStr(dNames,'CHN(\d+)');
        [~,camMask] = Utils.GetNumFromStr(dNames,'CM(\d+)');
        if (~isStack)
            [~,plnMask] = Utils.GetNumFromStr(dNames,'PLN(\d+)');
        else
            plnMask = true(size(frameMask));
        end
        
        useFileMask = frameMask & chanMask & camMask & plnMask;
        dList = dList(useFileMask);
        
        dNames = {dList.name}';
        frameList = Utils.GetNumFromStr(dNames,'TM(\d+)');
        chanList = Utils.GetNumFromStr(dNames,'CHN(\d+)');
        camList = Utils.GetNumFromStr(dNames,'CM(\d+)');
        plnList = Utils.GetNumFromStr(dNames,'PLN(\d+)');
        
        if (isempty(plnList))
            plnList = false(size(frameList));
        end
        
        filePath = fullfile(imMetadata.imageDir,dList(1).name);
        
        switch ext
            case 'stack'
                im = MicroscopeData.ReaderRawStack(imMetadata.Dimensions,filePath,imMetadata.PixelFormat);
            case 'tif'
                im = imread(filePath);
            otherwise
                error('Unknown file type');
        end
        
        im = zeros([size(im,1),size(im,2),imMetadata.Dimensions(3),length(chans),length(frames),length(cameras)],'like',im);
        
        for cm=1:length(cameras)
            camMask = camList==cameras(cm)-1;
            for t=1:length(frames)
                frameMask = frameList==frames(t)-1;
                for c=1:length(chans)
                    chanMask = chanList==chans(c)-1;
                    
                    switch ext
                        case 'stack'
                            fMask = frameMask & chanMask & camMask & useFileMask';
                            if (~any(fMask))
                                continue
                            end
                            filePath = fullfile(imMetadata.imageDir,dList(fMask).name);
                            im(:,:,:,c,t,cm) = MicroscopeData.ReaderRawStack(imMetadata.Dimensions,filePath,imMetadata.PixelFormat);
                        case 'tif'
                            for z=1:imMetadata.Dimensions(3)
                                plnMask = plnList==z-1;
                                
                                fMask = frameMask & chanMask & camMask & plnMask;
                                if (~any(fMask))
                                    continue
                                end
                                filePath = fullfile(imMetadata.imageDir,dList(fMask).name);
                                im(:,:,z,c,t,cm) = imread(filePath);
                            end
                        otherwise
                            error('Unknown file type');
                    end
                end
            end
        end
        
    else
        error('TODO deal with sturctured directories');
    end
end
