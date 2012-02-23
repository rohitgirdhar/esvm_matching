function [Ipos,Ineg] = esvm_get_positive_negative_sets(I, bb, negFolder)  
% Generate a dataset using single image and a negative folder 
% (see my_esvm_train_exemplar.m)
% Copyright (C) 2011-12 by Tomasz Malisiewicz (restructured and edited by
% Abhinav Shrivastava)
% All rights reserved.
% 
% This file is part of the Exemplar-SVM library and is made
% available under the terms of the MIT license (see COPYING file).
% Project homepage: https://github.com/quantombone/exemplarsvm


Ipos = cell(1,1);
for i = 1
  if iscell(I)
    Ipos{i}.I = im2double(imread(I{i}));
    recs.filename = I;
  else
    Ipos{i}.I = I;
    recs.filename = '';
  end
  recs.folder = '';
  
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
  object.bbox = bb;
  object.bndbox.xmin =object.bbox(1);
  object.bndbox.ymin =object.bbox(2);
  object.bndbox.xmax =object.bbox(3);
  object.bndbox.ymax =object.bbox(4);
  object.polygon = [];
  recs.objects = [object];
  
  Ipos{i}.recs = recs;
  if 0
      figure(1)
      clf
      imagesc(I)
      plot_bbox(bbs{i});

      pause
  end
end


endings = {'jpg','png','gif','JPEG','JPG', 'jpeg', 'bmp'};
files = cellfun(@(x)dir([negFolder '/*.' x]), endings, 'UniformOutput', ...
    false);
files = cat(1,files{:});
Ineg = cellfun(@(x)[negFolder '/' x],{files.name}, 'UniformOutput', ...
    false);
    
