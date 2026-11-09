function ids = readTestCases(cfg)
%READTESTCASES Case ids in the fixed test set (test_cases.csv, inTestSet = 1).
%   ids = readTestCases(cfg) returns a string column, e.g. ["001000"; ...].
%   Both segmentation methods and the evaluation must loop over exactly these
%   cases so the comparison is fair.

if ~isfile(cfg.testCaseFile)
    error('readTestCases:missing', '%s not found. Run task1_data/task1_load_and_visualise.m first.', cfg.testCaseFile);
end
opts = detectImportOptions(cfg.testCaseFile, 'TextType', 'string');
opts = setvartype(opts, {'caseId', 'sitePrefix'}, 'string');   % keep leading zeros
T = readtable(cfg.testCaseFile, opts);
ids = T.caseId(T.inTestSet == 1);
end
