function esvm_run_eval_clip(imgsDir, trainFilesListFpath, ...
        testFilesListFpath, negFolder)
% imgsDir : path to directory with all images
% testFilesListFpath : path to file with test images, wrt imgsDir
% trainFilesListFpath : path to file with train images, wrt imgsDir

% Use this folder to sync the running of multiple instances of this func
SYNC_FOLDER = 'run_syncs/sync_people_occ2/';
if ~exist(SYNC_FOLDER, 'dir')
    mkdir(SYNC_FOLDER);
end
CACHE_DIR = 'caches/models-people_occ2';
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
    % to remove lock file in case of forced exit or kill
    cleanupObj = onCleanup(@() rmdir(fullfile(SYNC_FOLDER, [test_hash, '.lock'])));

    masks_dir = fullfile(imgsDir, '../', 'masks');
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

            [t_path, t_fname, t_ext] = fileparts(testFpath);
            M = im2bw(imread(fullfile(masks_dir, ...
                            t_path, ['mask_', t_fname, t_ext])));
            models = esvm_train_single_exemplar(I, ...
                [1 1 size(I, 2) size(I, 1)], negFolder, ...
                img_id, 'mask_img', M);
            save(model_cache_path, 'models');
            out_dir = ['results/res_people_occ2/www/corpus.', img_id, '-svm'];
            mkdir(out_dir);
            imwrite(M, fullfile(out_dir, 'mask.jpg'));
        end
        esvm_get_closest_matches(models, imgsDir, trainFilesListFpath, ...
                21, 'res_folder', 'results/res_people_occ2');
        mkdir(fullfile(SYNC_FOLDER, [test_hash, '.done']));
    catch
    end
    try % since it might have been removed 
        rmdir(fullfile(SYNC_FOLDER, [test_hash, '.lock']));
    catch
    end
end

function mask = genRandomMask(wd, ht)
mask = ones(ht, wd);
x = floor(rand * wd / 2);
y = floor(rand * ht / 2);
w = floor(min(wd / 4 + rand * wd / 2, wd - x));
h = floor(min(ht / 4 + rand * ht / 2, ht - y));
mask(y : y + h, x : x + w) = 0;

function mask = genScaledMask(wd, ht, i)
mask = ones(ht, wd);
scale = 1.5;
block_ht = 0.4 * ht * (scale ^ i);
block_wd = 0.3 * wd * (scale ^ i);
mask(max(0, floor(end - block_ht)) : end, ...
        max(0, floor(wd / 2 - block_wd / 2)) : ...
            min(end, floor(wd / 2 + block_wd / 2))) = 0;

