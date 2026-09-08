%% plot IPF aligned power spectrum - Antigravity Version

clear; clc

% Set paths relative to the script location
scriptPath = fileparts(mfilename('fullpath'));
rawDir = fullfile(scriptPath, '..', '01_Data', '03_IRASAData');
saveDir = fullfile(scriptPath, '..', '03_Figure', 'Figure4');

if ~exist(saveDir, 'dir')
    mkdir(saveDir);
end

% Explicitly define the 4 pairs of (Invalid, Valid) conditions
pairs = { ...
    '100 ms Postcue Perf I (Left-C)', '100 ms Postcue Perf V (Left-C)'; ...
    '100 ms Postcue Perf I (Right-C)', '100 ms Postcue Perf V (Right-C)'; ...
    '100 ms Postcue Visi I (Left-C)', '100 ms Postcue Visi V (Left-C)'; ...
    '100 ms Postcue Visi I (Right-C)', '100 ms Postcue Visi V (Right-C)' ...
};

freqs = 2:0.1:10; % 81 points
x_axis = -8:0.1:8; % 161 points

% Frequencies matching the IRASA output grid (0 to 19 Hz in 0.1 Hz steps)
irasa_freqs = 0:0.1:19;
idx_2_10 = irasa_freqs >= 2 & irasa_freqs <= 10;

