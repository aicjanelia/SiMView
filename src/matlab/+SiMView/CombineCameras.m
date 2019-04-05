function imC = CombineCameras(im)

    if (size(im,6)==1)
        imC = im;
        return
    end
    
    sz = size(im);
    imC = zeros(sz(1:5),'like',im);
    for cm=1:size(im,6)
        curIm = im(:,:,:,:,:,cm);
        mask = curIm>imC;
        imC(mask) = curIm(mask);
    end
end