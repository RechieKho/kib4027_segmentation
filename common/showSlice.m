function showSlice(ax, img, pix, win, mask, ttl)
%SHOWSLICE Draw one MRI slice with true physical proportions.
%   showSlice(ax, img, pix, win) draws img in axes ax using the intensity
%   window win = [low high], with pixel size pix = [rowSpacing colSpacing] mm.
%   showSlice(ax, img, pix, win, mask) also overlays a logical mask as a
%   translucent fill with an outline. showSlice(..., ttl) sets a title.

if nargin < 5, mask = []; end
if nargin < 6, ttl = ''; end

grey = rescale(img, 'InputMin', win(1), 'InputMax', win(2));
if isempty(mask) || ~any(mask(:))
    imshow(grey, 'Parent', ax);
else
    imshow(labeloverlay(grey, mask, 'Colormap', [1 0.85 0], 'Transparency', 0.6), 'Parent', ax);
    hold(ax, 'on');
    visboundaries(ax, mask, 'Color', [1 0.85 0], 'LineWidth', 0.75, 'EnhanceVisibility', false);
    hold(ax, 'off');
end

% One column is pix(2) mm wide and one row is pix(1) mm tall.
daspect(ax, [1/pix(2) 1/pix(1) 1]);
if ~isempty(ttl)
    title(ax, ttl, 'FontWeight', 'normal', 'Interpreter', 'none');
end
end
