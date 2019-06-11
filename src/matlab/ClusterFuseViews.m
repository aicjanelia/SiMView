function ClusterFuseViews(rootDir, transform, channel, frame)
channel = str2num(channel);
frame = str2num(frame);
transform = jsondecode(transform);
SiMView.FuseViews(rootDir, transform, channel, frame);