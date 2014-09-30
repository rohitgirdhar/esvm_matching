function esvm_compute_scores(resultsDir, testSetFpath)
% ESVM_COMPUTE_SCORES takes the results dir and computes various scores on the
% results
%   resultsDir the directory with all top.txt filesi (www dir)
%   testSetFpath the files with all test files
% Eg run : esvm_compute_scores('results/res_vanilla/www', '../../datasets/hussain_hotels/TestSet.txt')

use_queries = 220; % the top this many queries from testSet
fid = fopen(testSetFpath);
testSet = textscan(fid, '%s\n');
fclose(fid);
testSet = sort(testSet{1});
testSet = testSet(1 : use_queries);

mP1 = 0;
mP3 = 0;
mP5 = 0;
mP10 = 0;
mP20 = 0;
any_hit_3 = 0;
any_hit_10 = 0;
for i = 1 : numel(testSet)
    [test_path, test_fname, ~] = fileparts(testSet{i});
    [~, test_class, ~] = fileparts(test_path);
    fpath = fullfile(resultsDir, ['corpus.' test_class '/'  test_fname '-svm'], 'top.txt');
    fid = fopen(fpath);
    matches =  textscan(fid, '%s\n');
    matches = matches{1};
    fclose(fid);
    P1 = computeP(matches, test_class, 1); 
    P3 = computeP(matches, test_class, 3); 
    P5 = computeP(matches, test_class, 5); 
    P10 = computeP(matches, test_class, 10); 
    P20 = computeP(matches, test_class, 20);
    mP1 = mP1 + P1;
    mP3 = mP3 + P3;
    mP5 = mP5 + P5;
    mP10 = mP10 + P10;
    mP20 = mP20 + P20;
    if P3 > 0
        any_hit_3 = any_hit_3 + 1;
    end
    if P10 > 0
        any_hit_10 = any_hit_10 + 1;
    end

end
fprintf('mP1 = %f\n', mP1 / numel(testSet));
fprintf('mP3 = %f\n', mP3 / numel(testSet));
fprintf('mP5 = %f\n', mP5 / numel(testSet));
fprintf('mP10 = %f\n', mP10 / numel(testSet));
fprintf('mP20 = %f\n', mP20 / numel(testSet));
fprintf('at least 1 hit in 3 = %f\n', any_hit_3 / numel(testSet));
fprintf('at least 1 hit in 10 = %f\n', any_hit_10 / numel(testSet));

function P = computeP(matches, cls, n)
cnt = 0;
for i = 1 : min(n, numel(matches))
    [path, ~, ~] = fileparts(matches{i});
    [~, hcls, ~] = fileparts(path);
    if strcmp(hcls, cls)
        cnt = cnt + 1;
    end
end
P = cnt / n;

