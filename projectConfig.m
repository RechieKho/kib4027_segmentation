function cfg = projectConfig()
%PROJECTCONFIG Shared paths and conventions for the KIB4027 bladder segmentation project.
%   cfg = projectConfig() returns the folder layout used by every script and
%   adds the shared helper functions (common/) to the MATLAB path.
%
%   Everyone should call this at the top of their scripts instead of
%   hard-coding paths. If your copy of the dataset is somewhere else, either
%   edit cfg.dataDir below or set the environment variable KIB4027_DATA,
%   e.g. setenv('KIB4027_DATA', 'C:\data\dataAndMask').

cfg.root = fileparts(mfilename('fullpath'));

% Folder holding <caseId>_img.nii and <caseId>_mask.nii (lecturer's Drive copy,
% stored in this repo under data/ via Git LFS).
cfg.dataDir = fullfile(cfg.root, 'data', 'dataAndMask');
if ~isempty(getenv('KIB4027_DATA'))
    cfg.dataDir = getenv('KIB4027_DATA');
end

% The reference masks are multi-class; the urinary bladder is label 1.
cfg.bladderLabel = 1;

% Fixed list of test cases used by BOTH methods and the evaluation.
cfg.testCaseFile = fullfile(cfg.root, 'test_cases.csv');

% Outputs
cfg.resultsDir = fullfile(cfg.root, 'results');
cfg.figDir     = fullfile(cfg.resultsDir, 'figures');
cfg.tableDir   = fullfile(cfg.resultsDir, 'tables');
cfg.maskDir    = fullfile(cfg.resultsDir, 'masks');   % masks/<method>/<caseId>_pred.nii

addpath(fullfile(cfg.root, 'common'));
end
