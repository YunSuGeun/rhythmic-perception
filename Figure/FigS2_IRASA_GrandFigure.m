%% Fig4 Grand Figure of IRASA Power Spectra (All Subjects x All Conditions)
%
% This script loads the pre-calculated IRASA results and plots a 19x8 grid 
% showing individual power spectra. 
% - Columns: 8 conditions
% - Rows: 19 subjects
% - Shaded background outside [2.8, 7.2] Hz (IPF range)
% - X-ticks are set only at 4 and 8 Hz, with larger font size.
% - Original spectrum is in red, median fractal is in black.

clear; clc; close all;
scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptDir);

fprintf('--- FIG4 GRAND FIGURE GENERATION START ---\n');
drawnow('update');

%% 1. Path Settings
scriptPath = fileparts(mfilename('fullpath'));
if isempty(scriptPath)
    scriptPath = pwd;
end

% Set paths relative to script location, with absolute path fallback
rawDir = fullfile(scriptPath, '..', '01_Data', '03_IRASAData');
if ~exist(rawDir, 'dir')
    rawDir = fullfile(projectRoot, '01_Data', '03_IRASAData');
end

saveDir = fullfile(scriptPath, '..', '03_Figure', 'Figure4');
if ~exist(saveDir, 'dir')
    saveDir = fullfile(projectRoot, '03_Figure', 'Figure4');
end

if ~exist(saveDir, 'dir')
    mkdir(saveDir);
end

%% 2. Condition Definitions
conditions = { ...
    '100 ms Postcue Perf I (Left-C)', ...
    '100 ms Postcue Perf V (Left-C)', ...
    '100 ms Postcue Perf I (Right-C)', ...
    '100 ms Postcue Perf V (Right-C)', ...
    '100 ms Postcue Visi I (Left-C)', ...
    '100 ms Postcue Visi V (Left-C)', ...
    '100 ms Postcue Visi I (Right-C)', ...
    '100 ms Postcue Visi V (Right-C)' ...
};

colHeaders = { ...
    'Perf Invalid (Left)', ...
    'Perf Valid (Left)', ...
    'Perf Invalid (Right)', ...
    'Perf Valid (Right)', ...
    'Visi Invalid (Left)', ...
    'Visi Valid (Left)', ...
    'Visi Invalid (Right)', ...
    'Visi Valid (Right)' ...
};

numSubj = 19;
numCond = length(conditions);

%% 3. Plot Configurations
plotSubwindows = false; % Set to true if you want to plot the 8 individual sliding-window fractal lines

% Frequencies matching the IRASA output grid (0 to 19 Hz in 0.1 Hz steps)
irasa_freqs = 0:0.1:19; 
idx_plot = irasa_freqs >= 2 & irasa_freqs <= 10;
plot_freqs = irasa_freqs(idx_plot); % 81 points from 2 to 10 Hz

% IPF Range: 2.8 - 7.2 Hz
ipf_min = 2.8;
ipf_max = 7.2;

%% 4. Preload All Data
fprintf('Preloading data from %s...\n', rawDir);
all_ori = cell(numCond, 1);
all_fra = cell(numCond, 1);
all_peaks = cell(numCond, 1);

for c = 1:numCond
    cond_name = conditions{c};
    mat_path = fullfile(rawDir, [cond_name '.mat']);
    peaks_path = fullfile(rawDir, ['subject_peaks_' cond_name '.mat']);
    
    if ~exist(mat_path, 'file')
        error('Data file not found: %s', mat_path);
    end
    if ~exist(peaks_path, 'file')
        error('Peak file not found: %s', peaks_path);
    end
    
    loaded_data = load(mat_path);
    all_ori{c} = loaded_data.IRASA_info.ori; % size: [19, 191]
    all_fra{c} = loaded_data.IRASA_info.fra; % size: [8, 191, 19]
    
    loaded_peaks = load(peaks_path);
    all_peaks{c} = loaded_peaks.all_subject_peaks; % size: [19, 2]
end

%% 5. Generate Grand Figure
fprintf('Generating grand figure...\n');
drawnow('update');

% Set up a large figure to accommodate 152 subplots
grand_fig = figure('Color', 'w', 'Visible', 'off');
% Set up large pixels size for high-resolution subplots layout
set(grand_fig, 'Units', 'pixels', 'Position', [50, 50, 2000, 2600]);
% grand_fig.Units = 'centimeters';
% grand_fig.Position(3:4) = [40 80]

% Create tiled layout with minimal spacing
t = tiledlayout(numSubj, numCond, 'TileSpacing', 'compact', 'Padding', 'compact');

