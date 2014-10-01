function esvm_run_eval(imgsDir, trainFilesListFpath, ...
        testFilesListFpath, negFolder, varargin)
% imgsDir : path to directory with all images
% testFilesListFpath : path to file with test images, wrt imgsDir
% trainFilesListFpath : path to file with train images, wrt imgsDir

% Use this folder to sync the running of multiple instances of this func

p = inputParser;
addOptional(p, 'sync_folder', 'run_sync'); % set directory to use for syncing processes
addOptional(p, 'cache_models', []); % set to directory path to cache models, else set to 0
addOptional(p, 'res_folder', 'res'); % The folder to save result images
addOptional(p, 'bow_res', '~/projects/001_ESVM/BoW/BoWImageSearch/eval/results/res_with_dist'); % The folder where BoW results might be present
parse(p, varargin{:});

SYNC_FOLDER = p.Results.sync_folder;
if ~exist(SYNC_FOLDER, 'dir')
    mkdir(SYNC_FOLDER);
end
CACHE_DIR = p.Results.cache_models;
if ~isempty(CACHE_DIR) && ~exist(CACHE_DIR, 'dir')
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
    % to remove lock file in case of forced exit or kill
    cleanupObj = onCleanup(@() rmdir(fullfile(SYNC_FOLDER, [test_hash, '.lock'])));

    try
        %% actual computation
        I = imread(fullfile(imgsDir, testFpath));
        % resize, if larger than 640xX
        I = imresize(I, [640, NaN]);
        model_cache_path = fullfile(CACHE_DIR, ['model_' test_hash '.mat']);
        if ~isempty(CACHE_DIR) && exist(model_cache_path, 'file')
            load(model_cache_path);
            fprintf('Read the model from file: %s\n', model_cache_path);
        else
            models = esvm_train_single_exemplar(I, ...
                [1 1 size(I, 2) size(I, 1)], negFolder, ...
                img_id);
            if ~isempty(CACHE_DIR)
                save(model_cache_path, 'models');
            end
        end

        head_trainFile = -1; % search in all imgs in trainFile
        % check if BoW results exist - use those first
        fpath = fullfile(p.Results.bow_res, cls, fname, 'top.txt');
        if exist(fpath, 'file')
            trainFilesListFpath = fpath;
            head_trainFile = 5000; % search in top 5000
        end

        esvm_get_closest_matches(models, imgsDir, trainFilesListFpath, ...
                20, 'res_folder', p.Results.res_folder, ...
                'head_trainFile', head_trainFile);


        mkdir(fullfile(SYNC_FOLDER, [test_hash, '.done']));
    catch e
        fprintf(2, '%s\n', getReport(e));
    end

    try % since it might have been removed 
        rmdir(fullfile(SYNC_FOLDER, [test_hash, '.lock']));
    catch
    end
    clearvars -except testFilesList p SYNC_FOLDER CACHE_DIR ...
            imgsDir trainFilesListFpath testFilesListFpath negFolder;
    close all; % remove all the visualization plots from the memory
    pack; % consolidate all memory
end

