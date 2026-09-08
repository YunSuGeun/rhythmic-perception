%% FigS4 Adjusted R2 violin plots split and pooled by Validity and Measure
% Reads adjusted_r2 values from the  CSV
% locations within subjects, and plots paired violin summaries separately
% for Accuracy/Visibility * Valid/Invalid, and pooled across Valid and Invalid (n=38).

close all; clear; clc;

fprintf('--- FIGS4 ADJUSTED R2 VIOLIN SPLIT  START ---\n');
drawnow('update');

scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptDir);

csvPath = fullfile(projectRoot, '01_Data', '04_CurvefittingData', ...
    'Fig5_Curvefitting_results.csv');

statsDir = fullfile(projectRoot, '01_Data', '05_AdjR2');
figureDir = fullfile(projectRoot, '03_Figure', 'FigureS4');

if ~exist(statsDir, 'dir')
    mkdir(statsDir);
end
if ~exist(figureDir, 'dir')
    mkdir(figureDir);
end

results = readtable(csvPath, 'TextType', 'string');
requiredVars = ["condition_file", "measure", "validity", "cue", ...
    "subject_index", "subject", "model", "frequency_hz", ...
    "adjusted_r2"];
missingVars = setdiff(requiredVars, string(results.Properties.VariableNames));
if ~isempty(missingVars)
    error('Missing required CSV column(s): %s', strjoin(missingVars, ', '));
end

modelNames = ["M1", "M2", "M4"];
modelLabels = {'Monotonic Decay', 'Sustained Oscillation', 'Gaussian Damped Oscillation'};
modelPairs = nchoosek(1:numel(modelNames), 2);
colors = [
    0.85, 0.33, 0.10;  % M1
    0.47, 0.67, 0.19;  % M2
    0.00, 0.45, 0.74   % M4
];

metricVar = 'adjusted_r2';
metricLabel = 'Adjusted R2';
metricFileTag = 'adjusted_r2';

% 1. SPLIT VALID & INVALID ANALYSIS (n = 19)
plotSpecs = struct( ...
    'measure', {'Perf', 'Perf', 'Visi', 'Visi'}, ...
    'measureLabel', {'Accuracy', 'Accuracy', 'Visibility', 'Visibility'}, ...
    'validity', {'Valid', 'Invalid', 'Valid', 'Invalid'}, ...
    'validityLabel', {'Valid', 'Invalid', 'Valid', 'Invalid'}, ...
    'fileTag', {'accuracy_valid', 'accuracy_invalid', 'visibility_valid', 'visibility_invalid'}, ...
    'ylims', {[-0.1, 0.8], [-0.1, 0.8], [-0.1, 0.8], [-0.1, 0.8]} ...
);

statsAll = table();

for plotIndex = 1:numel(plotSpecs)
    plotSpec = plotSpecs(plotIndex);
    
    % Build matrix: average Left and Right within subject for this measure & validity
    [r2Matrix, rowInfo] = build_split_metric_matrix( ...
        results, plotSpec.measure, plotSpec.validity, modelNames, metricVar);
    
    % Wilcoxon signed-rank tests
    statsTable = pairwise_wilcoxon( ...
        r2Matrix, modelPairs, modelNames, plotSpec.measureLabel, plotSpec.validityLabel, ...
        metricVar, metricLabel);
    statsAll = [statsAll; statsTable]; %#ok<AGROW>
    
    % Plot
    saveStem = sprintf('%s_%s_averaged_violin', metricFileTag, plotSpec.fileTag);
    plot_split_violins(r2Matrix, rowInfo, modelLabels, colors, modelPairs, ...
        statsTable, plotSpec.measureLabel, plotSpec.validityLabel, metricLabel, ...
        figureDir, saveStem, plotSpec.ylims);
end

% Save stats
statsName = 'adjusted_r2_split_M4.csv';
writetable(statsAll, fullfile(statsDir, statsName));

% 2. POOLED VALID & INVALID ANALYSIS (n = 38)
fprintf('Running pooled Valid & Invalid analysis (n = 38)...\n');
drawnow('update');

pooledSpecs = struct( ...
    'measure', {'Perf', 'Visi'}, ...
    'measureLabel', {'Accuracy', 'Visibility'}, ...
    'fileTag', {'accuracy_pooled', 'visibility_pooled'}, ...
    'ylims', {[-0.1, 0.8], [-0.1, 0.8]} ...
);

statsPooledAll = table();

