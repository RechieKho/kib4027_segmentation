function [S, pix] = orthoSlices(A, spacing, idx)
%ORTHOSLICES Axial, coronal and sagittal 2D slices in radiological layout.
%   [S, pix] = orthoSlices(A, spacing, idx) takes a volume and its spacing
%   from toDisplayOrientation and slice indices idx = [i j k]
%   (sagittal, coronal, axial). It returns S.axial, S.coronal, S.sagittal:
%     axial    - anterior at top, patient's right on the image left
%     coronal  - superior at top, patient's right on the image left
%     sagittal - superior at top, anterior on the image left
%   pix.<view> = [rowSpacing colSpacing] in mm. Pass it to showSlice so
%   anisotropic voxels (e.g. 0.4 x 0.4 x 3.3 mm) are not drawn squashed.

[nx, ny, nz] = size(A);

S.axial    = flipud(A(:, :, idx(3)).');
S.coronal  = flipud(reshape(A(:, idx(2), :), nx, nz).');
S.sagittal = fliplr(flipud(reshape(A(idx(1), :, :), ny, nz).'));

pix.axial    = spacing([2 1]);
pix.coronal  = spacing([3 1]);
pix.sagittal = spacing([3 2]);
end
