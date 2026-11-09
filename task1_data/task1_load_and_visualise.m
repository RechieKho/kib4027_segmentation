%% KIB4027 Assignment - Task 1: Load and visualise the pelvic MRI data
% Role A (Data & Visualisation).
%
% What this script does, following the Task 1 requirements:
%   1. Loads every T2-weighted MRI volume and its multi-class reference mask
%      (niftiinfo/niftiread) and extracts the urinary bladder (label 1).
%   2. Fixes the shared test-case list (test_cases.csv) used by both methods
%      and the evaluation.
%   3. Shows axial, coronal and sagittal views through the bladder for every
%      case, with and without the reference bladder overlay.
%   4. Measures image characteristics and bladder variation (voxel size,
%      field of view, bladder volume, contrast with surrounding tissue,
%      intensity heterogeneity, neighbouring structures, truncation by the
%      field of view) to support the written description in the report.
%
% Outputs (all under matlab/results/):
%   figures/task1/cases/<caseId>_views.png    3 views per case, with/without overlay
%   figures/task1/fig1_label_overview.png     multi-class mask vs extracted bladder
%   figures/task1/fig2_representative.png     cases showing anatomical/image variation
%   figures/task1/fig3_characteristics.png    dataset characteristic plots
%   tables/dataset_characteristics.csv        one row per case
%   tables/dataset_summary.csv                median / IQR / range for the report
%
% Run from anywhere in MATLAB: run('task1_load_and_visualise.m')

clear; close all; clc;

%% Options
saveCaseFigures = true;    % one 3-view figure per case (about 1 minute for 49 cases)
showFigures     = false;   % true opens every figure on screen as well as saving it
shellWidthMm    = 5;       % width of the tissue ring around the bladder used for contrast

%% Paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..'));
cfg = projectConfig();

figDir  = fullfile(cfg.figDir, 'task1');
caseDir = fullfile(figDir, 'cases');
for d = {figDir, caseDir, cfg.tableDir}
    if ~isfolder(d{1}), mkdir(d{1}); end
end
figVisible = matlab.lang.OnOffSwitchState(showFigures);

%% 1. Case list and the fixed test set
cases = listCases(cfg);
fprintf('Found %d image volumes in %s\n', height(cases), cfg.dataDir);

% A case can only be evaluated if it has a reference mask.
inTestSet = double(cases.hasMask);
note = repmat("", height(cases), 1);
note(~cases.hasMask) = "excluded: no reference mask provided";
testCases = [cases(:, {'caseId', 'sitePrefix', 'imageFile', 'maskFile'}), ...
             table(inTestSet, note)];

if isfile(cfg.testCaseFile)
    % The list is fixed once created; only warn if the data folder has changed.
    existing = readTestCases(cfg);
    if ~isequal(sort(existing), sort(testCases.caseId(inTestSet == 1)))
        warning('test_cases.csv no longer matches the data folder. Delete it to regenerate.');
    end
else
    writetable(testCases, cfg.testCaseFile);
    fprintf('Wrote fixed test-case list: %s\n', cfg.testCaseFile);
end
for k = find(~cases.hasMask)'
    fprintf('  Case %s has no mask, so it is excluded from the test set.\n', cases.caseId(k));
end

ids = readTestCases(cfg);
nCases = numel(ids);
fprintf('Test set: %d cases\n\n', nCases);

