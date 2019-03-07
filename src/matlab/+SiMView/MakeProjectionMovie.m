function MakeProjectionMovie(rootDir,subPath,datasetName,overwrite,colorTwoSheets)
% rootDir = 'D:\Images\SiMView\Sokol\20181129\HRWtip-Actn4-st13_Embryo1_Run1_OneSheet_Tiff_20181129_112401-ok';
% datasetName = 'HRWtip-Actn4-st13_Embryo1_Run1_OneSheet_Tiff_20181129_112401-ok';
% xyPhysicalSize = 0.325;
% zPhysicalSize = 2.031;

    colorsStd = [0,1,0;1,0,1;0,1,1;1,0,0;1,1,0;0,0,1];
    
    if (~exist('overwrite','var') || isempty(overwrite))
        overwrite = false;
    end
    if (~exist('colorTwoSheets','var') || isempty(colorTwoSheets))
        colorTwoSheets = false;
    end
    
    curRootDir = fullfile(rootDir,subPath);
    isUnstructured = false;
    isStack = false;
    spmDir = [];
    frameDir = [];
    chanDir = [];
    angDirs = [];
    
    dList = dir(fullfile(curRootDir,'*.stack'));
    if (~isempty(dList))
        isUnstructured = true;
        isStack = true;
    else
        dList = dir(fullfile(curRootDir,'*.tif'));
        if (~isempty(dList))
            isUnstructured = true;
        end
    end

    wavelengths = [];
    colors = [];
    if (~isUnstructured)
        [spms,spmDir] = Utils.GetNumsFromDirs(curRootDir,'SPM(\d+)');
        
        if (~isempty(spmDir))
            [frames,frameDir] = Utils.GetNumsFromDirs(fullfile(curRootDir,spmDir(1).name),'TM(\d+)');
        end
        
        if (~isempty(frameDir))
            [chans,chanDir] = Utils.GetNumsFromFiles(fullfile(curRootDir,spmDir(1).name,frameDir(1).name),'ch(\d)','xml');
            
            [~, zStep, mag,dimensions] = SiMView.ParseXML(fullfile(chanDir(1).folder,chanDir(1).name));
            
            for c=unique(chans)
                wavelengths = vertcat(wavelengths,SiMView.ParseXML(fullfile(chanDir(c).folder,chanDir(c).name)));
            end
        end
    else
        if (isStack)
            frames = Utils.GetNumsFromFiles(curRootDir,'TM(\d+)','stack');
        else
            frames = Utils.GetNumsFromFiles(curRootDir,'TM(\d+)','tif');
        end
        chans = Utils.GetNumsFromFiles(curRootDir,'ch(\d)','xml');
        [~, zStep, mag,dimensions] = SiMView.ParseXML(fullfile(curRootDir,'ch0.xml'));
        
        for c=unique(chans)
            wavelengths = vertcat(wavelengths,SiMView.ParseXML(fullfile(curRootDir,sprintf('ch%d.xml',c))));
            colors = vertcat(colors,colorsStd(c+1,:));
        end
    end
    
    if (length(wavelengths)==1)
        colors = [1,1,1];
    end
    
    xyPhysicalSize = 6.5 / mag;
    zPhysicalSize = zStep;

    numChans = max(chans) +1;
    if (~isempty(frameDir))
        [angs, angDirs] = Utils.GetNumsFromDirs(fullfile(curRootDir,spmDir(1).name,frameDir(1).name),'ANG(\d+)');
    end

    prgs = Utils.CmdlnProgress(length(spms)*length(angs)*length(frames),true,sprintf('Making movies for %s',datasetName));
    prgs.PrintProgress(0);
    i = 1;
    for s=1:length(spms)
        sMask = spms==s-1;
        spmPath = fullfile(curRootDir,spmDir(sMask).name);
        for a=1:length(angs)
            aMask = angs==a-1;
            curOutDir = fullfile(spmPath,'movieFrames',angDirs(aMask).name);
            if (~overwrite && exist(curOutDir,'dir'))
                continue
            elseif (exist(curOutDir,'dir'))
                rmdir(curOutDir,'s');
            end
            mkdir(curOutDir);
            fileSuffix = sprintf('%s_SPM%02d_ANG%03d',datasetName,s-1,a-1);

            parfor t=1:max(frames)
%             for t=0:max(frames)-1
                framePath = fullfile(spmPath,frameDir(frames==t).name);
                angPath = fullfile(framePath,angDirs(angs==a-1).name);
                curDir = dir(fullfile(angPath,'*.tif'));

                curChans = Utils.GetNumFromStr({curDir.name}','CHN(\d+)');
                curPlns = Utils.GetNumFromStr({curDir.name}','PLN(\d+)');

                tempIm = imread(fullfile(angPath,curDir(1).name));
                intensityImage = zeros([size(tempIm),numPlanes,numChans],'like',tempIm);

                for c=1:length(chans)
                    chanMask = curChans==chans(c);
                    for z=1:numPlanes
                        plnMask = curPlns==z-1;
                        try
                            intensityImage(:,:,z,c) = imread(fullfile(angPath,curDir(chanMask&plnMask).name));
                        catch err
                            warning(err.message);
                        end
                    end
                end
                imOrtho = ImUtils.MakeOrthoSliceProjections(intensityImage,colors(1:length(chans),:),xyPhysicalSize,zPhysicalSize);
                
                sz = size(imOrtho);
                if (sz(1)>sz(2))
                    imOrtho = imrotate(imOrtho,90);
                end
                imOrtho = imresize(imOrtho,[1080,NaN]);
                imOrtho = ImUtils.MakeImageXYDimEven(imOrtho);

                imwrite(imOrtho,fullfile(curOutDir,sprintf('%s_%04d.tif',fileSuffix,t)));
                prgs.PrintProgress(i);
            end

            if (frames<10)
                continue
            end
            
            fps = min(60,max(frames)/10);
            fps = max(fps,7);
            fps = round(fps);

            MovieUtils.MakeMP4_ffmpeg(1,max(frames),curOutDir,fps,[fileSuffix,'_']);
            copyfile(fullfile(curOutDir,[fileSuffix,'_','.mp4']),fullfile(rootDir,'.'));
        end
    end
    prgs.ClearProgress(true);
end