% Process each pair
for n = 1:size(pairs, 1)
    invalid_name = pairs{n, 1};
    valid_name = pairs{n, 2};

    cd(rawDir)

    %% 1. Process Valid (do not plot yet)
    data_name = valid_name;
    load([valid_name '.mat']) % loads IRASA_info
    load(['subject_peaks_' valid_name '.mat']) % loads all_subject_peaks

    % Slice the original power spectrum to 2-10 Hz
    ori_valid = IRASA_info.ori(:, idx_2_10);
    valid_subjects_v = ~isnan(all_subject_peaks(:, 1)) & (all_subject_peaks(:, 1) > 0);

    % Update all related data to include only valid subjects
    filtered_all_subject_peaks_v = all_subject_peaks(valid_subjects_v, :);
    filtered_ori_v = ori_valid(valid_subjects_v, :);

    num_subj_valid = size(filtered_ori_v, 1);
    num_freq = size(filtered_ori_v, 2); % 81
    
    IPF_align_v = NaN(num_subj_valid, 2*num_freq - 1); % size: [num_subj, 161]
    
    for subj_n = 1:num_subj_valid
        IPF = filtered_all_subject_peaks_v(subj_n,1);
        [~, IPF_index] = min(abs(freqs - IPF));
        diff_index = 81 - IPF_index;
        MaxOri = max(filtered_ori_v(subj_n,:));
        normalized_ori = filtered_ori_v(subj_n,:) / MaxOri;
        
        IPF_align_v(subj_n,diff_index+1:diff_index + 81) = normalized_ori;
    end        
      
    % Remove NaN columns for accurate plotting
    valid_columns_v = ~all(isnan(IPF_align_v), 1);
    IPF_align_v = IPF_align_v(:, valid_columns_v);
    x_axis_valid = x_axis(valid_columns_v);
    
    mean_align_valid = mean(IPF_align_v,1,'omitNaN');
    sd_align_valid = std(IPF_align_v,1,'omitNaN') / sqrt(num_subj_valid);
    
    % Compute mean and sem of IPFs directly
    valid_ipfs = filtered_all_subject_peaks_v(:,1);
    v_main_freq = mean(valid_ipfs);
    v_main_sem = std(valid_ipfs) / sqrt(length(valid_ipfs));


    %% 2. Process Invalid (do not plot yet)
    data_name = invalid_name;
    load([invalid_name '.mat']) % loads IRASA_info
    load(['subject_peaks_' invalid_name '.mat']) % loads all_subject_peaks

    % Slice the original power spectrum to 2-10 Hz
    ori_invalid = IRASA_info.ori(:, idx_2_10);
    valid_subjects_i = ~isnan(all_subject_peaks(:, 1)) & (all_subject_peaks(:, 1) > 0);

    % Update all related data to include only valid subjects
    filtered_all_subject_peaks_i = all_subject_peaks(valid_subjects_i, :);
    filtered_ori_i = ori_invalid(valid_subjects_i, :);

    num_subj_invalid = size(filtered_ori_i, 1);
    
    IPF_align_i = NaN(num_subj_invalid, 2*num_freq - 1); % size: [num_subj, 161]
    
    for subj_n = 1:num_subj_invalid
        IPF = filtered_all_subject_peaks_i(subj_n,1);
        [~, IPF_index] = min(abs(freqs - IPF));
        diff_index = 81 - IPF_index;
        MaxOri = max(filtered_ori_i(subj_n,:));
        normalized_ori = filtered_ori_i(subj_n,:) / MaxOri;
        
        IPF_align_i(subj_n,diff_index+1:diff_index + 81) = normalized_ori;
    end        
      
    % Compute mean and sem of IPFs directly
    invalid_ipfs = filtered_all_subject_peaks_i(:, 1);
    i_main_freq = mean(invalid_ipfs);
    i_main_sem = std(invalid_ipfs) / sqrt(length(invalid_ipfs));

    freq_dif = i_main_freq - v_main_freq;

    % Remove NaN columns for accurate plotting
    valid_columns_i = ~all(isnan(IPF_align_i), 1);
    IPF_align_invalid = IPF_align_i(:, valid_columns_i);
    x_axis_invalid = x_axis(valid_columns_i) + freq_dif;
    
    mean_align_invalid = mean(IPF_align_invalid,1,'omitNaN');
    sd_align_invalid = std(IPF_align_invalid,1,'omitNaN') / sqrt(num_subj_invalid);


    %% 3. Create Figure & Plot (Invalid first, then Valid)
    figure1 = figure('Visible', 'off');
    
    % Plot Invalid (Red) first so it goes below Valid
    H_invalid = shadedErrorBar(x_axis_invalid, mean_align_invalid, sd_align_invalid, {'-r','DisplayName','Invalid'}, 0, 0.1, 4, 1);
    set(H_invalid.patch, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    if isfield(H_invalid, 'edge') && ~isempty(H_invalid.edge)
        set(H_invalid.edge, 'Visible', 'off');
    end
    hold on;
    
    % Plot Valid (Blue) second so it stays on top
    H_valid = shadedErrorBar(x_axis_valid, mean_align_valid, sd_align_valid, {'-b','DisplayName','Valid'}, 0, 0.1, 4, 1);
    set(H_valid.patch, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    if isfield(H_valid, 'edge') && ~isempty(H_valid.edge)
        set(H_valid.edge, 'Visible', 'off');
    end

    % Draw color-coded vertical dotted lines from 0 to peak
    % Valid (at x = 0)
    idx_zero_v = find(x_axis_valid == 0);
    if ~isempty(idx_zero_v)
        y_peak_valid = mean_align_valid(idx_zero_v);
        plot([0, 0], [0, y_peak_valid], ':b', 'LineWidth', 1.5);
    end
    
    % Invalid (at x = freq_dif)
    idx_zero_i = find(x_axis(valid_columns_i) == 0);
    if ~isempty(idx_zero_i)
        y_peak_invalid = mean_align_invalid(idx_zero_i);
        plot([freq_dif, freq_dif], [0, y_peak_invalid], ':r', 'LineWidth', 1.5);
    end

    %% Text & Axis Formatting
    % Place V and I info at the northwest side in black and bold
    text(-1.3, 0.92, sprintf('V = %.1f \\pm %.1f Hz', v_main_freq, v_main_sem), ...
         'HorizontalAlignment', 'left', 'Color', 'k', 'FontSize', 10, 'FontWeight', 'bold');
    text(-1.3, 0.84, sprintf('I = %.1f \\pm %.1f Hz', i_main_freq, i_main_sem), ...
         'HorizontalAlignment', 'left', 'Color', 'k', 'FontSize', 10, 'FontWeight', 'bold');
     
    % X axis tick formatting
    if abs(v_main_freq - i_main_freq) < 1e-5
        tick_positions_sorted = [0, 4];
        tick_labels_sorted = {'V, I', 'V+4'};
    else
        tick_positions = [0, 4, freq_dif];
        [tick_positions_sorted, sort_idx] = sort(tick_positions);
        tick_labels = {'V', 'V+4', 'I'};
        tick_labels_sorted = tick_labels(sort_idx);
    end
    xticks(tick_positions_sorted);
    xticklabels(tick_labels_sorted);

    % Y axis tick formatting
    yticks([0, 0.2, 0.4, 0.6, 0.8, 1.0]);
    ylim([0 1]);
    xlim([-1.5 6]);
    
    % Style adjustments
    axis square;
    box off;
    set(gca, 'LineWidth', 1.5, 'FontSize', 10);
    
    xlabel('Frequency (Hz)', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('Normalized Power (a.u.)', 'FontSize', 11, 'FontWeight', 'bold');
    title(['IPF Aligned Power Spectrum: ', valid_name, ' vs ', invalid_name]);

    cd(saveDir)
    exportgraphics(figure1, [valid_name '_vs_' invalid_name '_aligned.pdf'], 'ContentType', 'vector')
    exportgraphics(figure1, [valid_name '_vs_' invalid_name '_aligned.png'], 'Resolution', 300)
    hold off
    close(figure1);
     
end
