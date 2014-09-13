function esvm_run_eval(imgsDir, testFilesListFpath, ...
        trainFilesListFpath, negFolder)
% imgsDir : path to directory with all images
% testFilesListFpath : path to file with test images, wrt imgsDir
% trainFilesListFpath : path to file with train images, wrt imgsDir

% Use this folder to sync the running of multiple instances of this func
SYNC_FOLDER = 'run-sync/';
if ~exist(SYNC_FOLDER, 'dir')
    mkdir(SYNC_FOLDER);
end
fid = fopen(testFilesListFpath);
testFilesList = textscan(fid, '%s\n');
testFilesList = testFilesList{1};
testFilesList = sort(testFilesList);
fclose(fid);

for i = 1 : numel(testFilesList)
    testFpath = testFilesList{i};
    [path, fname, ~] = fileparts(testFpath);
    [~, cls, ~] = fileparts(path);
    img_id = fullfile(cls, fname);
    fprintf('Doing for %s\n', img_id);

    % check if done, or some other worker doing
    test_hash = [cls, '_', fname];
    if exist(fullfile(SYNC_FOLDER, [test_hash, '.lock']), 'dir') || ...
        exist(fullfile(SYNC_FOLDER, [test_hash, '.done']), 'dir')
      continue;  
    end
    mkdir(fullfile(SYNC_FOLDER, [test_hash, '.lock']));

    %% actual computation
    I = imread(fullfile(imgsDir, testFpath));
    % resize, if larger than 640xX
    I = imresize(I, [640, NaN]);
    models = esvm_train_single_exemplar(I, ...
            [1 1 size(I, 2) size(I, 1)], negFolder, img_id);
    esvm_get_closest_matches(models, imgsDir, trainFilesListFpath, 20);

    rmdir(fullfile(SYNC_FOLDER, [test_hash, '.lock']));
    mkdir(fullfile(SYNC_FOLDER, [test_hash, '.done']));
end

