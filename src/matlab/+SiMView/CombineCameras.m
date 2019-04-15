function imC = CombineCameras(im)
    imC = im(:,:,:,:,:,1);
    for cm=2:size(im,6)
        curIm = im(:,:,:,:,:,cm);
        if (mod(cm,2)==0)
            curIm = curIm(:,end:-1:1,:,:,:);
        end
        mask = curIm>imC;
        imC(mask) = curIm(mask);
    end
end
