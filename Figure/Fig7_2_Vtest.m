%% Instantaneous Phase Check between Perf and Visi
clear; clc; close all;

scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptDir);

rawDir = fullfile(projectRoot, '01_Data', '06_PhaseAlign');
dataDir = fullfile(projectRoot, '01_Data', '06_PhaseAlign');
figDir = fullfile(projectRoot, '03_Figure', 'Figure7');

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
missingFiles = data_selected(~cellfun(@(name) exist(fullfile(rawDir, name), 'file') == 2, data_selected));
if ~isempty(missingFiles)
    error('Missing Hilbert data file(s): %s', strjoin(missingFiles, ', '));
end

indices = 1:4;
offset = 4;
saveDir = figDir;
if ~exist(saveDir, 'dir')
    mkdir(saveDir);
end
if ~exist(dataDir, 'dir')
    mkdir(dataDir);
end

invalidColor = [0.85, 0.00, 0.00];
validColor = [0.00, 0.25, 0.95];
arrowAlpha = 0.5;
plotData = repmat(struct( ...
    'avgAngle', [], ...
    'z', [], ...
    'sigAngle', [], ...
    'nSig', 0, ...
    'mu', NaN, ...
    'vtestP', NaN, ...
    'vtestZ', NaN, ...
    'color', [], ...
    'titleText', '', ...
    'saveStem', ''), length(indices), 1);
commonRMax = 100;
rayleighStatsAll = table();
vtestStatsAll = table();

% Compute all Perf-Visi pairs first so the saved figures share one grid.
for i = 1:length(indices)
        first_ind = indices(i);
        second_ind = first_ind + offset;
        
        first_name = data_selected{1,first_ind};
        conds = split(first_name); % Adjust delimiter as needed
        if strcmp(conds{5}, 'I')
            validityText = "Invalid";
            plotColor = invalidColor;
        elseif strcmp(conds{5}, 'V')
            validityText = "Valid";
            plotColor = validColor;
        else
            error('Cannot determine validity from file name: %s', first_name);
        end
        conditionText = string(conds{3});
        validityCode = string(conds{5});
        sideText = string(erase(conds{6}, '.mat'));
    
        second_name = data_selected{1,second_ind};
    
        % Load the instantaneous phase data
        load(fullfile(rawDir, first_name));
        phase1 = instantaneous_phase; % Perf/Invalid
    
        load(fullfile(rawDir, second_name));
        phase2 = instantaneous_phase; % Visi/Valid
    
        % Compute phase difference
        phase_diff = wrapToPi(phase1 - phase2);
    
        [nSubj, ~] = size(phase_diff);
        avg_angle_all = zeros(1, nSubj);
        pvals = zeros(nSubj, 1);
        z_all = zeros(1, nSubj);
        
    
        for subj = 1:nSubj
            subj_phase_diff = phase_diff(subj,:);        
            % Run Rayleigh test for clustering
            [pval, z] = circ_rtest(subj_phase_diff);
            % Store the p-value
            pvals(subj) = pval;
            z_all(subj) = z;   
            % Angle mean
            avg_angle = circ_mean(subj_phase_diff, [], 2);
            avg_angle_all(subj) = avg_angle;        
        end    



        % Step 2: Apply FDR BH correction
        alpha = 0.05;    
        [h, crit_p, ~, adj_pvals] = fdr_bh(pvals, alpha, 'pdep', 'no'); 
        h = logical(h(:));
        adj_pvals = adj_pvals(:);
        
        n = nnz(h);
        sig_avg_angle = avg_angle_all(logical(h));
        TiT = sprintf('%s %s %s', conds{3}, conds{5}, erase(conds{6}, '.mat'));
        saveStem = sprintf('%s_%s_%s', conds{3}, conds{5}, erase(conds{6}, '.mat'));

        rayleighStats = table( ...
            repmat(string(TiT), nSubj, 1), ...
            repmat(conditionText, nSubj, 1), ...
            repmat(validityCode, nSubj, 1), ...
            repmat(validityText, nSubj, 1), ...
            repmat(sideText, nSubj, 1), ...
            repmat(string(first_name), nSubj, 1), ...
            repmat(string(second_name), nSubj, 1), ...
            (1:nSubj)', ...
            avg_angle_all(:), ...
            rad2deg(wrapToPi(avg_angle_all(:))), ...
            pvals(:), ...
            z_all(:), ...
            adj_pvals, ...
            h, ...
            'VariableNames', {'condition_label', 'cue', 'validity_code', ...
            'validity', 'side', 'first_file', 'second_file', 'subject_index', ...
            'mean_angle_rad', 'mean_angle_deg', 'rayleigh_p', 'rayleigh_z', ...
            'rayleigh_fdr_p', 'rayleigh_fdr_significant'} ...
        );
        rayleighStatsAll = [rayleighStatsAll; rayleighStats]; %#ok<AGROW>

        plotData(i).avgAngle = avg_angle_all;
        plotData(i).z = z_all;
        plotData(i).sigAngle = sig_avg_angle;
        plotData(i).nSig = n;
        plotData(i).color = plotColor;
        plotData(i).titleText = TiT;
        plotData(i).saveStem = saveStem;
        commonRMax = max(commonRMax, max(z_all) * 1.10);

        if n > 0
            [pval, z] = circ_vtest(sig_avg_angle, 0); 
            plotData(i).vtestP = pval;
            plotData(i).vtestZ = z;
            plotData(i).mu = wrapToPi(circ_mean(sig_avg_angle,[],2));
        else
            plotData(i).mu = NaN;
        end

        vtestStats = table( ...
            string(TiT), conditionText, validityCode, validityText, sideText, ...
            string(first_name), string(second_name), nSubj, n, alpha, crit_p, ...
            plotData(i).mu, rad2deg(plotData(i).mu), plotData(i).vtestP, plotData(i).vtestZ, ...
            'VariableNames', {'condition_label', 'cue', 'validity_code', ...
            'validity', 'side', 'first_file', 'second_file', 'n_subjects', ...
            'n_rayleigh_fdr_significant', 'alpha', 'rayleigh_fdr_crit_p', ...
            'vtest_mu_rad', 'vtest_mu_deg', 'vtest_p', 'vtest_z'} ...
        );
        vtestStatsAll = [vtestStatsAll; vtestStats]; %#ok<AGROW>
