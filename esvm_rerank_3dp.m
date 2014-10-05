function esvm_rerank_3dp(test_struct, models, test_fpaths, ...
    q_fpath, topk, params)
addpath('3DP');
% takes result_struct output from esvm_pool_exemplar_dets as input (test_struct)
% uses 3D information from David's 3DP code to compute error in 3D normals
% in the scene

CACHE_FILES = 0;
if ~isempty(params.dataset_params.localdir)
    CACHE_FILES = 1;
end
if ~exist('set_name','var')
  set_name = 'corpus';
end

wwwdir = sprintf('%s/www/%s.%s%s/',params.dataset_params.localdir, ...
        set_name, models{1}.models_name, test_struct.calib_string);
if ~exist(wwwdir,'dir') && (CACHE_FILES == 1)
    mkdir(wwwdir);
end

fid = -1;
if CACHE_FILES == 1
    out_fpath = fullfile(wwwdir, '3dp_scores.txt');
    fid = fopen(out_fpath, 'w');
    fprintf('Writing output to %s\n', out_fpath);
end

final_boxes = test_struct.unclipped_boxes;
bbs = cat(1, final_boxes{:});
[~, bb] = sort(bbs(:, end), 'descend');
ranked_bbs = bbs(bb, :);

qMap = compute3DMap(q_fpath, 'sparse');
if isempty(qMap)
    return;
end
% resize the qMap to image size
qMap = imresize(qMap, [models{1}.sizeI(1), models{1}.sizeI(2)]);
% extract the bounding box
bbox = models{1}.gt_box;
qMap = qMap(bbox(2) : min(bbox(2) + bbox(4), size(qMap, 1)), ...
            bbox(1) : min(bbox(1) + bbox(3), size(qMap, 2)), :);

for i = 1 : min(size(ranked_bbs, 1), topk)
    cur_box = bbs(i, :);
    t_fpath = test_fpaths{cur_box(11)};
    tMap = compute3DMap(t_fpath, 'sparse');
    if isempty(tMap)
        continue;
    end
    % clip out the bbox
    tMap = tMap(max(round(bbs(i, 2)), 1) : min(round(bbs(i, 4)), size(tMap, 1)), ...
                max(round(bbs(i, 1)), 1) : min(round(bbs(i, 3)), size(tMap, 2)), :);
    tMapNorm = sum(tMap .^ 2, 3);
    tMapN = bsxfun(@rdivide, tMap, tMapNorm + eps);
    tMask = tMapNorm > eps;
    
    % might need to clip the query HoG
    
    
    qTemp = imresize(qMap, [cur_box(4) - cur_box(2), ...
                            cur_box(3) - cur_box(1)]);
    if cur_box(7) == 1 % flipped
        qTemp = flip_image(qTemp);
    end
    if cur_box(2) < 0 % rows
        qTemp = qTemp(-floor(cur_box(2)) : end, :, :);
    end
    if cur_box(1) < 0 % columns
        qTemp = qTemp(:, -floor(cur_box(1)) : end, :);
    end
    % all this might make the arrays different in sizes by a pixel here and
    % there, simply imresize it
    qTemp = imresize(qTemp, [size(tMapN, 1), size(tMapN, 2)]);
    
    qTempNorm = sum(qTemp .^ 2, 3);
    qTempN = bsxfun(@rdivide, qTemp, qTempNorm + eps);
    qMask = qTempNorm > eps;
    
    dprod = sum(qTempN .* tMapN, 3);
    mask = tMask .* qMask;
    dprod(dprod > 1 | dprod < -1) = 1; % give 0 error here
    errMap = acosd(dprod) .* mask;
    fprintf(fid, '%s : %f\n', t_fpath, mean(errMap(:)));

    %% plot the images
    imwrite(qMap, fullfile(wwwdir, sprintf('%05d_3d_query.jpg', i)));
    imwrite(tMap, fullfile(wwwdir, sprintf('%05d_3d_match.jpg', i)));
    imwrite(mat2gray(errMap), fullfile(wwwdir, sprintf('%05d_3d_err.jpg', i)));
end
fclose(fid);

