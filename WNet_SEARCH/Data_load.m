clear 
clc
format long

%% data read

filepath = 'data/EUV';
win_size = 10

d = dir(fullfile(filepath, '*.hdf'));

size(d,1)
kX = zeros(size(d,1)-1, floor(1600/win_size), floor(3200/win_size));
%idx = ceil(size(d, 1)*rand(100, 1));
%X = zeros(size(idx, 1), floor(1600/win_size), floor(3200/win_size));
parfor i = 1:size(d, 1)-1
	  [map,p,sl] = read_hdf4_map_data(fullfile(filepath, d(i).name));
          i
          [n,m]=size(map);
          a1=reshape(downsample(map, win_size),[],m);
          out=reshape(downsample(a1',win_size),[],size(a1,1))';
          X(i,:,:) = out;
    
end

save('EUV_test_large.mat', 'X', '-v7.3')
