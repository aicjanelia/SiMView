function MakeMIPmovie(rootDir,subDirectory,overwrite,separateColors,fps,maxSec)

    writeFiles = false;
    if (~exist('overwrite','var') || isempty(overwrite))
        overwrite = false;
    end
    if (~exist('separateColors','var') || isempty(separateColors))
        separateColors = false;
    end
    dynamicFPS = true;
    if (exist('fps','var') && ~isempty(fps))
        dynamicFPS = false;
    end
    if (~exist('maxSec','var') && ~isempty(maxSec))
        maxSec = inf;
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
    
    if (dynamicFPS)
        fps = min(60,max(imMeta.NumberOfFrames)/10);
        fps = max(fps,7);
        fps = round(fps);
    end
    prefixFPS = sprintf('%s_%dfps_',prefix,fps);
    
    dateDir = regexp(subDirectory, filesep, 'split');
    dateDir = dateDir{1};
    movieDir = fullfile(rootDir,'MIPmovies',dateDir);
    if (~exist(movieDir,'dir'))
        mkdir(movieDir);
    end
    
    maxFrame = imMeta.NumberOfFrames;
    lengthSec = imMeta.NumberOfFrames/fps;
    if (lengthSec>maxSec)
        maxFrame = ceil(fps*maxSec);
    end
    
    if (isempty(maxFrame) || maxFrame<20)
        return
    elseif (~exist(frameDir,'dir'))
        mkdir(frameDir);
        writeFiles = true;
    elseif (overwrite)
        rmdir(frameDir,'s');
        pause(5)
        mkdir(frameDir);
        writeFiles = true;
    elseif (exist(fullfile(movieDir,[prefixFPS,'.mp4']),'file'))
        return
    else
        d = dir(frameDir);
        mask = [d.isdir];
        d = d(~mask);
        if (isempty(d))
            writeFiles = true;
        elseif (dynamicFPS)
            return
        end
    end
    
    tic
    fprintf(1,'Making movie %s...',prefix);
    if (writeFiles)   
%         for t=1:imMeta.NumberOfFrames
        parfor t=1:imMeta.NumberOfFrames
            try
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
            catch err
                warning(err.message)
                fprintf('\n');
                continue
            end
            
            imwrite(imOrtho,fullfile(frameDir,sprintf('%s_%04d.tif',prefix,t)));
        end
        
        if (imMeta.NumberOfFrames<10)
            return
        end
    end

    MovieUtils.MakeMP4_ffmpeg(1,maxFrame,frameDir,fps,[prefix,'_']);
    
    movefile(fullfile(frameDir,[prefix,'_','.mp4']),fullfile(frameDir,[prefixFPS,'.mp4']));

    copyfile(fullfile(frameDir,[prefixFPS,'.mp4']),movieDir);
    fprintf(1,'took %s\n',Utils.PrintTime(toc,imMeta.NumberOfFrames));
end
