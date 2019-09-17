function spmInd = GetSpmIndices(rootDir)
    spmList = dir(fullfile(rootDir,'SPM*')); 
    spmInd = Utils.GetNumFromStr({spmList.name}','SPM(\d+)');
end
