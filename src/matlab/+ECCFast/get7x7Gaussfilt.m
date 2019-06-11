function [filt] = get7x7Gaussfilt()
% This function creates a gauss filter of size 7x7 by hard coded memory (
% much faster ). 
filt = reshape([1.43507364523366e-16;3.16096005597678e-12;
    1.27522230166144e-09;9.42268912558384e-09;1.27522230166144e-09;
    3.16096005597678e-12;1.43507364523366e-16;3.16096005597678e-12;
    6.96247785517228e-08;2.80886404083204e-05;0.000207548539719770;
    2.80886404083204e-05;6.96247785517228e-08;3.16096005597678e-12;
    1.27522230166144e-09;2.80886404083204e-05;0.0113317663107800;
    0.0837310569703257;0.0113317663107800;2.80886404083204e-05;
    1.27522230166144e-09;9.42268912558384e-09;0.000207548539719770;
    0.0837310569703257;0.618693477176495;0.0837310569703257;
    0.000207548539719770;9.42268912558384e-09;1.27522230166144e-09;
    2.80886404083204e-05;0.0113317663107800;0.0837310569703257;
    0.0113317663107800;2.80886404083204e-05;1.27522230166144e-09;
    3.16096005597678e-12;6.96247785517228e-08;2.80886404083204e-05;
    0.000207548539719770;2.80886404083204e-05;6.96247785517228e-08;
    3.16096005597678e-12;1.43507364523366e-16;3.16096005597678e-12;
    1.27522230166144e-09;9.42268912558384e-09;1.27522230166144e-09;
    3.16096005597678e-12;1.43507364523366e-16],7,7);
end