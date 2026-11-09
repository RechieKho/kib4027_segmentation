function bw = segmentBladderMethod1(c, params)
%SEGMENTBLADDERMETHOD1 Segmentation technique 1 (Role B).
%   bw = segmentBladderMethod1(c, params) returns a logical bladder mask the
%   same size as c.img. params comes from run_method1.m.
%
%   c is a BladderCase from loadCase (type c. in the editor to see them all):
%     c.id       case id, e.g. "002016"
%     c.img      3-D double T2 volume, native voxel order
%     c.spacing  voxel size in mm, [dx dy dz] along the array dimensions
%     c.info     niftiinfo struct of the image
%     c.labels, c.bladder   ground truth: do NOT use (see rules below)
%
%   Rules for a fair comparison:
%     - use only c.img, c.info and c.spacing as input. c.labels and c.bladder
%       are the ground truth and must NOT be used here.
%     - keep the native voxel order (do not reorient). If you resample,
%       resample the result back to size(c.img) before returning.
%
%   PLACEHOLDER: stage 2 below returns a 25 mm sphere at the centre of the
%   volume. It is NOT a segmentation method; it only lets the pipeline and the
%   evaluation run before your technique is ready. Replace it.

arguments
    c (1,1) BladderCase
    params (1,1) struct
end

%% 1. Preprocessing (e.g. intensity normalisation, bias correction, denoising)
% Intensities are in arbitrary units and differ between scanners, so rescale
% to [0, 1] with the 1st-99th percentile window.
win = intensityWindow(c.img);
I = (c.img - win(1)) / (win(2) - win(1));
I = min(max(I, 0), 1);
I = imgaussfilt3(I, params.smoothSigma);

%% 2. Segmentation (e.g. region growing, active contour, clustering, CNN)
% DUMMY: a sphere in mm (voxels are anisotropic, so use c.spacing).
% A plain global threshold does not work here: fat is brighter than urine in
% many cases. I is unused until you replace this stage.
[r, q, z] = ndgrid(1:size(I, 1), 1:size(I, 2), 1:size(I, 3));
centre = (size(I) + 1) / 2;
distMm = sqrt(((r - centre(1)) * c.spacing(1)).^2 + ...
              ((q - centre(2)) * c.spacing(2)).^2 + ...
              ((z - centre(3)) * c.spacing(3)).^2);
bw = distMm <= 25;

%% 3. Post-processing (e.g. keep the bladder component, fill holes, smooth)
% Keep the largest connected component and fill holes slice by slice.
cc = bwconncomp(bw, 26);
if cc.NumObjects > 1
    [~, kMax] = max(cellfun(@numel, cc.PixelIdxList));
    bw = false(size(bw));
    bw(cc.PixelIdxList{kMax}) = true;
end
for k = 1:size(bw, 3)
    bw(:, :, k) = imfill(bw(:, :, k), 'holes');
end
end
