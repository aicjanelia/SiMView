function ClusterFuseViews(rootDir, transform, channel, frame)
    channel = str2double(channel);
    frame = str2double(frame);
    transform = jsondecode(transform);
    SiMView.FuseViews(rootDir, transform, channel, frame);
end
