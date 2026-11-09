function win = intensityWindow(V, pLow, pHigh)
%INTENSITYWINDOW Display window from intensity percentiles of a volume.
%   win = intensityWindow(V) returns [p1 p99] of the non-zero voxels of V.
%   MRI intensities have arbitrary units and a few very bright voxels, so a
%   min-max window makes most slices look dark.
%   win = intensityWindow(V, pLow, pHigh) uses other percentiles (0-100).

if nargin < 2, pLow = 1; end
if nargin < 3, pHigh = 99; end

v = sort(V(V ~= 0));
if isempty(v)
    win = [0 1];
    return
end
n = numel(v);
win = [v(max(1, round(pLow/100 * n))), v(max(1, round(pHigh/100 * n)))];
if win(2) <= win(1)
    win(2) = win(1) + 1;
end
end
