%% KIB4027 Assignment - Tasks 3 and 4: Evaluation and error analysis
% Role D (Evaluation & Analysis).
%
% TEMPLATE: compares the predicted masks of every method with the reference
% bladder on exactly the test cases in test_cases.csv. It already produces
% the tables and figures below; adapt the settings, add metrics in
% computeMetrics.m, and add your own plots in section 5.
%
% Until methods 1 and 2 are implemented their masks are the same dummy
% sphere, so both methods score the same and the paired test gives NaN.
%
% Outputs (all under matlab/results/):
%   tables/metrics.csv                one row per case per method (all metrics)
%   tables/metrics_summary.csv        n, mean, SD, median, IQR, range per method and metric
%   tables/metrics_paired.csv         paired comparison (method 2 vs method 1) per metric
%   figures/evaluation/fig_metrics.png              Dice, IoU, HD95 per method (paired)
%   figures/evaluation/fig_dice_vs_characteristics.png   Dice vs bladder volume, contrast, truncated dome
%   figures/evaluation/errors/<caseId>_errors.png   error maps (TP / FP / FN) for selected cases
%
% Run from anywhere in MATLAB: run('run_evaluation.m')

clear; close all; clc;

%% Settings
methods      = ["method1", "method2"];      % folders under results/masks/
methodLabels = ["Method 1", "Method 2"];    % rename to the technique names for the report
methodColors = [0.000 0.514 0.000;          % #008300 green
                0.910 0.482 0.643];         % #e87ba4 magenta
methodMarkers = ["o", "^"];                 % second cue, so colour is never the only one
showFigures  = false;                       % true also opens the figures on screen

% Metrics where a smaller value is better (used for "which method wins")
lowerIsBetter = ["hd95_mm", "assd_mm"];

%% Paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..'));
cfg = projectConfig();
addpath(here);

figDir = fullfile(cfg.figDir, 'evaluation');
errDir = fullfile(figDir, 'errors');
for d = {figDir, errDir, cfg.tableDir}
    if ~isfolder(d{1}), mkdir(d{1}); end
end
figVisible = matlab.lang.OnOffSwitchState(showFigures);

%% 1. Check every method has a mask for every test case (fair comparison)
ids = readTestCases(cfg);
nCases = numel(ids);
nMethods = numel(methods);
for k = 1:nMethods
    files = fullfile(cfg.maskDir, methods(k), ids + "_pred.nii");
    missing = ids(~isfile(files));
    if ~isempty(missing)
        error('run_evaluation:missingMasks', '%s is missing %d of %d masks (e.g. %s). Run run_%s.m first.', ...
            methods(k), numel(missing), nCases, missing(1), methods(k));
    end
end
fprintf('Evaluating %d methods on %d test cases\n', nMethods, nCases);

%% 2. Metrics per case and method
rows = cell(nCases, nMethods);
for n = 1:nCases
    c = loadCase(cfg, ids(n));
    for k = 1:nMethods
        bw = loadPredictedMask(cfg, c.id, methods(k));
        m = computeMetrics(bw, c.bladder, c.spacing);
        rows{n, k} = mergeStructs(struct('caseId', c.id, 'method', methods(k)), m);
    end
    fprintf('%2d/%d  %s\n', n, nCases, c.id);
end
rows = rows';                                     % order: case, then method
T = struct2table(vertcat(rows{:}));
writetable(T, fullfile(cfg.tableDir, 'metrics.csv'));

metricNames = string(T.Properties.VariableNames(3:end));

%% 3. Statistical summary per method and metric
S = table();
for mName = metricNames
    for k = 1:nMethods
        x = T.(mName)(T.method == methods(k));
        x = x(~isnan(x));
        S = [S; table(mName, methods(k), numel(x), mean(x), std(x), median(x), ...
            quantileSorted(x, 0.25), quantileSorted(x, 0.75), min(x), max(x), ...
            'VariableNames', {'metric', 'method', 'n', 'mean', 'sd', 'median', 'q1', 'q3', 'min', 'max'})]; %#ok<AGROW>
    end
