function imC = CombineCameras(im)

    if (size(im,6)==1)
        imC = im;
        return
    end
    
    sz = size(im);
    imC = zeros(sz(1:5),'single');
    for cm=1:size(im,6)
        curIm = mat2gray(im(:,:,:,:,:,cm));
        mask = curIm>imC;
        imC(mask) = curIm(mask);
    end
end