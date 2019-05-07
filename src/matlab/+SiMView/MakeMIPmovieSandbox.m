function MakeMIPmovieSandbox(rootDir,subDirectory,overwrite,separateColors,fps,maxSec)

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
    if (~exist('maxSec','var') || isempty(maxSec))
        maxSec = inf;
    end
    
    views = dir(fullfile(rootDir, 'LS*'));
    views = views([views.isdir]);
    
    imMetaFile = dir(fullfile(rootDir, views(1).name, '*.json')); %Take metadata from first view
    imMeta = jsondecode( fileread(fullfile(imMetaFile.folder, imMetaFile.name)) );
    pos = regexp(imMeta.DatasetName,'_');
    klbFilePrefix = imMeta.DatasetName(1:pos(end)-1);

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
    
    dateDir = datestr(now,'yyyymmdd');
    movieDir = fullfile(rootDir,'MIPmovies',dateDir);
    if (~exist(movieDir,'dir'))
        mkdir(movieDir);
    end
    
    maxFrame = imMeta.NumberOfFrames;
    lengthSec = imMeta.NumberOfFrames/fps;
    if (lengthSec>maxSec)
        maxFrame = ceil(fps*maxSec);
    end
    
    if (~exist(frameDir,'dir'))
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
                intensityImage = zeros(imMeta.Dimensions(2), imMeta.Dimensions(1), imMeta.Dimensions(3), imMeta.NumberOfChannels, 1, imMeta.NumberOfCameras);
                for viewIndex = 1:numel(views)
                    currentView = views(viewIndex).name;
                    camera = Utils.GetNumFromStr(currentView,'CM(\d+)');
                    klbFileName = fullfile(rootDir,currentView, sprintf('%s_%s_c%01d_t%04d.klb',klbFilePrefix,currentView,1,t));
                    if camera == 1
                        intensityImage(:,:,:,1,1,camera) = MicroscopeData.KLB.readKLBstack(klbFileName);
                    else
                        intensityImage(:,end:-1:1,:,1,1,camera) = MicroscopeData.KLB.readKLBstack(klbFileName);
                    end
                end
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