end
writetable(S, fullfile(cfg.tableDir, 'metrics_summary.csv'));

%% 4. Paired comparison: method 2 vs method 1 on the same cases
% Wilcoxon signed-rank test (paired, no normality assumption). Implemented
% below because the Statistics Toolbox (signrank) is not available.
P = table();
for mName = metricNames
    x1 = T.(mName)(T.method == methods(1));
    x2 = T.(mName)(T.method == methods(2));
    ok = ~isnan(x1) & ~isnan(x2);
    d = x2(ok) - x1(ok);
    if ismember(mName, lowerIsBetter), better2 = d < 0; else, better2 = d > 0; end
    P = [P; table(mName, nnz(ok), median(d), nnz(better2), nnz(d == 0), signedRankP(d), ...
        'VariableNames', {'metric', 'nPairs', 'medianDiff_2minus1', 'nMethod2Better', 'nTies', 'pWilcoxon'})]; %#ok<AGROW>
end
writetable(P, fullfile(cfg.tableDir, 'metrics_paired.csv'));

fprintf('\n%-12s', 'metric');
fprintf('%22s', methodLabels + " median [IQR]");
fprintf('%12s\n', 'p (paired)');
for mName = ["dice", "iou", "hd95_mm"]
    fprintf('%-12s', mName);
    for k = 1:nMethods
        s = S(S.metric == mName & S.method == methods(k), :);
        fprintf('%22s', sprintf('%.3f [%.3f-%.3f]', s.median, s.q1, s.q3));
    end
    fprintf('%12.3g\n', P.pWilcoxon(P.metric == mName));
end

%% 5. Figures
% 5a. Distribution per method, with grey lines joining the same case
plotMetrics = ["dice", "iou", "hd95_mm"];
plotTitles  = ["Dice", "IoU", "HD95 (mm)"];
f = figure('Visible', figVisible, 'Color', 'w', 'Position', [100 100 1100 420]);
tl = tiledlayout(f, 1, numel(plotMetrics), 'TileSpacing', 'compact', 'Padding', 'compact');
rng(0);                                            % same jitter every run
jitter = (rand(nCases, 1) - 0.5) * 0.25;
for p = 1:numel(plotMetrics)
    ax = nexttile(tl); hold(ax, 'on');
    Y = reshape(T.(plotMetrics(p)), nMethods, nCases)';   % cases x methods
    plot(ax, (1:nMethods) + jitter, Y, '-', 'Color', [0.82 0.82 0.82], 'LineWidth', 0.5, ...
        'HandleVisibility', 'off');
    for k = 1:nMethods
        boxchart(ax, k * ones(nCases, 1), Y(:, k), 'BoxFaceColor', methodColors(k, :), ...
            'BoxFaceAlpha', 0.15, 'WhiskerLineColor', methodColors(k, :), 'MarkerStyle', 'none', ...
            'BoxWidth', 0.5, 'LineWidth', 1);
        scatter(ax, k + jitter, Y(:, k), 22, methodColors(k, :), 'filled', ...
            'Marker', methodMarkers(k), 'MarkerFaceAlpha', 0.7);
    end
    hold(ax, 'off');
    styleAxes(ax);
    set(ax, 'XTick', 1:nMethods, 'XTickLabel', methodLabels, 'XLim', [0.5 nMethods + 0.5]);
    ylabel(ax, plotTitles(p));
    if ismember(plotMetrics(p), ["dice", "iou"]), ylim(ax, [0 1]); end
end
title(tl, sprintf('Segmentation performance on %d test cases (lines join the same case)', nCases));
exportgraphics(f, fullfile(figDir, 'fig_metrics.png'), 'Resolution', 200);

