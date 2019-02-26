function MakeMIPmovieRoot(root,subPath,overwrite,separateColors)

    if (~exist('overwrite','var') || isempty(overwrite))
        overwrite = false;
    end
    if (~exist('separateColors','var') || isempty(separateColors))
        separateColors = false;
    end
    if (~exist('root','var') || isempty(root))
        root = uigetdir();
        if (root==0)
            return
        end
    end
    if (~exist('subPath','var'))
        subPath = '';
    end

    dList = dir(fullfile(root,subPath));
    dList = dList([dList.isdir]);
    subDirs = {dList.name};
    subDirs = subDirs(~cellfun(@(x)(strcmp(x,'.') || strcmp(x,'..')),subDirs));
    if (isempty(subDirs))
        return
    end
    
    frameDir = 'movieFrames';
    if (separateColors)
        frameDir = [frameDir,'_sepColors'];
    end
    
    if (any(cellfun(@(x)(~isempty(x)),regexp(subDirs,frameDir))) && ~overwrite)
        return
    end
    
    dList = dir(fullfile(root,subPath,'ch0.xml'));
    
    if (isempty(dList))
        for i=1:length(subDirs)
            subSub = fullfile(subPath,subDirs{i});
            SiMView.MakeMIPmovieRoot(root,subSub,overwrite,separateColors);
        end
    else
        try
            SiMView.MakeMIPmovie(root,subPath,overwrite,separateColors);
        catch err
            warning(err.message)
        end
    end
end
