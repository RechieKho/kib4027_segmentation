# KIB4027 Group 3: Bladder segmentation in pelvic MRI (MATLAB)

Assignment: *Performance Evaluation of Bladder Segmentation Techniques in Pelvic MRI*. Two segmentation
techniques are run on the same 49 test cases and compared against the reference bladder masks.

Requirements: MATLAB **R2022b or later** (the templates use output argument validation) with the **Image
Processing Toolbox**. No other toolboxes are needed.

## Quick start

1. Clone the repo. The dataset (~1 GB) is stored with Git LFS and downloads automatically. Git LFS is included
   with Git for Windows. On other systems, install it and run `git lfs install` once before cloning.
   ```
   git clone https://github.com/RechieKho/kib4027_segmentation.git
   ```
2. Open the cloned folder in MATLAB.
3. Run `task1_data/task1_load_and_visualise.m` (about 1-2 minutes) to check your setup. It should finish without
   errors and write figures to `results/figures/task1/`.

If `data/dataAndMask/` contains small text files instead of `.nii` volumes, LFS did not download them. Run
`git lfs pull` in the repo folder.

## Workflow

| Step | Who | Run | Produces |
|---|---|---|---|
| 1 | A | `task1_data/task1_load_and_visualise.m` | test-case list, dataset figures and characteristics (already committed) |
| 2 | B | `method1/run_method1.m` | `results/masks/method1/` |
| 2 | C | `method2/run_method2.m` | `results/masks/method2/` |
| 3 | D | `evaluation/run_evaluation.m` | metrics tables, comparison and error figures |

Until B and C implement their techniques, both methods output a dummy mask, so every step already runs end to end.

**Predicted masks are not committed** (`results/masks/` is git-ignored). Commit the method *code*; whoever runs
the evaluation first runs `run_method1.m` and `run_method2.m` to create the masks locally.

### Working with git

- Each person edits their own folder (see the layout below). Ask before changing `common/`, `projectConfig.m` or
  `test_cases.csv`, since everyone depends on them.
- `git pull` before you start, commit small changes often, and `git push` when your code runs.
- Commit figures and tables under `results/` only when they are ready for the report.

## Folder layout

| Folder / file | Owner | What goes there |
|---|---|---|
| `data/dataAndMask/` | A | MRI volumes and reference masks (Git LFS). Do not edit. |
| `projectConfig.m` | A | Shared paths. Call `cfg = projectConfig();` at the top of every script. |
| `test_cases.csv` | A | Fixed list of test cases. **Both methods and the evaluation use exactly these cases.** |
| `common/` | A (shared) | Helper functions and the `BladderCase` class (see below). |
| `task1_data/` | A | Task 1: loading, visualisation, dataset characteristics. |
| `method1/` | B | Segmentation technique 1 (template: `run_method1.m` + `segmentBladderMethod1.m`). |
| `method2/` | C | Segmentation technique 2 (template: `run_method2.m` + `segmentBladderMethod2.m`). |
| `evaluation/` | D | Metrics, statistics, error analysis (template: `run_evaluation.m` + `computeMetrics.m`). |
| `results/masks/<method>/` | B, C | Predicted masks, one file per test case (git-ignored). |
| `results/figures/`, `results/tables/` | all | Figures and tables for the report, in a subfolder per task/method. |

## Data

The 50 volumes come from the lecturer's Google Drive (`dataForAssignment/dataAndMask`), a subset of the
Cross-institution Male Pelvic Structures dataset (Zenodo record 7013610). They are included in this repo under
`data/dataAndMask/` (Git LFS), which is where `projectConfig` looks by default. To use a copy elsewhere, run
`setenv('KIB4027_DATA', 'C:\path\to\dataAndMask')` before `projectConfig`.

- `<caseId>_img.nii`: T2-weighted volume. `<caseId>_mask.nii`: multi-class reference mask (labels 0-8). **Bladder = label 1.**
- Case `002015` has no reference mask, so it is excluded. The test set is the other **49 cases**.
- Volumes differ in size (180x180 to 512x512 in-plane, 23-47 slices), voxel size (0.39-1.0 mm in-plane,
  2-3.6 mm slices) and data type. `loadCase` converts every image to `double`.

## Shared conventions (agreed for a fair comparison)

1. Loop over `ids = readTestCases(cfg);` and nothing else.
2. Load with `c = loadCase(cfg, id);`. This returns a `BladderCase` with `c.img` (double), `c.spacing` (mm),
   `c.info` (NIfTI header) and the reference `c.bladder` (logical). Arrays are in the file's **native voxel
   order**, so do not reorient before segmenting.
3. Save each predicted mask with `savePredictedMask(cfg, c, 'method1', bw);`. This checks the mask and writes
   `results/masks/method1/<caseId>_pred.nii` as uint8 0/1 on the same grid and header as the image.
