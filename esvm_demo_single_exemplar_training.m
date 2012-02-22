
%Input query image
I = im2double(imread('./images/eiffel_tower.jpg'));

%Bounding-box of region-of-interest (which is usually entire images in case
%of full image matching and object bounding-box in case of detection tasks.
bb = [1 1 size(I, 2) size(I, 1)];

%Folder that contains our negative image or rather dataset images that are
%random images from web.
negFolder = '/home/abhinav/images/datasetImages/sampleDataset/';

%esvm_train_single_exemplar returns the trained model for given input,
%trained against the given dataset of images.
models = esvm_train_single_exemplar(I, bb, negFolder);

