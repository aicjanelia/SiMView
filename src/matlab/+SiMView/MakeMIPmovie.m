function MakeMIPmovie(rootDir,subDirectory,overwrite,separateColors)

    if (~exist('overwrite','var') || isempty(overwrite))
        overwrite = false;
    end
    if (~exist('separateColors','var') || isempty(separateColors))
        separateColors = false;
    end

    [imMeta,structured] = SiMView.GetMetadata(fullfile(rootDir,subDirectory));
    
    if (separateColors && imMeta.NumberOfLightSheets<2 && imMeta.NumberOfCameras<2)
        return
    end

    colorsStd = [0,1,0;1,0,1;0,1,1;1,0,0;1,1,0;0,0,1];
    
    pos = regexp(subDirectory,filesep);
    prefix = subDirectory;
    prefix(pos) = '_';
    frameDir = fullfile(rootDir,subDirectory,'movieFrames');
    if (separateColors)
        prefix = [prefix,'_sepColors'];
        frameDir = [frameDir,'_sepColors'];
    end

    if (~exist(frameDir,'dir'))
        mkdir(frameDir);
    elseif (overwrite)
        rmdir(frameDir,'s');
        pause(5)
        mkdir(frameDir);
    else
        return
    end

    fprintf(1,'Making movie %s...',prefix);
    tic
    parfor t=1:imMeta.NumberOfFrames
        intensityImage = SiMView.GetImages(imMeta,structured,t);
        if(separateColors)
            curIm = intensityImage(:,:,:,1,:,1);
            for cm = 2:size(intensityImage,6)
                curIm = cat(4,curIm,intensityImage(:,:,:,1,:,cm));
            end
        else
            curIm = SiMView.CombineChannelPairs(intensityImage);
            curIm = SiMView.CombineCameras(curIm);
        end

        if (size(curIm,4)==1)
            colors = [1,1,1];
        else
            colors = colorsStd(1:size(curIm,4),:);
        end

        imOrtho = ImUtils.MakeOrthoSliceProjections(curIm,colors,imMeta.PixelPhysicalSize(1),imMeta.PixelPhysicalSize(3));

        sz = size(imOrtho);
        if (sz(1)>sz(2))
            imOrtho = imrotate(imOrtho,90);
        end
        imOrtho = imresize(imOrtho,[1080,NaN]);
        imOrtho = ImUtils.MakeImageXYDimEven(imOrtho);

        imwrite(imOrtho,fullfile(frameDir,sprintf('%s_%04d.tif',prefix,t)));
    end

    if (imMeta.NumberOfFrames<10)
        return
    end

    fps = min(60,max(imMeta.NumberOfFrames)/10);
    fps = max(fps,7);
    fps = round(fps);

    MovieUtils.MakeMP4_ffmpeg(1,imMeta.NumberOfFrames,frameDir,fps,[prefix,'_']);

    movieDir = fullfile(rootDir,'MIPmovies');
    if (~exist(movieDir,'dir'))
        mkdir(movieDir);
    end

    copyfile(fullfile(frameDir,[prefix,'_','.mp4']),movieDir);
    fprintf(1,'took %s\n',Utils.PrintTime(toc));
end