end

if ~isfinite(commonRMax) || commonRMax <= 0
    commonRMax = 100;
end

writetable(rayleighStatsAll, fullfile(dataDir, 'Fig7_phasealign_rayleigh_stats.csv'));
writetable(vtestStatsAll, fullfile(dataDir, 'Fig7_phasealign_vtest_stats.csv'));
save(fullfile(dataDir, 'Fig7_phasealign_stats.mat'), ...
    'rayleighStatsAll', 'vtestStatsAll', 'commonRMax');

for i = 1:numel(plotData)
        Figure1 = figure('Color', 'w');
        ax = axes('Parent', Figure1);
        hold(ax, 'on');
        axis(ax, 'equal');
        axis(ax, 'off');

        draw_polar_grid(ax, commonRMax);

        % Plot subject angles
        for subj = 1:numel(plotData(i).avgAngle)
            draw_polar_arrow(ax, plotData(i).avgAngle(subj), plotData(i).z(subj), ...
                plotData(i).color, arrowAlpha, commonRMax);
        end

        % Mean angle only for significant
        if plotData(i).nSig > 0
            fprintf('%s: V-test p = %.4g, z = %.4g\n', ...
                plotData(i).titleText, plotData(i).vtestP, plotData(i).vtestZ);
            plot(ax, [0, commonRMax * cos(plotData(i).mu)], ...
                [0, commonRMax * sin(plotData(i).mu)], ...
                'Color', plotData(i).color, 'LineWidth', 4);
        else
            fprintf('%s: V-test skipped: no significant subjects.\n', plotData(i).titleText);
        end

        title(ax, plotData(i).titleText);

        saveas(Figure1, fullfile(saveDir, [plotData(i).saveStem '.png']));
        saveas(Figure1, fullfile(saveDir, [plotData(i).saveStem '.pdf']));
        hold(ax, 'off');
        close(Figure1);
