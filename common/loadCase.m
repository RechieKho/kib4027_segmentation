function c = loadCase(cfg, caseId)
%LOADCASE Load one T2 MRI volume, its multi-class mask and the bladder mask.
%   c = loadCase(cfg, caseId) returns a BladderCase with properties
%     id        case id, e.g. "002016"
%     img       T2 volume as double, in the file's native voxel order
%     spacing   voxel size in mm, [dx dy dz] along the array dimensions
%     info      niftiinfo of the image (use it to save predicted masks)
%     labels    multi-class reference mask (uint8), empty if the case has no mask
%     bladder   logical bladder mask (labels == cfg.bladderLabel), empty if no mask
%
%   See BladderCase for details.

c = BladderCase(cfg, caseId);
end
