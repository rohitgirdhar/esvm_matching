function [Ipos,Ineg] = esvm_get_positive_negative_sets_for_ensemble(posFolder, ...
                            bbsFile, negFolder)  
% Generate a dataset using positive folder and a negative folder
% Copyright (C) 2011-12 by Tomasz Malisiewicz
% (restructured and edited by Rohit Girdhar)
% All rights reserved.
% @posFolder : folder path with the corpus
% @bbsFile : (optional, can specify [])
%            File containing bounding box of the object of interest for
%            each image. Eg, each line of format: 
%            image_name : 1 1 cols rows
% (for complete image each bb should be [1 1 size(I,2) size(I,1)]
% (defaults)
% @negFolder: folder with negative random images
%
% See esvm_train_ensemble_of_exemplar.m
%
% This file is part of the Exemplar-SVM library and is made
% available under the terms of the MIT license (see COPYING file).
% Project homepage: https://github.com/quantombone/exemplarsvm

try
    bbsFin = fopen(bbsFile);
    bbs = textscan(bbsFin, '%s : %f %f %f %f\n');
    % create a dictionary lookup for bounding boxes from file
    names2bb = containers.Map;
    for i = 1 : size(bbs{1}, 1)
        names2bb(char(bbs{1}(i))) = [bbs{2}(i) bbs{3}(i) bbs{4}(i) bbs{5}(i)];
    end
    fclose(bbsFin);
catch
end

endings = {'jpg','png','gif','JPEG','JPG', 'jpeg', 'bmp'};
posFiles = cellfun2(@(x)dir([posFolder '/*.' x]), endings);
posFiles = cat(1,posFiles{:});

Ipos = cell(1, size(posFiles, 1));
for i = 1 : size(posFiles, 1)
    imgFName = char(posFiles(i).name);
    I = im2double(imread(fullfile(posFolder, imgFName)));
    Ipos{i}.I = I;
    recs.filename = imgFName;
    recs.folder = posFolder;
    recs.source = '';
    [recs.size.width,recs.size.height,recs.size.depth] = size(I);
    recs.segmented = 0;
    recs.imgname = sprintf('%08d',i);
    recs.imgsize = size(I);
    recs.database = '';
    
    object.class = 'circle';
    object.view = '';
    object.truncated = 0;
    object.occluded = 0;
    object.difficult = 0;
    object.label = 'circle';
    try
        object.bbox = names2bb(imgFName);
    catch
        object.bbox = [ 1 1 size(I, 2) size(I, 1)];
    end
    object.bndbox.xmin =object.bbox(1);
    object.bndbox.ymin =object.bbox(2);
    object.bndbox.xmax =object.bbox(3);
    object.bndbox.ymax =object.bbox(4);
    object.polygon = [];
    recs.objects = object;
    
    Ipos{i}.recs = recs;
    if 0 % set = 1 for testing!!
        figure(1)
        clf
        imagesc(I)
        plot_bbox(object.bbox);
        pause
    end
end


files = cellfun(@(x)dir([negFolder '/*.' x]), endings, 'UniformOutput', ...
    false);
files = cat(1,files{:});
Ineg = cellfun(@(x)[negFolder '/' x],{files.name}, 'UniformOutput', ...
    false);