4. The evaluation reads masks with `bw = loadPredictedMask(cfg, id, 'method1');` and compares them with `c.bladder`.
5. For figures, use `toDisplayOrientation` + `orthoSlices` + `showSlice` so every view has the same layout
   (axial: anterior up, patient's right on the image left; sagittal: superior up, anterior left) with correct
   physical proportions.

## Shared code (`common/`)

`BladderCase` is the class `loadCase` returns. Its properties are read-only and documented (`doc BladderCase`):

| Property | Type | Meaning |
|---|---|---|
| `id` | string | Case id, e.g. `"002016"` |
| `img` | 3-D double | T2 volume, native voxel order |
| `spacing` | 1x3 double | Voxel size in mm along the array dimensions |
| `info` | struct | `niftiinfo` of the image |
| `labels` | 3-D uint8 | **Ground truth**, multi-class (empty if the case has no mask) |
| `bladder` | 3-D logical | **Ground truth**, label 1 (empty if the case has no mask) |

`c.checkPrediction(bw)` errors unless `bw` is a logical mask the size of `c.img`, and warns if it is empty.

| Function | Purpose |
|---|---|
| `listCases(cfg)` | Every case in the data folder and whether it has a mask |
| `readTestCases(cfg)` | Case ids in the fixed test set |
| `loadCase(cfg, id)` | Load one case as a `BladderCase` |
| `savePredictedMask` / `loadPredictedMask` | Write/read masks in the shared format |
| `toDisplayOrientation(V, info)` | Reorder axes to Left/Anterior/Superior for display (no resampling) |
| `orthoSlices(A, spacing, [i j k])` | Axial/coronal/sagittal slices in radiological layout |
| `showSlice(ax, img, pix, win, mask, title)` | Draw a slice with true proportions and an optional mask outline |
| `intensityWindow(V)` | 1st-99th percentile intensity window |

## Task 1 (Role A)

Run `task1_data/task1_load_and_visualise.m` (about 1-2 minutes). It writes:

- `test_cases.csv`, created once and then kept fixed
- `results/figures/task1/cases/<caseId>_views.png`: axial/coronal/sagittal views of every case, with and without
  the reference bladder (git-ignored, regenerated by the script)
- `results/figures/task1/fig1_label_overview.png`: multi-class mask vs extracted bladder
- `results/figures/task1/fig2_representative.png`: cases illustrating size, shape, contrast and resolution variation
- `results/figures/task1/fig3_characteristics.png`: volume, voxel size, contrast and slice-coverage plots
- `results/tables/dataset_characteristics.csv` (per case) and `dataset_summary.csv` (median/IQR/range)

## Task 2 (Roles B and C)

`method1/` and `method2/` each contain a ready-made template:

| File | What to do |
|---|---|
| `run_methodN.m` | Driver: loops over the test cases, saves masks in the shared format, writes `results/tables/methodN_runtime.csv` and prints a sanity-check Dice. Only edit the `params` block. |
| `segmentBladderMethodN.m` | **Put your technique here**, in the three marked stages: preprocessing, segmentation, post-processing. Keep the function signature (see below). |

Both methods have the same signature, `bw = segmentBladderMethodN(c, params)`:

| | Argument | Type | Checked by |
|---|---|---|---|
| In | `c` | `BladderCase` from `loadCase`. Use only `c.img`, `c.spacing`, `c.info` (and `c.id`). | `arguments (Input)` block |
| In | `params` | struct of your settings, set in `run_methodN.m` | `arguments (Input)` block |
| Out | `bw` | logical, `size(bw) == size(c.img)`, native voxel order, true = bladder | `arguments (Output)` block (type) and `c.checkPrediction` in `savePredictedMask` (size; warns if empty) |

The segmentation stage is a placeholder (a 25 mm sphere at the volume centre, median Dice about 0.01) so the
pipeline and the evaluation can run before the real methods exist. Do not use `c.labels` or `c.bladder` inside
`segmentBladderMethodN.m`: those are the ground truth.

## Tasks 3 and 4 (Role D)

`evaluation/` contains a ready-made template:

| File | What to do |
|---|---|
| `run_evaluation.m` | Driver: checks every method has a mask for every test case, computes the metrics, writes the tables and draws the figures below. Set `methodLabels` to the technique names; add your own plots in section 5. |
| `computeMetrics.m` | Metrics for one case: Dice, IoU, sensitivity, precision, volumes, signed volume difference, HD95 and ASSD (mm). Add a metric as a new field and it appears in every table. |

Outputs:

- `results/tables/metrics.csv`: one row per case per method
- `results/tables/metrics_summary.csv`: n, mean, SD, median, IQR, range per method and metric
- `results/tables/metrics_paired.csv`: method 2 vs method 1 per metric (median difference, wins, Wilcoxon signed-rank p)
- `results/figures/evaluation/fig_metrics.png`: Dice, IoU and HD95 per method, lines joining the same case
- `results/figures/evaluation/fig_dice_vs_characteristics.png`: Dice against bladder volume, contrast and
  truncated dome (from the Task 1 table)
- `results/figures/evaluation/errors/<caseId>_errors.png`: TP / FP / FN maps in three views for each method's
  worst case

No Statistics Toolbox is needed: quantiles and the Wilcoxon test are implemented in the script.
