function m = computeMetrics(pred, ref, spacing)
%COMPUTEMETRICS Overlap, volume and surface-distance metrics for one case.
%   m = computeMetrics(pred, ref, spacing) compares a predicted mask with the
%   reference mask. pred and ref are logical arrays of the same size, in the
%   same (native) voxel order; spacing = [dx dy dz] in mm (c.spacing).
%
%   Fields of m (one value each):
%     dice           2|P&R| / (|P|+|R|)                       (required by the brief)
%     iou            |P&R| / |P|R|  (Jaccard)                 (required by the brief)
%     sensitivity    |P&R| / |R|    share of the bladder found (low = under-segmentation)
%     precision      |P&R| / |P|    share of the prediction that is bladder (low = leakage)
%     volPred_mL, volRef_mL
%     volDiff_pct    100 (|P|-|R|) / |R|   signed: + over-, - under-segmentation
%     hd95_mm        95th percentile symmetric surface distance (boundary outliers)
%     assd_mm        average symmetric surface distance (mean boundary error)
%   Surface distances are NaN when either mask is empty.
%
%   TEMPLATE: add further metrics here as new fields. run_evaluation.m picks
%   up every field automatically.

arguments
    pred (:,:,:) logical
    ref (:,:,:) logical
    spacing (1,3) double
end
if ~isequal(size(pred), size(ref))
    error('computeMetrics:size', 'pred is %s but ref is %s.', mat2str(size(pred)), mat2str(size(ref)));
end

tp = nnz(pred & ref);
nP = nnz(pred);
nR = nnz(ref);
voxelMl = prod(spacing) / 1000;

m.dice        = safeDivide(2 * tp, nP + nR);
m.iou         = safeDivide(tp, nnz(pred | ref));
m.sensitivity = safeDivide(tp, nR);
m.precision   = safeDivide(tp, nP);
m.volPred_mL  = nP * voxelMl;
m.volRef_mL   = nR * voxelMl;
m.volDiff_pct = 100 * safeDivide(nP - nR, nR);

[m.hd95_mm, m.assd_mm] = surfaceDistances(pred, ref, spacing);
end

function r = safeDivide(a, b)
if b == 0
    r = NaN;
else
    r = a / b;
end
end

function [hd95, assd] = surfaceDistances(A, B, spacing)
% Distances in mm between the boundary voxels of A and B, both directions.
% bwdist assumes cubic voxels, so the nearest boundary point is found
% directly in mm, in chunks to keep memory small.
if ~any(A, 'all') || ~any(B, 'all')
    hd95 = NaN; assd = NaN;
    return
end
pa = boundaryPointsMm(A, spacing);
pb = boundaryPointsMm(B, spacing);
d = [nearestDistance(pa, pb); nearestDistance(pb, pa)];
assd = mean(d);
d = sort(d);
hd95 = interp1(1:numel(d), d, 1 + 0.95 * (numel(d) - 1));   % no Statistics Toolbox needed
end

function p = boundaryPointsMm(bw, spacing)
% Voxels of bw with at least one 6-connected background neighbour.
edge = bw & ~imerode(bw, conndef(3, 'minimal'));
[i, j, k] = ind2sub(size(bw), find(edge));
p = [i, j, k] .* spacing;
end

function d = nearestDistance(from, to)
d = zeros(size(from, 1), 1);
chunk = 2000;
for s = 1:chunk:size(from, 1)
    e = min(s + chunk - 1, size(from, 1));
    D2 = sum(from(s:e, :).^2, 2) + sum(to.^2, 2)' - 2 * from(s:e, :) * to';
    d(s:e) = sqrt(max(min(D2, [], 2), 0));
end
end
