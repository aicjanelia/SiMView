function ClusterFuseViews(rootDir, transform, channel, spm, frame)
    channel = str2double(channel);
    frame = str2double(frame);
    transform = jsondecode(transform);
    spm = str2double(spm);
    
    SiMView.FuseViews(rootDir, transform, channel, spm, frame);
end
