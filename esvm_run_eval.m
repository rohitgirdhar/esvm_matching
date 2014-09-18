function esvm_run_eval(imgsDir, trainFilesListFpath, ...
        testFilesListFpath, negFolder)
% imgsDir : path to directory with all images
% testFilesListFpath : path to file with test images, wrt imgsDir
% trainFilesListFpath : path to file with train images, wrt imgsDir

% Use this folder to sync the running of multiple instances of this func
SYNC_FOLDER = 'run-sync/';
if ~exist(SYNC_FOLDER, 'dir')
    mkdir(SYNC_FOLDER);
end
CACHE_DIR = 'models-cache';
if ~exist(CACHE_DIR, 'dir')
    mkdir(CACHE_DIR);
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
    % to cleanup in case of forced exit or kill
    cleanupObj = onCleanup(@() rmdir(fullfile(SYNC_FOLDER, [test_hash, '.lock'])));

    try
        %% actual computation
        I = imread(fullfile(imgsDir, testFpath));
        % resize, if larger than 640xX
        I = imresize(I, [640, NaN]);
        model_cache_path = fullfile(CACHE_DIR, ['model_' test_hash '.mat']);
        if exist(model_cache_path, 'file')
            load(model_cache_path);
            fprintf('Read the model from file: %s\n', model_cache_path);
        else
            models = esvm_train_single_exemplar(I, ...
                [1 1 size(I, 2) size(I, 1)], negFolder, img_id);
            save(model_cache_path, 'models');
        end
        esvm_get_closest_matches(models, imgsDir, trainFilesListFpath, 20);
        mkdir(fullfile(SYNC_FOLDER, [test_hash, '.done']));
    catch
    end
    try % since it might have been removed 
        rmdir(fullfile(SYNC_FOLDER, [test_hash, '.lock']));
    catch
    end
end