for plotIndex = 1:numel(pooledSpecs)
    plotSpec = pooledSpecs(plotIndex);
    
    % Build matrix: average Left and Right within subject for this measure (pooling validity)
    [r2Matrix, rowInfo] = build_pooled_metric_matrix( ...
        results, plotSpec.measure, modelNames, metricVar);
    
    % Wilcoxon signed-rank tests (validityLabel is 'Pooled')
    statsTable = pairwise_wilcoxon( ...
        r2Matrix, modelPairs, modelNames, plotSpec.measureLabel, 'Pooled', ...
        metricVar, metricLabel);
    statsPooledAll = [statsPooledAll; statsTable]; %#ok<AGROW>
    
    % Plot
    saveStem = sprintf('%s_%s_averaged_violin', metricFileTag, plotSpec.fileTag);
    plot_split_violins(r2Matrix, rowInfo, modelLabels, colors, modelPairs, ...
        statsTable, plotSpec.measureLabel, 'Pooled', metricLabel, ...
        figureDir, saveStem, plotSpec.ylims);
end

% Save pooled stats
statsPooledName = 'adjusted_r2_pooled_M4.csv';
writetable(statsPooledAll, fullfile(statsDir, statsPooledName));

fprintf('--- FIGS4 ADJUSTED R2 VIOLIN SPLIT  COMPLETE ---\n');


function [metricMatrix, rowInfo] = build_split_metric_matrix(results, measureName, validityName, modelNames, metricVar)
    % Filter by measure and validity
    subRows = results(results.measure == measureName & results.validity == validityName, :);
    if isempty(subRows)
        error('No rows found for measure "%s" and validity "%s".', measureName, validityName);
    end

    % Get unique subjects
    uniqueSubjs = unique(subRows(:, {'subject_index', 'subject'}), 'rows', 'stable');
    
    metricMatrix = nan(height(uniqueSubjs), numel(modelNames));
    rowInfo = uniqueSubjs;
    
    for r = 1:height(uniqueSubjs)
        subjIdx = uniqueSubjs.subject_index(r);
        subjMask = (subRows.subject_index == subjIdx);
        
        for m = 1:numel(modelNames)
            modelMask = subjMask & (subRows.model == modelNames(m));
            vals = subRows.(metricVar)(modelMask);
            metricMatrix(r, m) = mean(vals, 'omitnan');
        end
    end
end


function [metricMatrix, rowInfo] = build_pooled_metric_matrix(results, measureName, modelNames, metricVar)
    % Filter by measure only (pooling Valid and Invalid)
    subRows = results(results.measure == measureName, :);
    if isempty(subRows)
        error('No rows found for measure "%s".', measureName);
    end

    % Get unique subjects and validity combinations
    uniqueSubjs = unique(subRows(:, {'subject_index', 'subject', 'validity'}), 'rows', 'stable');
    
    metricMatrix = nan(height(uniqueSubjs), numel(modelNames));
    rowInfo = uniqueSubjs;
    
    for r = 1:height(uniqueSubjs)
        subjIdx = uniqueSubjs.subject_index(r);
        valName = uniqueSubjs.validity(r);
        subjMask = (subRows.subject_index == subjIdx & subRows.validity == valName);
        
        for m = 1:numel(modelNames)
            modelMask = subjMask & (subRows.model == modelNames(m));
            vals = subRows.(metricVar)(modelMask);
            metricMatrix(r, m) = mean(vals, 'omitnan');
        end
    end
end


function statsTable = pairwise_wilcoxon(metricMatrix, modelPairs, modelNames, measureLabel, validityLabel, metricVar, metricLabel)
    numPairs = size(modelPairs, 1);
    pRaw = nan(numPairs, 1);
    wVal = nan(numPairs, 1);
    meanDiff = nan(numPairs, 1);
    semDiff = nan(numPairs, 1);
    n = zeros(numPairs, 1);
    comparison = strings(numPairs, 1);

    for p = 1:numPairs
        m1 = modelPairs(p, 1);
        m2 = modelPairs(p, 2);
        validRows = all(isfinite(metricMatrix(:, [m1, m2])), 2);
        n(p) = nnz(validRows);
        comparison(p) = modelNames(m1) + " - " + modelNames(m2);

        if n(p) == 0
            continue;
        end

        x = metricMatrix(validRows, m1);
        y = metricMatrix(validRows, m2);
        d = x - y;
        meanDiff(p) = mean(d);
        semDiff(p) = std(d) / sqrt(n(p));

        [pRaw(p), ~, stats] = signrank(d, 0);
        if isfield(stats, 'signedrank')
            wVal(p) = stats.signedrank;
        end
    end

    pBonf = min(pRaw .* numPairs, 1);
    model1 = reshape(modelNames(modelPairs(:, 1)), [], 1);
    model2 = reshape(modelNames(modelPairs(:, 2)), [], 1);
    statsTable = table( ...
        repmat(string(metricVar), numPairs, 1), ...
        repmat(string(metricLabel), numPairs, 1), ...
        repmat(string(measureLabel), numPairs, 1), ...
        repmat(string(validityLabel), numPairs, 1), ...
        comparison, ...
        model1, ...
        model2, ...
        n, meanDiff, semDiff, pRaw, pBonf, wVal, ...
        'VariableNames', {'metric', 'metric_label', 'measure', 'validity', 'comparison', 'model_1', 'model_2', ...
        'n', 'mean_difference', 'sem', 'p_uncorrected', 'p_bonferroni', 'W'} ...
    );
