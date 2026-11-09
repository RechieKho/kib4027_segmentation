# KIB4027 Group 3: Bladder segmentation in pelvic MRI (MATLAB)

MATLAB R2022b or later with the Image Processing Toolbox. No other toolboxes are needed.

## Quick start

1. Clone the repo. The dataset (~1 GB) is stored with Git LFS and downloads automatically. Git LFS is included
   with Git for Windows. On other systems, install it and run `git lfs install` once before cloning.
   ```
   git clone <repo-url>
   ```
2. Open the cloned folder in MATLAB.
3. Run `task1_data/task1_load_and_visualise.m` (about 1-2 minutes) to check your setup. It should finish without
   errors and write figures to `results/figures/task1/`.

If `data/dataAndMask/` contains small text files instead of `.nii` volumes, LFS did not download them. Run
`git lfs pull` in the repo folder.

## Folder layout

| Folder / file | Owner | What goes there |
|---|---|---|
| `data/dataAndMask/` | A | MRI volumes and reference masks (Git LFS). Do not edit. |
| `projectConfig.m` | A | Shared paths. Call `cfg = projectConfig();` at the top of every script. |
| `test_cases.csv` | A | Fixed list of test cases. **Both methods and the evaluation use exactly these cases.** |
| `common/` | A (shared) | Helper functions everyone uses (see below). |
| `task1_data/` | A | Task 1: loading, visualisation, dataset characteristics. |
| `method1/` | B | Segmentation technique 1 (template: `run_method1.m` + `segmentBladderMethod1.m`). |
| `method2/` | C | Segmentation technique 2 (template: `run_method2.m` + `segmentBladderMethod2.m`). |
| `evaluation/` | D | Dice / IoU, statistics, error analysis. |
| `results/masks/<method>/` | B, C | Predicted masks, one file per test case. |
| `results/figures/`, `results/tables/` | all | Figures and tables for the report (use a subfolder per task/method). |

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
2. Load with `c = loadCase(cfg, id);`. This returns a `BladderCase` `c` with `c.img` (double), `c.bladder` (logical reference) and
   `c.info` (NIfTI header). Arrays are in the file's **native voxel order**, so do not reorient before segmenting.
3. Save each predicted mask with `savePredictedMask(cfg, c, 'method1', bw);`. This writes
   `results/masks/method1/<caseId>_pred.nii` as uint8 0/1 on the same grid and header as the image.
4. The evaluation reads masks with `bw = loadPredictedMask(cfg, id, 'method1');` and compares them with `c.bladder`.
5. For figures, use `toDisplayOrientation` + `orthoSlices` + `showSlice` so every view has the same layout
   (axial: anterior up, patient's right on the image left; sagittal: superior up, anterior left) with correct
   physical proportions.

## Helper functions (`common/`)

| Function | Purpose |
|---|---|
| `listCases(cfg)` | Every case in the data folder and whether it has a mask |
| `readTestCases(cfg)` | Case ids in the fixed test set |
| `loadCase(cfg, id)` | Image, multi-class labels, bladder mask, header, voxel spacing |
| `savePredictedMask` / `loadPredictedMask` | Write/read masks in the shared format |
| `toDisplayOrientation(V, info)` | Reorder axes to Left/Anterior/Superior for display (no resampling) |
| `orthoSlices(A, spacing, [i j k])` | Axial/coronal/sagittal slices in radiological layout |
| `showSlice(ax, img, pix, win, mask, title)` | Draw a slice with true proportions and an optional mask outline |
| `intensityWindow(V)` | 1st-99th percentile display window |
| `BladderCase` | Class returned by `loadCase`. Declare arguments as `c (1,1) BladderCase` to get type checks and property suggestions in the editor. |

## Task 2 (Roles B and C)

`method1/` and `method2/` each contain a ready-made template:

| File | What to do |
|---|---|
| `run_methodN.m` | Driver: loops over the test cases, saves masks in the shared format, writes `results/tables/methodN_runtime.csv` and prints a sanity-check Dice. Only edit the `params` block. |
| `segmentBladderMethodN.m` | **Put your technique here**, in the three marked stages: preprocessing, segmentation, post-processing. Input is the `BladderCase` from `loadCase`; output is a logical mask the same size as `c.img`. |

The segmentation stage is a placeholder (a 25 mm sphere at the volume centre, median Dice about 0.01) so the
pipeline and the evaluation can run before the real methods exist. Do not use `c.labels` or `c.bladder` inside
`segmentBladderMethodN.m`: those are the ground truth.

## Task 1 (Role A)

Run `task1_data/task1_load_and_visualise.m` (about 1-2 minutes). It writes:

- `test_cases.csv`, created once and then kept fixed
- `results/figures/task1/cases/<caseId>_views.png`: axial/coronal/sagittal views of every case, with and without the reference bladder
- `results/figures/task1/fig1_label_overview.png`: multi-class mask vs extracted bladder
- `results/figures/task1/fig2_representative.png`: cases illustrating size, shape, contrast and resolution variation
- `results/figures/task1/fig3_characteristics.png`: volume, voxel size, contrast and slice-coverage plots
- `results/tables/dataset_characteristics.csv` (per case) and `dataset_summary.csv` (median/IQR/range)
