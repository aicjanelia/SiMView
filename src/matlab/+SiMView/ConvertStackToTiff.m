function ConvertStackToTiff(rootDir)
    if (~exist('rootDir','var') || isempty(rootDir))
        rootDir = uigetdir();
        if (rootDir == 0)
            return
        end
    end
    
    subDir = 'tifFiles';
    if (exist(fullfile(rootDir,subDir),'dir'))
        d = dir(fullfile(rootDir,subDir));
        d = d(~[d.isdir]);
        if (~isempty(d))
            return
        end
    else
        mkdir(fullfile(rootDir,subDir));
    end

    [imMeta,structured] = SiMView.GetMetadata(rootDir);
    fprintf('%s...',imMeta.DatasetName);
    tic
    i=0;
    
    if (imMeta.Dimensions(3)==1)
        im = SiMView.GetImages(imMeta,structured,1,1,1);
        for cm=1:imMeta.NumberOfCameras
            for ls=1:imMeta.NumberOfLightSheets
                for c=1:imMeta.NumberOfChannels
                    im = zeros([imMeta.Dimensions(2),imMeta.Dimensions(1),imMeta.NumberOfFrames],'like',im);
                    parfor t=1:imMeta.NumberOfFrames
                        im(:,:,t) = SiMView.GetImages(imMeta,structured,t,c,cm);
                    end
                    fName = sprintf('%s_ls%d_cm%d',imMeta.DatasetName,ls,cm);
                    MicroscopeData.Tiff_(im,fName,fullfile(rootDir,subDir),c,[1,1],false);
                end
            end
        end
    else
        for cm=1:imMeta.NumberOfCameras
            for ls=1:imMeta.NumberOfLightSheets
                for c=1:imMeta.NumberOfChannels
                    parfor t=1:imMeta.NumberOfFrames
                        im = SiMView.GetImages(imMeta,structured,t,c,cm);
                        fName = sprintf('%s_ls%d_cm%d',imMeta.DatasetName,ls,cm);
                        MicroscopeData.Tiff_(im,fName,fullfile(rootDir,subDir),c,[t,t],false,false);
                    end
                    i = i +imMeta.NumberOfFrames;
                end
            end
        end
    end

    fprintf('%s\n',Utils.PrintTime(toc,i));
end