end


function plot_split_violins(r2Matrix, ~, modelLabels, colors, modelPairs, ...
    statsTable, measureLabel, validityLabel, metricLabel, figureDir, saveStem, yLimits)

    fig = figure('Color', 'w');
    set(fig, 'Position', [100, 100, 820, 700]);
    ax = axes(fig);
    hold(ax, 'on');

    xPositions = 1:size(r2Matrix, 2);
    violinWidth = 0.17;

    % Draw violin density patches
    for m = 1:size(r2Matrix, 2)
        draw_violin(ax, xPositions(m), r2Matrix(:, m), colors(m, :), violinWidth);
    end

    % Draw grey dotted lines for each subject connecting their averaged values
    for r = 1:size(r2Matrix, 1)
        plot(ax, xPositions, r2Matrix(r, :), ':', ...
            'Color', [0.68, 0.68, 0.68], 'LineWidth', 0.35);
    end

    % Draw subject scatter points
    for m = 1:size(r2Matrix, 2)
        scatter(ax, repmat(xPositions(m), size(r2Matrix, 1), 1), r2Matrix(:, m), ...
            10, colors(m, :), 'filled', 'MarkerFaceAlpha', 0.76, ...
            'MarkerEdgeColor', [0.15, 0.15, 0.15], 'MarkerEdgeAlpha', 0.30);
    end

    ySpan = diff(yLimits);
    bracketBase = yLimits(2) - 0.20 * ySpan;
    bracketStep = 0.032 * ySpan;
    textOffset = 0.014 * ySpan;

    for p = 1:size(modelPairs, 1)
        m1 = modelPairs(p, 1);
        m2 = modelPairs(p, 2);
        y = bracketBase + (p - 1) * bracketStep;
        pBonf = statsTable.p_bonferroni(p);
        pText = format_p_text(pBonf);

        plot(ax, [m1, m2], [y, y], ...
            '-', 'Color', [0.45, 0.45, 0.45], 'LineWidth', 1);
        text(ax, mean([m1, m2]), y + textOffset, ...
            pText, ...
            'HorizontalAlignment', 'center', 'FontSize', 9);
    end

    set(ax, 'XTick', xPositions, 'XTickLabel', modelLabels, 'TickDir', 'out');
    xlim(ax, [0.5, numel(xPositions) + 0.5]);
    ylim(ax, yLimits);
    yticks(ax, yLimits(1):0.1:yLimits(2));
    ylabel(ax, metricLabel);
    title(ax, sprintf('%s (%s) | %s', measureLabel, validityLabel, metricLabel));
    axis(ax, 'square');
    box(ax, 'off');
    grid(ax, 'off');
    hold(ax, 'off');

    saveas(fig, fullfile(figureDir, [saveStem '.png']));
    exportgraphics(fig, fullfile(figureDir, [saveStem '.pdf']), 'ContentType', 'vector');
    close(fig);
end


function draw_violin(ax, xCenter, values, color, width)
    values = values(isfinite(values));
    if isempty(values)
        return;
    end

    if isscalar(unique(values))
        yGrid = values(1) + [-0.5, 0.5];
        density = [0.15, 0.15];
    else
        [density, yGrid] = ksdensity(values, 'NumPoints', 160);
        density = density(:)';
        yGrid = yGrid(:)';
        density = density ./ max(density) .* width;
    end

    patch(ax, [xCenter - density, fliplr(xCenter + density)], ...
        [yGrid, fliplr(yGrid)], color, ...
        'FaceAlpha', 0.22, 'EdgeColor', 'none');

    q = quantile(values, [0.25, 0.50, 0.75]);
    plot(ax, [xCenter - width, xCenter + width], [q(2), q(2)], ...
        '-', 'Color', color, 'LineWidth', 1.6);
    plot(ax, [xCenter, xCenter], [q(1), q(3)], '-', 'Color', color, 'LineWidth', 1.0);
end


function pText = format_p_text(pValue)
    if isnan(pValue)
        pText = 'ns';
    elseif pValue < 0.001
        pText = '***';
    elseif pValue < 0.01
        pText = '**';
    elseif pValue < 0.05
        pText = '*';
    else
        pText = 'ns';
    end
end
