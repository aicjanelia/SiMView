function imC = CombineChannelPairs(im,verbose)
    if (~exist('verbose','var') || isempty(verbose))
        verbose = false;
    end
    
    sz = size(im);
    numChannels = size(im,4)/2;
    if (mod(numChannels,1)~=0)
        if (verbose)
            warning('Wrong number of channels to merge');
        end
        imC = im;
        return
    end
    
    imC = zeros([sz(1:3),numChannels,sz(5:6)],'like',im);
    i = 1;
    for c=1:2:size(im,4)
        curIm1 = mat2gray(squeeze(im(:,:,:,c,:,:)));
        curIm2 = mat2gray(squeeze(im(:,:,:,c+1,:,:)));
        mask = curIm1>curIm2;
        curIm = curIm2;
        curIm(mask) = curIm1(mask);
        
        imC(:,:,:,i,:,:) = curIm;
    end
end