%% KIB4027 Assignment - Task 2: Segmentation technique 2
% Role C (Segmentation Method 2).
%
% TEMPLATE: this script is the driver. It already loops over the fixed test
% cases, saves masks in the shared format and records the run time, so you
% only need to change segmentBladderMethod2.m (and the parameters below).
%
% The segmentation inside segmentBladderMethod2.m is a PLACEHOLDER (a dummy
% sphere) so the pipeline runs end to end. Replace it with your technique.
%
% Outputs (all under matlab/results/):
%   masks/method2/<caseId>_pred.nii      one predicted mask per test case
%   tables/method2_runtime.csv           seconds per case (useful for the comparison)
%
% Run from anywhere in MATLAB: run('run_method2.m')

clear; close all; clc;

%% Method settings: put every tunable parameter here so it is easy to report
methodName = 'method2';         % folder name under results/masks/, do not change
params = struct();
params.smoothSigma = 1;         % Gaussian smoothing (voxels), placeholder
% params.yourParameter = ...;

%% Paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..'));
cfg = projectConfig();
addpath(here);

%% Run on every test case (the same cases as method 1, for a fair comparison)
ids = readTestCases(cfg);
n = numel(ids);
runtime = zeros(n, 1);
sanityDice = nan(n, 1);

for i = 1:n
    c = loadCase(cfg, ids(i));

    tic;
    bw = segmentBladderMethod2(c, params);   % <-- your technique
    runtime(i) = toc;

    savePredictedMask(cfg, c, methodName, bw);

    % Quick check while developing only. The real evaluation is Role D's job.
    sanityDice(i) = 2 * nnz(bw & c.bladder) / (nnz(bw) + nnz(c.bladder));
    fprintf('%2d/%d  %s  %.1f s  Dice %.3f\n', i, n, c.id, runtime(i), sanityDice(i));
end

%% Save run time
if ~isfolder(cfg.tableDir), mkdir(cfg.tableDir); end
T = table(ids(:), runtime, 'VariableNames', {'caseId', 'runtime_s'});
writetable(T, fullfile(cfg.tableDir, [methodName '_runtime.csv']));
fprintf('\nDone: %d masks in %s\nMedian Dice (sanity check) %.3f\n', ...
    n, fullfile(cfg.maskDir, methodName), median(sanityDice, 'omitnan'));