% 5b. Does performance depend on the case? (uses Task 1's characteristics)
charFile = fullfile(cfg.tableDir, 'dataset_characteristics.csv');
opts = detectImportOptions(charFile, 'TextType', 'string');
opts = setvartype(opts, {'caseId', 'sitePrefix'}, 'string');
C = readtable(charFile, opts);
TC = innerjoin(T, C(:, {'caseId', 'sitePrefix', 'bladderVolume_mL', 'contrastRatio', 'cutOffSuperior'}), ...
    'Keys', 'caseId');

f = figure('Visible', figVisible, 'Color', 'w', 'Position', [100 100 1100 380]);
tl = tiledlayout(f, 1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
xVars   = ["bladderVolume_mL", "contrastRatio"];
xLabels = ["Reference bladder volume (mL)", "Contrast ratio (bladder / surrounding)"];
for p = 1:2
    ax = nexttile(tl); hold(ax, 'on');
    for k = 1:nMethods
        r = TC.method == methods(k);
        scatter(ax, TC.(xVars(p))(r), TC.dice(r), 28, methodColors(k, :), 'filled', ...
            'Marker', methodMarkers(k), 'MarkerFaceAlpha', 0.7, 'DisplayName', methodLabels(k));
    end
    hold(ax, 'off');
    styleAxes(ax);
    xlabel(ax, xLabels(p)); ylabel(ax, 'Dice'); ylim(ax, [0 1]);
end
lg = legend(nexttile(tl, 1), 'Orientation', 'horizontal', 'Box', 'off');
lg.Layout.Tile = 'north';
ax = nexttile(tl); hold(ax, 'on');
cutGroup = categorical(TC.cutOffSuperior, [0 1], ["Dome visible", "Dome cut off"]);
methodGroup = categorical(TC.method, methods, methodLabels);
colororder(ax, methodColors);
boxchart(ax, cutGroup, TC.dice, 'GroupByColor', methodGroup, 'BoxFaceAlpha', 0.3);
hold(ax, 'off');
styleAxes(ax);
ylabel(ax, 'Dice'); ylim(ax, [0 1]);
title(tl, 'Dice against case characteristics (from Task 1)');
exportgraphics(f, fullfile(figDir, 'fig_dice_vs_characteristics.png'), 'Resolution', 200);

% 5c. Error maps: the worst case of each method (add any case ids you want)
errorCases = strings(0);
for k = 1:nMethods
    r = find(T.method == methods(k));
    [~, w] = min(T.dice(r));
    errorCases(end + 1) = T.caseId(r(w)); %#ok<SAGROW>
end
for id = unique(errorCases)
    f = errorFigure(cfg, id, methods, methodLabels, T, figVisible);
    exportgraphics(f, fullfile(errDir, id + "_errors.png"), 'Resolution', 200);
    close(f);
end

fprintf('\nTables saved to %s\nFigures saved to %s\n', cfg.tableDir, figDir);

%% Local functions
function s = mergeStructs(s, extra)
% Append the fields of struct extra to struct s.
for fn = string(fieldnames(extra))'
    s.(fn) = extra.(fn);
end
end

function q = quantileSorted(x, p)
% Quantile by linear interpolation (avoids needing the Statistics Toolbox).
x = sort(x(~isnan(x)));
if isempty(x), q = NaN; return, end
q = interp1(1:numel(x), x, 1 + p * (numel(x) - 1));
end

function p = signedRankP(d)
% Two-sided Wilcoxon signed-rank test, normal approximation with tie and
% continuity correction. d = paired differences. NaN if all differences are 0.
d = d(d ~= 0 & ~isnan(d));
n = numel(d);
if n == 0, p = NaN; return, end
[s, order] = sort(abs(d));
ranks = zeros(n, 1);
tieSizes = [];
i = 1;
while i <= n
    j = i;
    while j < n && s(j + 1) == s(i), j = j + 1; end
    ranks(order(i:j)) = (i + j) / 2;           % average rank for ties
    tieSizes(end + 1) = j - i + 1; %#ok<AGROW>
    i = j + 1;
end
W = sum(ranks(d > 0));
mu = n * (n + 1) / 4;
sigma = sqrt(n * (n + 1) * (2 * n + 1) / 24 - sum(tieSizes.^3 - tieSizes) / 48);
z = (W - mu - 0.5 * sign(W - mu)) / sigma;
p = erfc(abs(z) / sqrt(2));
end

function styleAxes(ax)
% Recessive axes and grid so the data stands out.
set(ax, 'Box', 'off', 'TickDir', 'out', 'XColor', [0.35 0.35 0.35], 'YColor', [0.35 0.35 0.35], ...
    'YGrid', 'on', 'GridColor', [0.85 0.85 0.85], 'GridAlpha', 1, 'FontSize', 10);
end

function f = errorFigure(cfg, id, methods, methodLabels, T, figVisible)
% Axial, coronal and sagittal slices through the reference bladder: the
% reference, then each method's errors (white = correct, orange = false
% positive / leakage, blue = false negative / missed bladder).
c = loadCase(cfg, id);
[A, sp] = toDisplayOrientation(c.img, c.info);
R = toDisplayOrientation(c.bladder, c.info);
[~, i] = max(squeeze(sum(R, [2 3])));
[~, j] = max(squeeze(sum(R, [1 3])));
[~, k] = max(squeeze(sum(R, [1 2])));
idx = [i j k];
win = intensityWindow(A);
[S, pix] = orthoSlices(A, sp, idx);
SR = orthoSlices(R, sp, idx);

errColors = [1 1 1; 0.922 0.408 0.204; 0.165 0.471 0.839];   % TP white, FP #eb6834, FN #2a78d6
views = ["axial", "coronal", "sagittal"];
nM = numel(methods);
f = figure('Visible', figVisible, 'Color', 'w', 'Position', [100 100 300 * (nM + 1) 700]);
tl = tiledlayout(f, 3, nM + 1, 'TileSpacing', 'compact', 'Padding', 'compact');
for v = 1:3
    showSlice(nexttile(tl, (v - 1) * (nM + 1) + 1), S.(views(v)), pix.(views(v)), win, SR.(views(v)), ...
        "Reference (" + views(v) + ")");
end
for m = 1:nM
    P = toDisplayOrientation(loadPredictedMask(cfg, id, methods(m)), c.info);
    SP = orthoSlices(P, sp, idx);
    dice = T.dice(T.caseId == id & T.method == methods(m));
    for v = 1:3
        ax = nexttile(tl, (v - 1) * (nM + 1) + m + 1);
        pr = SP.(views(v)); rf = SR.(views(v));
        L = zeros(size(pr));
        L(pr & rf) = 1; L(pr & ~rf) = 2; L(~pr & rf) = 3;
        grey = rescale(S.(views(v)), 'InputMin', win(1), 'InputMax', win(2));
        imshow(labeloverlay(grey, L, 'Colormap', errColors, 'Transparency', 0.45), 'Parent', ax);
        daspect(ax, [1/pix.(views(v))(2) 1/pix.(views(v))(1) 1]);
        title(ax, sprintf('%s (Dice %.2f)', methodLabels(m), dice), 'FontWeight', 'normal');
    end
end
% Legend with named swatches so the colours are not the only cue
hold(ax, 'on');
names = ["Correct (TP)", "False positive (leakage)", "False negative (missed)"];
h = gobjects(1, 3);
for e = 1:3
    h(e) = patch(ax, NaN, NaN, errColors(e, :), 'EdgeColor', [0.4 0.4 0.4], 'DisplayName', names(e));
end
hold(ax, 'off');
lg = legend(ax, h, 'Orientation', 'horizontal', 'Box', 'off');
lg.Layout.Tile = 'south';
title(tl, "Case " + id + ": errors against the reference bladder");
end
