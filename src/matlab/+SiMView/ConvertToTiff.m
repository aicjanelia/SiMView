function ConvertToTiff(rootDir,numT,numC)

%     rootDir = 'N:\Heddleston\SiMView\Sokol\20181204\HRWtip-actn4-Shr3-st9_albino_Embryo4_Run1_OneSheet_TIFF_20181204_160527\Processed\sub_background\SPM00';

    %% figure these thing out automaticly
%     numT = 180;
%     numC = 2;
    numAng = 1;
    prefix = 'SPM00';

    %%
    outDir = rootDir;

    prgs = Utils.CmdlnProgress(numT,true,'Converting to Tiff');
   parfor t=0:numT-1
        timeDir = sprintf('TM%06d',t);
        for c=0:numC-1
            fName = fullfile(rootDir,timeDir,sprintf('%s_%s_ANG%03d_CM00_CHN%02d.filtered_100.klb',prefix,timeDir,numAng-1,c));
            try
                im = MicroscopeData.KLB.readKLBstack(fName);
                MicroscopeData.Tiff_(im,prefix,outDir,c,[t,t],false,false);
            catch err
                warning(err.message);
            end
        end
        prgs.PrintProgress(t+1)
    end
    prgs.ClearProgress(true);
end
