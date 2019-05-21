function [im,metaData] = GetData(rootDir,frames,chans,cameras,verbose)
    [metaData, structured] = SiMView.GetMetadata(rootDir);
    
    if (~exist('frames','var') || isempty(frames))
        frames = 1:metaData.NumberOfFrames;
    end
    if (~exist('chans','var') || isempty(chans))
        chans = 1:metaData.NumberOfChannels;
    end
    if (~exist('cameras','var') || isempty(cameras))
        cameras = 1:metaData.NumberOfCameras;
    end
    if (~exist('verbose','var') || isempty(verbose))
        verbose = false;
    end
    
    im = SiMView.GetImages(metaData,structured,frames,chans,cameras,verbose);
end
