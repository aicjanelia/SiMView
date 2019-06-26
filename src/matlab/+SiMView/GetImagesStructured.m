function im = GetImagesStructured(imMetadata,frames,chans,cameras,verbose)
    %Assuming uint16... This might be bad.
    im = zeros([imMetadata.Dimensions([2,1,3]),length(chans),length(frames),length(cameras)],'uint16');
    ext = 'tif'; %deal with non-tif data
    
    i = 1;
    for t=1:length(frames)
        fileList = dir(fullfile(imMetadata.imageDir,'SPM00',sprintf('TM%05d',frames(t)-1),'ANG000',['*.',ext]));
        
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
                for z=1:max(plnList)+1
                    plnMask = z-1==plnList;
                    
                    fMask = camMask & chanMask & plnMask;
                    if (~any(fMask))
                        continue
                    end
                    
                    if (strcmpi(ext,'tif'))
                        curIm = imread(fullfile(fileList(fMask).folder,fileList(fMask).name));
                        if (cm==2)
                            curIm = curIm(:,end:-1:1,:,:);
                        end
                        im(:,:,z,c,t,cm) = curIm;
                    else
                        %TODO
                    end
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
