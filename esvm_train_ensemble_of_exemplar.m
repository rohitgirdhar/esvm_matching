% DEMO: Training Exemplar-SVMs from a single image
%
% Copyright (C) 2011-12 by Tomasz Malisiewicz 
% (Restructured and edited by Rohit Girdhar)
% All rights reserved. 
%
% This file is part of the Exemplar-SVM library and is made
% available under the terms of the MIT license (see COPYING file).
% Project homepage: https://github.com/quantombone/exemplarsvm
%
function [models] = esvm_train_ensemble_of_exemplar(posFolder, bbsFile, ...
                                                    negFolder)
% Train model for a single image: esvm_train_single_exemplar returns the 
% trained model for given input, trained against the given dataset of 
% images.
% [models]: Trained model
% [posFolder]: Folder path (string) that contains positive images
% [bbsFile]: File containing bounding box of the object of interest for
% each image. Eg, each line of format: 
% image_name : 1 1 cols rows
% (for complete image each bb should be [1 1 size(I,2) size(I,1)] 
% [negFolder]: Folder path (string) that contains negative images

addpath(genpath(pwd))

%% Make Positive and Negative sets 
[pos_set, neg_set] = esvm_get_positive_negative_sets_for_ensemble(...
                        posFolder, bbsFile, negFolder);

models_name = 'image';
%%% TODO(Rohit) : Merge this code with esvm_train_single_exemplar
%% Set exemplar-initialization parameters
params = esvm_get_default_params;
params.init_params.sbin = 8;
params.init_params.MAXDIM = 15;
params.model_type = 'exemplar';

%enable display so that nice visualizations pop up during learning
params.dataset_params.display = 1;

%if localdir is not set, we do not dump files
%params.dataset_params.localdir = '/nfs/baikal/tmalisie/synthetic/';

%%Initialize exemplar stream
stream_params.stream_set_name = 'trainval';
stream_params.stream_max_ex = 10;
stream_params.must_have_seg = 0;
stream_params.must_have_seg_string = '';
stream_params.model_type = 'exemplar'; %must be scene or exemplar
%assign pos_set as variable, because we need it for visualization
stream_params.pos_set = pos_set;
stream_params.cls = '';

%% Get the positive stream
e_stream_set = esvm_get_pascal_stream(stream_params, params.dataset_params);

%% Initialize Exemplars
% Each exemplar will have a figure, where on the first image is
% the exemplar's image, along with the exemplar bounding box and
% HOG grid overlayed.  The second image shows the HOG mask along
% with its offset to the ground-truth bounding box.  The third
% image shows the initial HOG features used to define the exemplar.
initial_models = esvm_initialize_exemplars(e_stream_set, params, ...
                                           models_name);

%% Set exemplar-svm training parameters
train_params = params;
train_params.detect_max_scale = 1.0;
train_params.train_max_mined_images = 10000;
train_params.detect_max_windows_per_exemplar = 400;

%% Perform Exemplar-SVM training
% Because display is turned on, we will show the result of each
% exemplar's training iteration.   Each iteration shows a
% diagnostic first column then the remaining rows are the top
% negative support vectors used to define the exemplar's decision
% boundary.  The diagnostic row shows: exemplar, w's positive
% part, w's negative part, and four mean support vector images,
% where the means are computed with the first 1:N/4, 1:N/2, .. ,
% 1:N support vectors.
[models] = esvm_train_exemplars(initial_models, ...
                                neg_set, train_params);
