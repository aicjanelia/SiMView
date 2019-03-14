function ConvertStackToTiffFromRoot(root,subPath)
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
    
    if (all(~strcmp(subDirs,'SPM00')) && all(~strcmpi(subDirs,'Processed')))
        for i=1:length(subDirs)
            subSub = fullfile(subPath,subDirs{i});
            SiMView.ConvertStackToTiffFromRoot(root,subSub);
        end
    else
        try
            SiMView.ConvertStackToTiff(fullfile(root,subPath));
        catch err
            warning(err.message)
        end
    end
end