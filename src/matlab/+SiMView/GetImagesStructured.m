function im = GetImagesStructured(imMetadata,frames,chans,cameras,verbose,spm)
    if (~exist('spm','var') || isempty(spm))
        spm = 0;
    end

    %Assuming uint16... This might be bad.
    im = zeros([imMetadata.Dimensions([2,1,3]),length(chans),length(frames),length(cameras)],'uint16');
    fileList = dir(fullfile(imMetadata.imageDir,sprintf('SPM%02d',spm),sprintf('TM%05d',frames(1)-1),'ANG000'));
    extList = regexpi({fileList.name},'.*\.(.*)','tokens');
    if (any(cellfun(@(x)(strcmpi(x{1},'tif')),extList)))
        ext = 'tif';
    elseif (any(cellfun(@(x)(strcmpi(x{1},'stack')),extList)))
        ext = 'stack';
    end
    
    i = 1;
    prgs = Utils.CmdlnProgress(frames*length(cameras),true);
    for t=1:length(frames)
        fileList = dir(fullfile(imMetadata.imageDir,sprintf('SPM%02d',spm),sprintf('TM%05d',frames(t)-1),'ANG000',['*.',ext]));
        
        dNames = {fileList.name}';
        chanList = Utils.GetNumFromStr(dNames,'CHN(\d+)');
        camList = Utils.GetNumFromStr(dNames,'CM(\d+)');
        plnList = Utils.GetNumFromStr(dNames,'PLN(\d+)');
        
        if (isempty(plnList))
            plnList = ones(size(chanList));
        end
        
        for cm=1:length(cameras)
            camMask = camList==cameras(cm)-1;
            
            for c=1:length(chans)
                chanMask = chanList==chans(c)-1;
                fMask = camMask & chanMask;
                
                if (~all(plnList))
                    for z=1:max(plnList)+1
                        plnMask = z-1==plnList;
                        
                        fMask = fMask & plnMask;
                        if (~any(fMask))
                            continue
                        end
                        
                        curIm = imread(fullfile(fileList(fMask).folder,fileList(fMask).name));
                        if (cm==2)
                            curIm = curIm(:,end:-1:1,:,:);
                        end
                        im(:,:,z,c,t,cm) = curIm;
                    end
                elseif (strcmpi(ext,'tif'))
                    fMask = camMask & chanMask;
                    curIm = MicroscopeData.LoadTif(fullfile(fileList(fMask).folder,fileList(fMask).name));
                    im(:,:,1:size(curIm,3),c,t,cm) = curIm;
                elseif (strcmpi(ext,'stack'))
                    meta = SiMView.GetMetadata(imMetadata.imageDir,t);
                    curIm = MicroscopeData.ReaderRawStack(meta.Dimensions,fullfile(fileList(fMask).folder,fileList(fMask).name),'uint16');
                    im(:,:,1:size(curIm,3),c,t,cm) = curIm;
                else
                    error('Unable to read image %s',fullfile(fileList(fMask).folder,fileList(fMask).name));
                end
            end
            if (verbose)
                prgs.PrintProgress(i);
            end
            i = i+1;
        end
    end
    if (verbose)
        prgs.ClearProgress(true)
    end
end