for s = 1:numSubj
    for c = 1:numCond
        % Focus on the next subplot tile
        nexttile;
        
        % Get data vectors
        ori = all_ori{c}(s, :);
        ori_plot = ori(idx_plot);
        
        % Normalize by MaxOri in the plotting range (2 to 10 Hz)
        MaxOri = max(ori_plot);
        if MaxOri == 0 || isnan(MaxOri)
            MaxOri = 1;
        end
        ori_norm = ori_plot / MaxOri;
        
        % Shade background outside [2.8, 7.2] Hz
        % Since plotting range is [2, 10], the regions are [2, 2.8] and [7.2, 10]
        y_limit_patch = 1.15;
        y_coords = [0, 0, y_limit_patch, y_limit_patch];
        patch_color = [0.93, 0.93, 0.93];
        
        % Left shaded patch: [2, 2.8]
        patch([2, ipf_min, ipf_min, 2], y_coords, patch_color, 'EdgeColor', 'none', 'FaceAlpha', 1.0);
        hold on;
        
        % Right shaded patch: [7.2, 10]
        patch([ipf_max, 10, 10, ipf_max], y_coords, patch_color, 'EdgeColor', 'none', 'FaceAlpha', 1.0);
        
        % Gray dotted line at x = 4 Hz, y = [0, 1]
        plot([4, 4], [0, 1.5], ':', 'Color', [0.5, 0.5, 0.5], 'LineWidth', 1.0);
        
        % Plot optional subwindow fractal spectra (thin dotted gray lines)
        if plotSubwindows
            fra_subj = all_fra{c}(:, idx_plot, s); % [8, 81]
            for w = 1:size(fra_subj, 1)
                plot(plot_freqs, fra_subj(w, :) / MaxOri, ...
                    'Color', [0.8, 0.8, 0.8], 'LineStyle', ':', 'LineWidth', 0.5);
            end
        end
        
        % Plot Median Fractal component (thin black line)
        fra_median = median(all_fra{c}(:, idx_plot, s), 1);
        plot(plot_freqs, fra_median / MaxOri, ...
            'Color', [0.2, 0.2, 0.2], 'LineStyle', '-', 'LineWidth', 0.9);
        
        % Plot Original spectrum (solid red line)
        plot(plot_freqs, ori_norm, ...
            'Color', [0.85, 0.15, 0.15], 'LineStyle', '-', 'LineWidth', 1.5);
        
        % Highlight identified peak frequency with a green circle/dot
        peak_freq = all_peaks{c}(s, 1);
        if ~isnan(peak_freq) && peak_freq >= 2 && peak_freq <= 10
            [~, peak_idx] = min(abs(plot_freqs - peak_freq));
            peak_power_norm = ori_norm(peak_idx);
            plot(peak_freq, peak_power_norm, 'go', 'MarkerSize', 5, 'LineWidth', 1.2, 'MarkerFaceColor', 'g');
        end
        
        % Subplot formatting
        xlim([2, 10]);
        ylim([0, 1.15]);
        box off;
        
        % X-tick configuration: only at 4 and 8 Hz, and make it larger
        xticks([4, 8]);
        set(gca, 'LineWidth', 1.0);
        
        if s == numSubj
            xticklabels({'4', '8'});
            set(gca, 'FontSize', 20, 'FontWeight', 'bold');
        else
            xticklabels({});
            set(gca, 'FontSize', 20, 'FontWeight', 'bold');
        end
        
        % Hide Y-ticks to prevent clutter in the matrix
        yticks([]);
        
        % Set column title at the top row
        if s == 1
            title(colHeaders{c}, 'FontSize', 20, 'FontWeight', 'bold', 'Interpreter', 'none');
        end
        
        % Set row label on the leftmost column
        if c == 1
            ylabel(sprintf('Subj %d', s), 'FontSize', 20, 'FontWeight', 'bold', ...
                'Rotation', 0, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
        end
        
        hold off;
    end
end

% Set global labels for the tiled layout
xlabel(t, 'Frequency (Hz)', 'FontSize', 20, 'FontWeight', 'bold');
title(t, 'Individual IRASA Power Spectra (Original in Red, Fractal in Black, Shaded Outside 2.8 - 7.2 Hz)', ...
    'FontSize', 20, 'FontWeight', 'bold');

%% 6. Save the Figure
fprintf('Saving figure to %s...\n', saveDir);
drawnow('update');

cd(saveDir);
png_name = 'Fig4_IRASA_GrandFigure_Individual.png';
pdf_name = 'Fig4_IRASA_GrandFigure_Individual.pdf';

% Export as PNG with high resolution (300 DPI) for presentation
exportgraphics(grand_fig, png_name, 'Resolution', 300);

% Export as vector PDF for publication
exportgraphics(t, pdf_name, 'ContentType', 'vector', 'Resolution', 300);

close(grand_fig);
fprintf('--- FIG4 GRAND FIGURE GENERATION COMPLETE ---\n');
