clear; clc;

% Data Directories
scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptDir);
rawDir = fullfile(projectRoot, '01_Data', '02_BehavioralData');
    
cd(rawDir)

data_selected = { ...
    '100 ms Postcue Perf I (Left-C).mat', ...
    '100 ms Postcue Perf I (Right-C).mat', ...
    '100 ms Postcue Perf V (Left-C).mat', ...
    '100 ms Postcue Perf V (Right-C).mat', ...
    '100 ms Postcue Visi I (Left-C).mat', ...
    '100 ms Postcue Visi I (Right-C).mat', ...
    '100 ms Postcue Visi V (Left-C).mat', ...
    '100 ms Postcue Visi V (Right-C).mat' ...
};


    
poly_orig_opts = 2;
poly_fra_opts  = 0;

for i = 1:length(data_selected)
    close all;
    cd(rawDir);
    data_name = data_selected{i};
    load(data_name);
    data = Group_data;

    if strcmp(data_name(8:10), 'Pre'); Cue_Cond = 1; elseif strcmp(data_name(8:10), 'Pos'); Cue_Cond = 2; end
        
    %% IRASA setup
    raw_timepoint = 0.05:0.01:1.5;
    analysis_idx = raw_timepoint >= 0.05 & raw_timepoint <= 1.50;
    timepoint = raw_timepoint(analysis_idx);
    if Cue_Cond == 1; timepoint = flip(timepoint) .* -1; end

    fs = 100; % 100 Hz sampling rate
    L_full = length(timepoint);
    window_n = round(L_full * 0.75); % 75% of full analysis window
    step_n = 5; % 0.05 s step size (5 samples)
    num_windows = floor((L_full - window_n) / step_n) + 1;
    
    if num_windows < 1
        error('The selected time window is too short for the sliding fractal window.');
    end
    
    N_fft = 10 * fs; % 10s zero padding -> 1000 FFT points
    freqs = (0:N_fft-1) * (fs / N_fft); % 0.1 Hz frequency resolution
    
    % Keep frequencies up to 19 Hz (indices 1 to 191)
    freqs = freqs(1:191);
    idx_plot = find(freqs >= 2 & freqs <= 10);
    idx_search = find(freqs >= 2.75 & freqs <= 10);
    freqs_search = freqs(idx_search);
    
    rf_set = 1.1:0.05:1.9;
    num_rf = length(rf_set);

    poly_orig_val = 2;
    poly_fra_val  = 0;
            
    %% Custom IRASA Loop
    num_data = size(data,1);
    
    fractal_n = zeros(num_data, num_windows, length(freqs));
    original_n = zeros(num_data, length(freqs));
    oscillatory_n = zeros(num_data, length(freqs));
    all_subject_peaks = zeros(num_data, 2);

    for subj_n = 1:num_data
        trial = data(subj_n, analysis_idx);
        
        trial_detrend_full = trial;
        t_full_poly = 1:L_full;
        p_full = polyfit(t_full_poly, trial_detrend_full, poly_orig_val);
        trial_detrend_full = trial_detrend_full - polyval(p_full, t_full_poly);
        
        % 1. Original power spectrum on full window
        % Order: (No resampling) -> Apply Taper -> Pad -> FFT
        w_full = hanning(L_full)';
        w_full = w_full / norm(w_full, 'fro');
        trial_win_full = trial_detrend_full .* w_full;
        P_orig_full = abs(fft(trial_win_full, N_fft)).^2 * (2 / N_fft);
        
        % 2. Fractal component estimation from sliding windows
        P_fractal_windows_subj = zeros(num_windows, length(freqs));
        
        for w = 1:num_windows
            win_start = (w - 1) * step_n + 1;
            win_end = win_start + window_n - 1;
            trial_sub = trial(win_start:win_end);
            
            % Remove polynomial trend from subwindow
            if poly_fra_val >= 0
                t_sub_poly = 1:window_n;
                p_sub = polyfit(t_sub_poly, trial_sub, poly_fra_val);
                trial_sub = trial_sub - polyval(p_sub, t_sub_poly);
            end
            
            P_rf_all = zeros(length(freqs), 2 * num_rf);
            t_sub = 0 : 1/fs : (window_n - 1)/fs;
            
            for r_idx = 1:num_rf
                rf = rf_set(r_idx);
                rf_star = 2 - rf;
                
                % --- Upsample (rf) ---
                L_up = floor(window_n / rf);
                t_up = (0 : L_up - 1) / fs;
                % 1. Resample (spline interpolation on 100 Hz grid)
                trial_up = interp1(t_sub, trial_sub, t_up * rf, 'spline', 0);
                % 2. Hanning Window
                w_up = hanning(L_up)';
                w_up = w_up / norm(w_up, 'fro');
                trial_up_win = trial_up .* w_up;
                % 3. Zero pad to 10s (1000 samples)
                trial_up_padded = zeros(1, N_fft);
                len_up = min(L_up, N_fft);
                trial_up_padded(1:len_up) = trial_up_win(1:len_up);
                % 4. FFT
                P_up = abs(fft(trial_up_padded, N_fft)).^2 * (2 / N_fft);
                
                % --- Downsample (rf_star) ---
                L_down = floor(window_n / rf_star);
                t_down = (0 : L_down - 1) / fs;
                % 1. Resample (spline interpolation on 100 Hz grid)
                trial_down = interp1(t_sub, trial_sub, t_down * rf_star, 'spline', 0);
                % 2. Hanning Window
                w_down = hanning(L_down)';
                w_down = w_down / norm(w_down, 'fro');
                trial_down_win = trial_down .* w_down;
                % 3. Zero pad to 10s (1000 samples)
                trial_down_padded = zeros(1, N_fft);
                len_down = min(L_down, N_fft);
                trial_down_padded(1:len_down) = trial_down_win(1:len_down);
                % 4. FFT
                P_down = abs(fft(trial_down_padded, N_fft)).^2 * (2 / N_fft);
                
                % Store both up- and down-resampled powers
                P_rf_all(:, 2*r_idx - 1) = P_up(1:191);
                P_rf_all(:, 2*r_idx) = P_down(1:191);
            end
            
            % Median across all resampled power spectra (both rf and rf_star)
            P_fractal_windows_subj(w, :) = median(P_rf_all, 2);
        end
        % Store original power spectrum (truncated to 19 Hz)
        original_n(subj_n, :) = P_orig_full(1:191);
        fractal_n(subj_n, :, :) = P_fractal_windows_subj;
        
        % Compute final median fractal across sliding windows
        P_fractal_median = median(P_fractal_windows_subj, 1);
        
        % Oscillatory residuals: Original - Median Fractal
        osc_residuals = P_orig_full(1:191) - P_fractal_median;
        oscillatory_n(subj_n, :) = osc_residuals;
        
        % Peak identification 
        % 1. Find segments where Original > Fractal across all frequencies (1:191)
        idx_above_all = find(P_orig_full(1:191) > P_fractal_median(1:191));
        
        local_peaks = [];
        if ~isempty(idx_above_all)
            diff_idx = diff(idx_above_all);
            seg_breaks = [0, find(diff_idx > 1), length(idx_above_all)];
            num_segs = length(seg_breaks) - 1;
            
            for s_idx = 1:num_segs
                seg_indices = idx_above_all(seg_breaks(s_idx)+1 : seg_breaks(s_idx+1));
                if length(seg_indices) == 1
                    % Segment of length 1 is considered a local peak (no neighbors in the segment)
                    local_peaks = [local_peaks, seg_indices(1)];
                else
                    % For segments of length >= 2, find internal local peaks
                    for k_idx = 2 : length(seg_indices)-1
                        k = seg_indices(k_idx);
                        if P_orig_full(k) > P_orig_full(k-1) && P_orig_full(k) > P_orig_full(k+1)
                            local_peaks = [local_peaks, k];
                        end
                    end
                end
            end
        end
        
        % 2. Filter local peaks that fall in [2.75 10.0] Hz
        candidate_peaks = [];
        for p = 1:length(local_peaks)
            freq_val = freqs(local_peaks(p));
            if freq_val >= 2.75 && freq_val <= 10.0
                candidate_peaks = [candidate_peaks, local_peaks(p)];
            end
        end
        
        % 3. Select candidate with maximum original power
        if ~isempty(candidate_peaks)
            [max_power, max_idx] = max(P_orig_full(candidate_peaks));
            peak_frequency = freqs(candidate_peaks(max_idx));
            peak_val = max_power;
        else
            peak_frequency = NaN;
            peak_val = NaN;
        end
        
        all_subject_peaks(subj_n, :) = [peak_frequency, peak_val];
    end
    %% save info
    [~, data_name_noext, ~] = fileparts(data_name);
    TiT = sprintf('%s',data_name_noext) 
    
    saveDir = fullfile(projectRoot, '01_Data', '03_IRASAData');
    if (~exist(saveDir,'dir'))
        mkdir(saveDir) ;
    end
  
    cd(saveDir);
    
    IRASA_info = [];
    IRASA_info.name = TiT;
    IRASA_info.ori = original_n;
    IRASA_info.osc = oscillatory_n;
    % Permute fractal_n back to original dimension order [win, freq, subj_n] for backward compatibility
    IRASA_info.fra = permute(fractal_n, [2, 3, 1]);
    
    save(TiT, 'IRASA_info');
    
    %% Plot individual (plotting in range 2-10 Hz)
    for subj_n = 1:num_data 
        figure1 = figure('Visible', 'off', 'Position', [100, 100, 800, 550]);
        
        ori = original_n(subj_n, :);
        MaxOri = max(ori(idx_plot)); % Scale based on 2-10 Hz peak for visibility
        
        % Plot original spectrum in thick red
        plot(freqs(idx_plot), ori(idx_plot) / MaxOri, '-r', 'LineWidth', 2.5, 'DisplayName', 'Original (Full Window)');
        hold on;
        
        % Plot fractal spectrum for each individual subwindow in thin dotted gray
        fra = squeeze(fractal_n(subj_n, :, :));
        for w = 1:num_windows
            plot(freqs(idx_plot), fra(w, idx_plot) / MaxOri, 'Color', [0.7, 0.7, 0.7], 'LineStyle', ':', 'LineWidth', 1, 'HandleVisibility', 'off');
        end
        % Legend placeholder for individual subwindows
        plot(nan, nan, 'Color', [0.7, 0.7, 0.7], 'LineStyle', ':', 'LineWidth', 1, 'DisplayName', 'Fractal (Subwindows)');
        
        % Plot final median fractal spectrum in thin black
        P_fractal_median = median(fra, 1);
        plot(freqs(idx_plot), P_fractal_median(idx_plot) / MaxOri, '-k', 'LineWidth', 1.0, 'DisplayName', 'Fractal (Median)');
        
        % Highlight identified peak frequency on the original spectrum graph
        peak_frequency = all_subject_peaks(subj_n, 1);
        if ~isnan(peak_frequency)
            peak_idx_in_freqs = find(freqs == peak_frequency);
            plot(peak_frequency, ori(1, peak_idx_in_freqs) / MaxOri, 'go', 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', 'Peak');
            text(peak_frequency, ori(1, peak_idx_in_freqs) / MaxOri, ...
                 sprintf(' %.2f Hz', peak_frequency), ...
                 'VerticalAlignment', 'bottom', 'FontWeight', 'bold');
        end
        
        title(sprintf('%s - Subj %d', data_name_noext, subj_n));
        xlabel('Frequency (Hz)');
        ylabel('Normalized Power');
        xlim([2 10]);
        ylim([0, max(ori(idx_plot)/MaxOri)+0.1]);
        grid on;
        legend('Location', 'best');

        figDir = fullfile(projectRoot, '03_Figure', 'Figure4', TiT);
        if (~exist(figDir,'dir'))
            mkdir(figDir) ;
        end

        cd(figDir)
        saveas(figure1, sprintf('%d.png', subj_n));
        hold off;
        close(figure1);
    end

    cd(saveDir)
    save(['subject_peaks_' TiT '.mat'], 'all_subject_peaks');
end
