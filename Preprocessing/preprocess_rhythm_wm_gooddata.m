function preprocess_rhythm_wm_gooddata()
%PREPROCESS_RHYTHM_WM_GOODDATA Combine and clean Rhythm_WM GoodDATA files.
%   This is a non-interactive wrapper around the existing preprocessing
%   functions in this folder. It discovers subjects under Rhythm_WM/GoodDATA,
%   combines their behavioral and eye-tracking data, and saves both combined
%   and cleaned outputs under Rhythm_WM/Preprocessed.

root_dir = fileparts(fileparts(mfilename('fullpath')));
gooddata_dir = fullfile(root_dir, 'Rhythm_WM', 'GoodDATA');
edf_dir = fullfile(root_dir, 'Rhythm_WM', 'edf');
output_dir = fullfile(root_dir, 'Rhythm_WM', 'Preprocessed');
combined_dir = fullfile(output_dir, 'CombinedData');
cleaned_dir = fullfile(output_dir, 'CleanedData');
edf_toolbox_dir = fullfile(root_dir, 'Preprocessing', 'edf-converter-master', 'edf-converter-master');

pre = 50;
post = 300;
auto_mode = 2;
saccade_threshold = 30;
visual_angle = 1;
stimulus_mode = 'TC';
save_intermediate = 0;

if ~exist(gooddata_dir, 'dir')
    error('GoodDATA directory not found: %s', gooddata_dir);
end
if ~exist(edf_dir, 'dir')
    error('EDF directory not found: %s', edf_dir);
end

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end
if ~exist(combined_dir, 'dir')
    mkdir(combined_dir);
end
if ~exist(cleaned_dir, 'dir')
    mkdir(cleaned_dir);
end

addpath(fileparts(mfilename('fullpath')));
addpath(edf_dir);
if exist(edf_toolbox_dir, 'dir')
    addpath(genpath(edf_toolbox_dir));
end

subject_listing = dir(gooddata_dir);
is_subject = [subject_listing.isdir] & ~ismember({subject_listing.name}, {'.', '..'});
subjects = sort({subject_listing(is_subject).name});

run_date = datetime('now');
summary = struct('subject', {}, 'blocks', {}, 'trials', {}, 'removed_trials', {}, 'clean_trials', {}, 'status', {}, 'message', {});

for m = 1:numel(subjects)
    subj_name = subjects{m};
    subj_dir = fullfile(gooddata_dir, subj_name);
    behav_files = dir(fullfile(subj_dir, 'data_RetroCue_*.mat'));

    if isempty(behav_files)
        fprintf('Skipping %s: no RetroCue files found.\n', subj_name);
        continue;
    end

    behav_names = sort_nat({behav_files.name});
    fprintf('\nProcessing %s (%d blocks)\n', subj_name, numel(behav_names));

    try
        old_dir = pwd;
        cleanup_dir = onCleanup(@() cd(old_dir));
        cd(combined_dir);

        saccades = Saccade_Data_YL_ver02( ...
            edf_dir, stimulus_mode, pre, post, auto_mode, ...
            saccade_threshold, visual_angle, save_intermediate, subj_name);

        clear cleanup_dir;
        cd(old_dir);

        total_trials = count_total_trials(subj_dir, behav_names);
        if numel(saccades.xSaccade) < total_trials || numel(saccades.xEyeoff) < total_trials
            error('Saccade data shorter than behavior data (saccades=%d, eyeoff=%d, trials=%d).', ...
                numel(saccades.xSaccade), numel(saccades.xEyeoff), total_trials);
        end

        DATA = zeros(total_trials, 14);
        row_offset = 0;

        for i = 1:numel(behav_names)
            loaded = load(fullfile(subj_dir, behav_names{i}));
            if ~isfield(loaded, 'data')
                error('File does not contain variable "data": %s', fullfile(subj_dir, behav_names{i}));
            end

            data = loaded.data;
            block_trials = size(data.xAcc, 2);
            row_idx = row_offset + (1:block_trials);

            DATA(row_idx, 1) = data.xBlock(1, 1:block_trials);
            DATA(row_idx, 2) = data.xTrial(1, 1:block_trials);
            DATA(row_idx, 3) = data.xCondition1(1, 1:block_trials);
            DATA(row_idx, 4) = data.xCondition2(1, 1:block_trials);
            DATA(row_idx, 5) = data.xCondition5(1, 1:block_trials);
            DATA(row_idx, 6) = data.xCondition4(1, 1:block_trials);
            DATA(row_idx, 7) = data.xDuration(1, 1:block_trials);
            DATA(row_idx, 8) = data.xAcc(1, 1:block_trials);
            DATA(row_idx, 9) = data.xAbsent(1, 1:block_trials);
            DATA(row_idx, 10) = 0;
            DATA(row_idx, 11) = data.xVisi(1, 1:block_trials);
            DATA(row_idx, 12) = saccades.xSaccade(1, row_idx);
            DATA(row_idx, 13) = saccades.xEyeoff(1, row_idx);
            DATA(row_idx, 14) = data.xCondition3(1, 1:block_trials);

            row_offset = row_offset + block_trials;
        end

        cleaned_data = clean_raw_data(DATA);
        combined_path = fullfile(combined_dir, sprintf('Combine_data_%s_%04d%02d%02d.mat', ...
            subj_name, run_date.Year, run_date.Month, run_date.Day));
        cleaned_path = fullfile(cleaned_dir, sprintf('%s_%04d%02d%02d_cleaned.mat', ...
            subj_name, run_date.Year, run_date.Month, run_date.Day));

        save(combined_path, 'DATA');
        save(cleaned_path, 'cleaned_data');

        summary(end+1) = struct( ... %#ok<AGROW>
            'subject', subj_name, ...
            'blocks', numel(behav_names), ...
            'trials', size(DATA, 1), ...
            'removed_trials', size(DATA, 1) - size(cleaned_data, 1), ...
            'clean_trials', size(cleaned_data, 1), ...
            'status', 'processed', ...
            'message', '');

        fprintf('Saved combined=%s cleaned=%s\n', combined_path, cleaned_path);
    catch ME
        summary(end+1) = struct( ... %#ok<AGROW>
            'subject', subj_name, ...
            'blocks', numel(behav_names), ...
            'trials', 0, ...
            'removed_trials', 0, ...
            'clean_trials', 0, ...
            'status', 'skipped', ...
            'message', ME.message);
        fprintf('Skipping %s: %s\n', subj_name, ME.message);
    end
end

summary_path = fullfile(output_dir, sprintf('preprocess_summary_%04d%02d%02d.mat', ...
    run_date.Year, run_date.Month, run_date.Day));
save(summary_path, 'summary');
fprintf('\nSummary saved to %s\n', summary_path);
end

function total_trials = count_total_trials(subj_dir, behav_names)
total_trials = 0;
for i = 1:numel(behav_names)
    loaded = load(fullfile(subj_dir, behav_names{i}));
    if ~isfield(loaded, 'data')
        error('File does not contain variable "data": %s', fullfile(subj_dir, behav_names{i}));
    end
    total_trials = total_trials + size(loaded.data.xAcc, 2);
end
end

function names = sort_nat(names)
block_numbers = zeros(size(names));
for i = 1:numel(names)
    tokens = regexp(names{i}, 'Block(\d+)\.mat$', 'tokens', 'once');
    if isempty(tokens)
        block_numbers(i) = inf;
    else
        block_numbers(i) = str2double(tokens{1});
    end
end
[~, order] = sort(block_numbers);
names = names(order);
end
