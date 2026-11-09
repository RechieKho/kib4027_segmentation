function T = listCases(cfg)
%LISTCASES Table of every case in the data folder and whether it has a mask.
%   T = listCases(cfg) scans cfg.dataDir for <caseId>_img.nii files and
%   returns one row per case with columns caseId, sitePrefix, imageFile,
%   maskFile and hasMask. Rows are sorted by caseId.

files = dir(fullfile(cfg.dataDir, '*_img.nii'));
if isempty(files)
    error('listCases:noData', 'No *_img.nii files found in %s. Check cfg.dataDir.', cfg.dataDir);
end

caseId = erase(string({files.name})', "_img.nii");
caseId = sort(caseId);
imageFile = caseId + "_img.nii";
maskFile  = caseId + "_mask.nii";
hasMask = arrayfun(@(f) isfile(fullfile(cfg.dataDir, f)), maskFile);

% The first three digits group the cases (001xxx vs 002xxx), most likely by
% source institution in the original Zenodo dataset.
sitePrefix = extractBefore(caseId, 4);

T = table(caseId, sitePrefix, imageFile, maskFile, hasMask);
end