end


function draw_polar_grid(ax, rMax)
    theta = linspace(0, 2*pi, 361);
    gridColor = [0.82, 0.82, 0.82];
    labelColor = [0.35, 0.35, 0.35];
    axisLimit = rMax * 1.30;
    radiusTicks = [50, 100];
    angleTicks = 0:45:315;

    for radius = radiusTicks(radiusTicks <= rMax)
        plot(ax, radius * cos(theta), radius * sin(theta), ...
            '-', 'Color', gridColor, 'LineWidth', 0.6);
        text(ax, radius * cos(pi/18), radius * sin(pi/18), sprintf('%d', radius), ...
            'Color', labelColor, 'FontSize', 9, ...
            'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
            'BackgroundColor', 'w', 'Margin', 1);
    end

    if ~ismember(round(rMax), radiusTicks)
        plot(ax, rMax * cos(theta), rMax * sin(theta), ...
            '-', 'Color', gridColor, 'LineWidth', 0.6);
    end

    for angle = angleTicks .* pi / 180
        plot(ax, [0, rMax * cos(angle)], [0, rMax * sin(angle)], ...
            '-', 'Color', gridColor, 'LineWidth', 0.6);
    end

    angleLabelRadius = rMax * 1.16;
    for angleDeg = angleTicks
        angle = angleDeg * pi / 180;
        text(ax, angleLabelRadius * cos(angle), angleLabelRadius * sin(angle), ...
            sprintf('%d%s', angleDeg, char(176)), ...
            'Color', labelColor, 'FontSize', 9, ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
            'BackgroundColor', 'w', 'Margin', 1);
    end

    xlim(ax, [-axisLimit, axisLimit]);
    ylim(ax, [-axisLimit, axisLimit]);
end


function draw_polar_arrow(ax, theta, radius, color, alphaValue, rMax)
    if ~isfinite(theta) || ~isfinite(radius) || radius <= 0
        return;
    end

    headLength = min(0.045 * rMax, 0.2625 * radius);
    headWidth = min(0.02625 * rMax, 0.1875 * radius);
    shaftWidth = 0.006 * rMax;

    direction = [cos(theta), sin(theta)];
    orthogonal = [-sin(theta), cos(theta)];
    tip = radius * direction;
    headBase = max(radius - headLength, 0) * direction;

    if norm(headBase) > 0
        shaftStart = 0.015 * rMax * direction;
        shaftEnd = headBase;
        shaftX = [
            shaftStart(1) + shaftWidth * orthogonal(1)
            shaftEnd(1) + shaftWidth * orthogonal(1)
            shaftEnd(1) - shaftWidth * orthogonal(1)
            shaftStart(1) - shaftWidth * orthogonal(1)
        ];
        shaftY = [
            shaftStart(2) + shaftWidth * orthogonal(2)
            shaftEnd(2) + shaftWidth * orthogonal(2)
            shaftEnd(2) - shaftWidth * orthogonal(2)
            shaftStart(2) - shaftWidth * orthogonal(2)
        ];
        patch(ax, shaftX, shaftY, color, ...
            'FaceAlpha', alphaValue, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    end

    headX = [
        tip(1)
        headBase(1) + headWidth * orthogonal(1)
        headBase(1) - headWidth * orthogonal(1)
    ];
    headY = [
        tip(2)
        headBase(2) + headWidth * orthogonal(2)
        headBase(2) - headWidth * orthogonal(2)
    ];
    patch(ax, headX, headY, color, ...
        'FaceAlpha', alphaValue, 'EdgeColor', 'none', 'HandleVisibility', 'off');
end
