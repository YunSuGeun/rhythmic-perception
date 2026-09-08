# Retrospective Attention Theta Rhythm Analysis Code

MATLAB code used for the accepted iScience manuscript:

**Retrospective attention reveals a decaying theta rhythm in conscious access to a preceding stimulus**

The corresponding data are available on Zenodo:

[https://doi.org/10.5281/zenodo.21192160](https://doi.org/10.5281/zenodo.21192160)

## Repository Structure

```text
.
|-- Preprocessing/
|   |-- preprocess_rhythm_wm_gooddata.m
|   |-- Block_Combining_verAuto.m
|   |-- save_clean_rawdata.m
|   |-- clean_raw_data.m
|   |-- Saccade_Data_YL_ver02.m
|   |-- Edf_Tool_YL_ver03.m
|   `-- Saccade_Remover_YL.m
|-- Figure/
|   |-- Fig3_1_SlidingWindow.m
|   |-- Fig4_1_IndividualIRASA.m
|   |-- Fig4_2_PlotAlignedSpectra.m
|   |-- Fig5_1_Curvefitting.m
|   |-- Fig5_2_PlotCurve.m
|   |-- Fig6_AdjustedR2_violin.m
|   |-- Fig7_1_Hilbert.m
|   |-- Fig7_2_Vtest.m
|   |-- FigS2_IRASA_GrandFigure.m
|   |-- FigS3_PlotCurve.m
|   |-- FigS4_AdjustedR2_violin.m
|   |-- FigS5_Vtest_SplitTimeBins.m
|   `-- helper plotting/behavior functions
`-- README.md
```

Raw data, processed `.mat`/`.csv` files, and generated figures are intentionally excluded from this repository. Download the data from Zenodo and place the required data folders in the local project directory before running the scripts.

## Expected Local Data Layout

Most figure scripts resolve paths relative to the repository root:

```text
.
|-- 01_Data/
|   |-- 01_RawData/
|   |-- 01_Preprocessed/
|   |-- 02_BehavioralData/
|   |-- 03_IRASAData/
|   |-- 04_CurvefittingData/
|   |-- 05_AdjR2/
|   `-- 06_PhaseAlign/
|-- 03_Figure/
|-- Preprocessing/
`-- Figure/
```

## Dependencies

- MATLAB
- Optimization Toolbox is used when available for `lsqnonlin`; `Fig5_1_Curvefitting.m` falls back to `fminsearch` if it is unavailable.
- Statistics and Machine Learning Toolbox for functions such as `signrank` and `ksdensity`.
- FieldTrip for `Fig7_1_Hilbert.m`; set `FIELDTRIP_ROOT` before running that script.
- CircStat functions (`circ_mean`, `circ_rtest`, `circ_vtest`) and `fdr_bh` for phase statistics.
- `edfmex` for EDF conversion in the eye-tracking preprocessing helpers.

Before running analyses from the repository root, add the code folders to the MATLAB path:

```matlab
addpath(genpath(pwd));
```

## Typical Analysis Order

1. Run preprocessing scripts in `Preprocessing/`.
2. Run `Figure/Fig3_1_SlidingWindow.m` to generate behavioral time-course files.
3. Run `Figure/Fig4_1_IndividualIRASA.m` and related Figure 4/S2 scripts for IRASA outputs.
4. Run `Figure/Fig5_1_Curvefitting.m`, then plot with `Figure/Fig5_2_PlotCurve.m` and `Figure/FigS3_PlotCurve.m`.
5. Run `Figure/Fig6_AdjustedR2_violin.m` and `Figure/FigS4_AdjustedR2_violin.m`.
6. Run `Figure/Fig7_1_Hilbert.m`, then `Figure/Fig7_2_Vtest.m` and `Figure/FigS5_Vtest_SplitTimeBins.m`.

## Citation

If you use this code or data, please cite the iScience article and the Zenodo dataset:

Yun, S. et al. **Retrospective attention reveals a decaying theta rhythm in conscious access to a preceding stimulus**. iScience.

Data: [https://doi.org/10.5281/zenodo.21192160](https://doi.org/10.5281/zenodo.21192160)
