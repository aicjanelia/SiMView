function im = GetImages(imMetadata,structured,frames,chans,cameras,verbose)
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
    if (~exist('verbose','var') || isempty(verbose))
        verbose = false;
    end
    
    if (~structured)
        im = SiMView.GetImagesUnstructured(imMetadata,frames,chans,cameras,verbose);
    else
        im = SiMView.GetImagesStructured(imMetadata,frames,chans,cameras,verbose);
    end
end
