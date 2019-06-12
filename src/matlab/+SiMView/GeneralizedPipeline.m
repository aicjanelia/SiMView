function  GeneralizedPipeline(rootDir, firstNFrames, useECC, rigidOrTranslation, multimodalOrMonomodal, maximumIterations, submit)
if (~exist('useECC','var') || isempty(useECC))
    useECC = true;
    rigidOrTranslation = [];
    multimodalOrMonomodal = [];
    maximumIterations = [];
end
if (~exist('firstNFrames','var'))
    firstNFrames = [];
end
if (~exist('rigidOrTranslation','var'))
    rigidOrTranslation = [];
end
if (~exist('multimodalOrMonomodal','var'))
    multimodalOrMonomodal = [];
end
if (~exist('maximumIterations','var'))
    maximumIterations = [];
end
if (~exist('submit','var'))
    submit = true;
end

SiMView.RestructureData(rootDir, firstNFrames, submit);
SiMView.RegisterAndFuseData(fullfile(rootDir,'Restructured'), firstNFrames, useECC, rigidOrTranslation, multimodalOrMonomodal, maximumIterations, submit);

    outputDir = fullfile(fileparts(rootDir), 'Processed');
    metadata = MicroscopeData.ReadMetadata(outputDir);
    movieDir = fullfile(outputDir, 'movieFrames');
    MovieUtils.MakeMP4_ffmpeg(1,metadata.NumberOfFrames,movieDir,15,'c1_');
end
