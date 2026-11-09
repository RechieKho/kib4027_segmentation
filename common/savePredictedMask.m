function outFile = savePredictedMask(cfg, c, methodName, bw)
%SAVEPREDICTEDMASK Save a predicted bladder mask in the agreed shared format.
%   outFile = savePredictedMask(cfg, c, methodName, bw) writes
%   results/masks/<methodName>/<caseId>_pred.nii, where c is the BladderCase from
%   loadCase and bw is a logical array the same size as c.img.
%
%   Agreed format (so the evaluation script can read every method the same way):
%     - one NIfTI per test case, named <caseId>_pred.nii
%     - same voxel grid and header as the source image (native voxel order,
%       NOT the display orientation)
%     - uint8, 1 = bladder, 0 = background

arguments
    cfg (1,1) struct
    c (1,1) BladderCase
    methodName (1,1) string
    bw
end
c.checkPrediction(bw);

outDir = fullfile(cfg.maskDir, methodName);
if ~isfolder(outDir), mkdir(outDir); end
outFile = fullfile(outDir, c.id + "_pred.nii");

info = c.info;
info.Datatype = 'uint8';
info.BitsPerPixel = 8;
info.MultiplicativeScaling = 1;
info.AdditiveOffset = 0;
info.Description = sprintf('KIB4027 %s bladder mask', methodName);
niftiwrite(uint8(bw ~= 0), outFile, info);
end
