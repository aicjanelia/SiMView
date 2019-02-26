function MakeMoviesFromRoot(root,subPath,overwrite)
    if (~exist('overwrite','var') || isempty(overwrite))
        overwrite = false;
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
    
    if (any(cellfun(@(x)(~isempty(x)),regexp(subDirs,'movieFrames'))))
        return
    end
    
    if (all(~strcmp(subDirs,'SPM00')) && all(~strcmpi(subDirs,'Processed')))
        for i=1:length(subDirs)
            subSub = fullfile(subPath,subDirs{i});
            SiMView.MakeMoviesFromRoot(root,subSub,overwrite);
        end
    else
        [~,name] = fileparts(subPath);
        try
            SiMView.MakeProjectionMovie(root,subPath,name,overwrite);
        catch err
            warning(err.message)
        end
    end
end
