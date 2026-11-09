function c = loadCase(cfg, caseId)
%LOADCASE Load one T2 MRI volume, its multi-class mask and the bladder mask.
%   c = loadCase(cfg, caseId) returns a struct with fields
%     id        case id, e.g. "002016"
%     img       T2 volume as double, in the file's native voxel order
%     labels    multi-class reference mask (uint8), [] if the case has no mask
%     bladder   logical bladder mask (labels == cfg.bladderLabel), [] if no mask
%     info      niftiinfo of the image (use it to save predicted masks)
%     spacing   voxel size in mm, [dx dy dz] along the array dimensions
%
%   Arrays stay in native voxel order so predicted masks line up with the
%   reference masks voxel for voxel. Use toDisplayOrientation only for figures.

caseId = string(caseId);
imgFile  = fullfile(cfg.dataDir, caseId + "_img.nii");
maskFile = fullfile(cfg.dataDir, caseId + "_mask.nii");

c.id = caseId;
c.info = niftiinfo(imgFile);
% Image datatypes differ between cases (int16, uint16, single, double),
% so convert everything to double.
c.img = double(niftiread(c.info));
c.spacing = double(c.info.PixelDimensions(1:3));

if isfile(maskFile)
    labels = niftiread(maskFile);
    if ~isequal(size(labels), size(c.img))
        error('loadCase:sizeMismatch', 'Case %s: image %s and mask %s differ in size.', ...
            caseId, mat2str(size(c.img)), mat2str(size(labels)));
    end
    c.labels = uint8(round(labels));     % some masks are stored as single
    c.bladder = c.labels == cfg.bladderLabel;
else
    c.labels = [];
    c.bladder = [];
end
end
