function [A, spacing] = toDisplayOrientation(V, info)
%TODISPLAYORIENTATION Reorder a volume so its axes point Left, Anterior, Superior.
%   [A, spacing] = toDisplayOrientation(V, info) permutes and flips V using
%   the NIfTI transform in info so that, in A,
%     dim 1 increases towards the patient's Left,
%     dim 2 increases towards Anterior,
%     dim 3 increases towards Superior (RAS+ convention).
%   spacing is the voxel size in mm along the dims of A.
%
%   The volumes in this dataset are stored with the first two axes flipped
%   (and some slightly oblique), so displaying the raw arrays gives rotated or
%   mirrored views. Only nearest-axis reordering is done; there is no
%   resampling, so voxel values are unchanged. Use it for display only.

% MATLAB's affine uses row vectors: [x y z 1] = [i j k 1] * T, so row r of
% T(1:3,1:3) is the world direction of voxel axis r.
M = info.Transform.T(1:3, 1:3);

perm = zeros(1, 3);   % perm(w) = voxel axis that maps to world axis w
flipAxis = false(1, 3);
for r = 1:3
    [~, w] = max(abs(M(r, :)));
    perm(w) = r;
    flipAxis(w) = M(r, w) < 0;
end
if any(perm == 0)
    error('toDisplayOrientation:oblique', 'Could not match voxel axes to world axes.');
end

A = permute(V, perm);
for w = find(flipAxis)
    A = flip(A, w);
end

spacing = double(info.PixelDimensions(perm));
end
