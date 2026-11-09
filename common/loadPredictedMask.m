function bw = loadPredictedMask(cfg, caseId, methodName)
%LOADPREDICTEDMASK Read a mask saved by savePredictedMask as a logical array.
%   bw = loadPredictedMask(cfg, caseId, methodName)

f = fullfile(cfg.maskDir, methodName, string(caseId) + "_pred.nii");
if ~isfile(f)
    error('loadPredictedMask:missing', 'No mask for case %s from %s (%s).', caseId, methodName, f);
end
bw = niftiread(f) ~= 0;
end
