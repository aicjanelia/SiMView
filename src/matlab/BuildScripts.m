currentDirectory = fileparts(mfilename('fullpath'));
binDirectory = fullfile(fileparts(fileparts(currentDirectory)), 'bin');
if (~exist(binDirectory,'dir'))
    mkdir(binDirectory);
end
eval(sprintf('mcc -m -R -nodesktop -v ClusterReadAndWriteRestructuredKLBs.m -d %s', binDirectory));
eval(sprintf('mcc -m -R -nodesktop -v ClusterFuseViews.m -d %s', binDirectory));