%% 2. Load every case, measure characteristics and draw the 3 views
rows = cell(nCases, 1);
for n = 1:nCases
    c = loadCase(cfg, ids(n));

    % Reorient (no resampling) so all cases display the same way round.
    [A, sp] = toDisplayOrientation(c.img, c.info);
    B = toDisplayOrientation(c.bladder, c.info);
    L = toDisplayOrientation(c.labels, c.info);
    win = intensityWindow(A);

    r = struct();
    r.caseId      = c.id;
    r.sitePrefix  = extractBefore(c.id, 4);
    r.datatype    = string(c.info.Datatype);
    r.nx = size(A, 1); r.ny = size(A, 2); r.nz = size(A, 3);
    % Rounded so identical protocols group together (headers differ by ~1e-6 mm)
    r.spacingLR_mm = round(sp(1), 3); r.spacingAP_mm = round(sp(2), 3); r.sliceThickness_mm = round(sp(3), 2);
    r.fovLR_mm = r.nx * sp(1); r.fovAP_mm = r.ny * sp(2); r.fovSI_mm = r.nz * sp(3);
    r.labelsPresent = strjoin(string(unique(L(:))'), ' ');

    % Bladder size and extent
    r.bladderVoxels    = nnz(B);
    r.bladderVolume_mL = nnz(B) * prod(sp) / 1000;
    slicesWithBladder  = squeeze(any(B, [1 2]));
    r.bladderSlices    = nnz(slicesWithBladder);
    r.bladderExtentSI_mm = r.bladderSlices * sp(3);
    % Bladder on the top/bottom axial slice means the field of view cuts it off.
    r.cutOffSuperior = slicesWithBladder(end);
    r.cutOffInferior = slicesWithBladder(1);

    % Contrast with a ring of surrounding tissue (in-plane, shellWidthMm wide)
    ringPx = max(1, round(shellWidthMm / sp(1)));
    shell = imdilate(B, strel('disk', ringPx)) & ~B;
    r.bladderMean   = mean(A(B));
    r.surroundMean  = mean(A(shell));
    r.contrastRatio = r.bladderMean / r.surroundMean;   % urine is bright on T2, so > 1 is expected
    r.bladderCV     = std(A(B)) / r.bladderMean;        % heterogeneity inside the bladder
    r.windowLow = win(1); r.windowHigh = win(2);

    % Which other labelled structures touch the bladder ring
    nb = unique(L(shell));
    r.neighbourLabels = strjoin(string(nb(nb ~= 0 & nb ~= cfg.bladderLabel)'), ' ');

    % Slices through the largest bladder cross-section in each direction
    [~, i] = max(squeeze(sum(B, [2 3])));
    [~, j] = max(squeeze(sum(B, [1 3])));
    [~, k] = max(squeeze(sum(B, [1 2])));
    r.sliceSag = i; r.sliceCor = j; r.sliceAx = k;
    rows{n} = r;

    if saveCaseFigures
        [S, pix] = orthoSlices(A, sp, [i j k]);
        M = orthoSlices(B, sp, [i j k]);
        f = figure('Visible', figVisible, 'Color', 'w', 'Position', [100 100 1200 750]);
        tl = tiledlayout(f, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
        views = ["axial", "coronal", "sagittal"];
        sliceNo = [k j i];
        for v = 1:3
            showSlice(nexttile(tl, v), S.(views(v)), pix.(views(v)), win, [], ...
                sprintf('%s (slice %d)', views(v), sliceNo(v)));
            showSlice(nexttile(tl, v + 3), S.(views(v)), pix.(views(v)), win, M.(views(v)), ...
                sprintf('%s + reference bladder', views(v)));
        end
        title(tl, sprintf('Case %s  |  %d\\times%d\\times%d voxels, %.2f\\times%.2f\\times%.2f mm  |  bladder %.0f mL', ...
            c.id, r.nx, r.ny, r.nz, sp(1), sp(2), sp(3), r.bladderVolume_mL));
        exportgraphics(f, fullfile(caseDir, c.id + "_views.png"), 'Resolution', 150);
        if ~showFigures, close(f); end
    end
    fprintf('[%2d/%d] %s  %3dx%3dx%2d  %.2fx%.2fx%.2f mm  bladder %6.1f mL  contrast %.2f\n', ...
        n, nCases, c.id, r.nx, r.ny, r.nz, sp, r.bladderVolume_mL, r.contrastRatio);
end

chars = struct2table([rows{:}]);
writetable(chars, fullfile(cfg.tableDir, 'dataset_characteristics.csv'));

%% 3. Summary statistics for the report's Dataset section
vars = ["spacingLR_mm", "spacingAP_mm", "sliceThickness_mm", "nz", "fovLR_mm", "fovSI_mm", ...
        "bladderVolume_mL", "bladderSlices", "bladderExtentSI_mm", "contrastRatio", "bladderCV"];
summary = table('Size', [numel(vars) 6], ...
    'VariableTypes', ["string", "double", "double", "double", "double", "double"], ...
    'VariableNames', ["measure", "median", "q1", "q3", "min", "max"]);
for v = 1:numel(vars)
    x = chars.(vars(v));
    summary(v, :) = {vars(v), median(x), quantileSorted(x, 0.25), quantileSorted(x, 0.75), min(x), max(x)};
end
writetable(summary, fullfile(cfg.tableDir, 'dataset_summary.csv'));

fprintf('\n=== Dataset summary (%d cases) ===\n', nCases);
disp(summary);
fprintf('Distinct acquisition grids:\n');
disp(groupcounts(chars, {'sitePrefix', 'nx', 'ny', 'sliceThickness_mm'}));
fprintf('Bladder cut off by the field of view: superior (dome) %d cases, inferior %d cases\n', ...
    nnz(chars.cutOffSuperior), nnz(chars.cutOffInferior));
fprintf('Image datatypes: %s\n', strjoin(unique(chars.datatype)', ', '));

%% 4a. Figure 1 - multi-class reference mask and the extracted bladder
c = loadCase(cfg, ids(1));
[A, sp] = toDisplayOrientation(c.img, c.info);
L = toDisplayOrientation(c.labels, c.info);
B = L == cfg.bladderLabel;
win = intensityWindow(A);
k = chars.sliceAx(1); j = chars.sliceCor(1); i = chars.sliceSag(1);
[S, pix] = orthoSlices(A, sp, [i j k]);
SL = orthoSlices(double(L), sp, [i j k]);
SB = orthoSlices(B, sp, [i j k]);
nLab = double(max(L(:)));
% Distinct colours for up to 10 labels (lines() repeats after 7)
palette = [0.00 0.45 0.74; 0.85 0.33 0.10; 0.93 0.69 0.13; 0.49 0.18 0.56; 0.47 0.67 0.19; ...
           0.30 0.75 0.93; 0.64 0.08 0.18; 1.00 0.41 0.71; 0.50 0.50 0.50; 0.00 0.60 0.50];
cmap = palette(1:nLab, :);

% Axes are placed by hand: axial and sagittal slices have very different
% shapes, and tiledlayout's equal-height rows leave large gaps between them.
ax = gridAxes(figVisible, [physAspect(S.axial, pix.axial), physAspect(S.sagittal, pix.sagittal)], 3, 380, 30, 70);
f = ancestor(ax(1), 'figure');
views = ["axial", "sagittal"];
for r = 1:2
    v = views(r);
    showSlice(ax(r, 1), S.(v), pix.(v), win, [], sprintf('%s T2', v));
    grey = rescale(S.(v), 'InputMin', win(1), 'InputMax', win(2));
    imshow(labeloverlay(grey, SL.(v), 'Colormap', cmap, 'Transparency', 0.5), 'Parent', ax(r, 2));
    daspect(ax(r, 2), [1/pix.(v)(2) 1/pix.(v)(1) 1]);
    title(ax(r, 2), sprintf('%s, all %d labels', v, nLab), 'FontWeight', 'normal');
    showSlice(ax(r, 3), S.(v), pix.(v), win, SB.(v), sprintf('%s, bladder (label %d)', v, cfg.bladderLabel));
end
% Label colour key, placed in the right margin so it does not shrink an image
pos = ax(1, 2).Position;
colormap(ax(1, 2), cmap);
clim(ax(1, 2), [0 nLab]);
cb = colorbar(ax(1, 2), 'Ticks', (1:nLab) - 0.5, 'TickLabels', string(1:nLab));
cb.Label.String = 'label (middle column)';
ax(1, 2).Position = pos;
right = ax(1, 3).Position;
cb.Position = [right(1) + right(3) + 0.012, right(2), 0.012, right(4)];
sgtitle(f, sprintf('Case %s: multi-class reference mask and extracted urinary bladder', c.id));
exportgraphics(f, fullfile(figDir, 'fig1_label_overview.png'), 'Resolution', 200);

%% 4b. Figure 2 - representative cases showing variation
[~, pSmall] = min(chars.bladderVolume_mL);
[~, pLarge] = max(chars.bladderVolume_mL);
[~, pLowC]  = min(chars.contrastRatio);
[~, pHet]   = max(chars.bladderCV);
[~, pThick] = max(chars.sliceThickness_mm);
pSite = find(chars.sitePrefix ~= chars.sitePrefix(end), 1);   % one case from the smaller site
picks   = chars.caseId([pSmall; pLarge; pLowC; pHet; pThick; pSite]);
reasons = ["smallest bladder"; "largest bladder"; "lowest contrast"; "most heterogeneous"; ...
           "thickest slices"; "site " + chars.sitePrefix(pSite)];
reasons = reasons(1:numel(picks));
[picks, keep] = unique(picks, 'stable');
reasons = reasons(keep);

nPick = numel(picks);
P = cell(nPick, 1);
for n = 1:nPick
    row = chars(chars.caseId == picks(n), :);
    c = loadCase(cfg, picks(n));
    [A, sp] = toDisplayOrientation(c.img, c.info);
    B = toDisplayOrientation(c.bladder, c.info);
    idx = [row.sliceSag row.sliceCor row.sliceAx];
    [S, pix] = orthoSlices(A, sp, idx);
    P{n} = struct('S', S, 'M', orthoSlices(B, sp, idx), 'pix', pix, 'win', intensityWindow(A), ...
        'sp', sp, 'row', row);
end
aspAx  = max(cellfun(@(q) physAspect(q.S.axial, q.pix.axial), P));
aspSag = max(cellfun(@(q) physAspect(q.S.sagittal, q.pix.sagittal), P));
ax = gridAxes(figVisible, [aspAx aspSag], nPick, 280, 25, [80 40]);
f = ancestor(ax(1), 'figure');
for n = 1:nPick
    q = P{n};
    showSlice(ax(1, n), q.S.axial, q.pix.axial, q.win, q.M.axial, ...
        sprintf('%s: %s\n%.0f mL, contrast %.2f', picks(n), reasons(n), q.row.bladderVolume_mL, q.row.contrastRatio));
    showSlice(ax(2, n), q.S.sagittal, q.pix.sagittal, q.win, q.M.sagittal, ...
        sprintf('sagittal, %.1f mm slices', q.sp(3)));
end
sgtitle(f, 'Variation in bladder size, shape and image appearance (axial and sagittal views)');
exportgraphics(f, fullfile(figDir, 'fig2_representative.png'), 'Resolution', 200);

%% 4c. Figure 3 - dataset characteristics
site = categorical(chars.sitePrefix);
f = figure('Visible', figVisible, 'Color', 'w', 'Position', [100 100 1100 800]);
tl = tiledlayout(f, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

ax = nexttile(tl);
boxchart(ax, site, chars.bladderVolume_mL); hold(ax, 'on');
swarmchart(ax, site, chars.bladderVolume_mL, 18, 'filled', 'MarkerFaceAlpha', 0.6);
xlabel(ax, 'case prefix (site)'); ylabel(ax, 'bladder volume (mL)');
title(ax, '(a) Bladder volume', 'FontWeight', 'normal');

ax = nexttile(tl);
% Many cases share a protocol, so draw one marker per protocol sized by case count.
hold(ax, 'on');
siteNames = categories(site)';
for si = 1:numel(siteNames)
    g = groupcounts(chars(site == siteNames{si}, :), {'spacingLR_mm', 'sliceThickness_mm'});
    scatter(ax, g.spacingLR_mm, g.sliceThickness_mm, 40 + 25 * g.GroupCount, 'filled', ...
        'MarkerFaceAlpha', 0.5, 'DisplayName', "site " + siteNames{si});
    % Offset labels per site so sites sharing a protocol don't overprint
    text(ax, g.spacingLR_mm + 0.04, g.sliceThickness_mm + 0.08 * (1.5 - si), ...
        siteNames{si} + ": n=" + g.GroupCount, 'FontSize', 8, 'HandleVisibility', 'off');
end
xlim(ax, [0.3 1.15]); ylim(ax, [1.8 3.8]);
xlabel(ax, 'in-plane pixel size (mm)'); ylabel(ax, 'slice thickness (mm)');
title(ax, '(b) Voxel size (marker size = number of cases)', 'FontWeight', 'normal');
legend(ax, 'Location', 'northeast');

ax = nexttile(tl);
histogram(ax, chars.contrastRatio, 12);
xlabel(ax, 'bladder / surrounding-tissue mean intensity'); ylabel(ax, 'cases');
title(ax, sprintf('(c) Bladder contrast (%g mm ring)', shellWidthMm), 'FontWeight', 'normal');

ax = nexttile(tl);
[~, order] = sort(chars.bladderVolume_mL);
bar(ax, [chars.bladderSlices(order), chars.nz(order) - chars.bladderSlices(order)], 'stacked');
xlabel(ax, 'cases, sorted by bladder volume'); ylabel(ax, 'axial slices');
legend(ax, {'with bladder', 'without bladder'}, 'Location', 'northwest');
title(ax, '(d) Axial slices containing bladder', 'FontWeight', 'normal');

title(tl, sprintf('Dataset characteristics (%d cases)', nCases));
exportgraphics(f, fullfile(figDir, 'fig3_characteristics.png'), 'Resolution', 200);

fprintf('\nFigures saved to %s\nTables saved to %s\n', figDir, cfg.tableDir);

%% Local functions
function ax = gridAxes(visible, rowAspect, nCols, colW, gap, titleH)
% Figure with a grid of axes whose row heights follow the image shapes.
%   rowAspect(r) = height/width of the images in row r (physical, in mm),
%   colW = column width in pixels, gap = spacing in pixels, titleH = room
%   for axes titles (scalar or one value per row). Returns ax(row, col).
nRows = numel(rowAspect);
if isscalar(titleH), titleH = repmat(titleH, 1, nRows); end
topH = 40;                                 % room for sgtitle
rightPad = 70;                             % room for a colorbar
h = colW * rowAspect;
figW = nCols * colW + (nCols + 1) * gap + rightPad;
figH = topH + sum(h) + sum(titleH) + gap * nRows;
f = figure('Visible', visible, 'Color', 'w', 'Units', 'pixels', 'Position', [50 50 figW figH]);
ax = gobjects(nRows, nCols);
y = figH - topH;
for r = 1:nRows
    y = y - titleH(r) - h(r);
    for cc = 1:nCols
        x = gap + (cc - 1) * (colW + gap);
        ax(r, cc) = axes(f, 'Units', 'pixels', 'Position', [x y colW h(r)]);
    end
    y = y - gap;
end
set(ax, 'Units', 'normalized');
end

function a = physAspect(img, pix)
% Physical height/width of a displayed slice.
a = (size(img, 1) * pix(1)) / (size(img, 2) * pix(2));
end

function q = quantileSorted(x, p)
% Quantile by linear interpolation (avoids needing the Statistics Toolbox).
x = sort(x(~isnan(x)));
pos = 1 + p * (numel(x) - 1);
q = interp1(1:numel(x), x, pos);
end
