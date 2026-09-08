%% Generate curve-fitting figures from Fig5_Curvefitting_results.csv
% Saves primary M1-M3 figures as PNG and PDF.

fprintf('--- FIG5 CURVE FIGURE GENERATION  START ---\n');
drawnow('update');
scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptDir);

behavDir = fullfile(projectRoot, '01_Data', '02_BehavioralData');
csvPath = fullfile(projectRoot, '01_Data', '04_CurvefittingData', ...
    'Fig5_Curvefitting_results.csv');
saveRoot = fullfile(projectRoot, '03_Figure', 'Figure5');

timeMs = (50:10:1500)';
timeSec = timeMs / 1000;

if ~exist(csvPath, 'file')
    error('Result CSV not found: %s', csvPath);
end

results = readtable(csvPath, 'TextType', 'string');
requiredVars = ["condition_file", "subject_index", "subject", "model", ...
    "frequency_hz", "adjusted_r2", "a", "b", "lambda", "sigma", "c", "k"];
missingVars = setdiff(requiredVars, string(results.Properties.VariableNames));
if ~isempty(missingVars)
    error('Missing required CSV column(s): %s', strjoin(missingVars, ', '));
end

conditionFiles = unique(string(results.condition_file), 'stable');

saveDir = saveRoot;
if ~exist(saveDir, 'dir'), mkdir(saveDir); end

modelNames = {'M1', 'M2', 'M3'};
numModels = numel(modelNames);

fprintf('Generating figures under %s\n', saveDir);
drawnow('update');

for c = 1:numel(conditionFiles)
    conditionFile = conditionFiles(c);
    conditionName = char(conditionFile);
    fprintf('  Condition: %s\n', conditionName);
    drawnow('update');

    loaded = load(fullfile(behavDir, conditionName));
    groupData = loaded.Group_data;
    if contains(conditionName, ' Perf ')
        yLabelText = 'Accuracy (%)';
    else
        yLabelText = 'Visibility';
    end

    conditionDir = fullfile(saveDir, erase(conditionName, '.mat'));
    if ~exist(conditionDir, 'dir'), mkdir(conditionDir); end

    for subjectIndex = 1:size(groupData, 1)
        subjectRows = results( ...
            string(results.condition_file) == conditionFile & ...
            results.subject_index == subjectIndex, :);
        if isempty(subjectRows)
            warning('No fitted rows for %s subject %d', conditionName, subjectIndex);
            continue;
        end

        y = groupData(subjectIndex, :)';
        yFits = nan(numel(timeMs), numel(modelNames));

        fig = figure('Visible', 'off', 'Color', 'w');
        set(fig, 'Position', [50, 50, 500 * numModels, 430]);
        tiledlayout(1, numModels, 'TileSpacing', 'compact', 'Padding', 'compact');

        subjectName = string(subjectRows.subject(1));

        for m = 1:numModels
            modelName = modelNames{m};
            modelRow = subjectRows(string(subjectRows.model) == modelName, :);
            if isempty(modelRow)
                warning('No %s row for %s subject %d', modelName, conditionName, subjectIndex);
                continue;
            end

            rawFit = predict_fit(modelRow, modelName, timeSec);
            yFits(:, m) = rawFit;

            nexttile;
            plot(timeSec, y, 'Color', [0, 0, 0], 'LineWidth', 3.0);
            hold on;
            plot(timeSec, rawFit, 'Color', model_color(modelName), 'LineWidth', 4.4);
            xline(0.05, 'k:', 'LineWidth', 2.0);

            title(modelName);
            xlabel('Time (s)');

            xlim([-0.05, 1.5]);
            set(gca, 'XTick', [0.5, 1.0]);
            set(gca, 'XTickLabel', {'0.5', '1'});

            grid off;
            box off;
            axis square;
            set(gca, 'LineWidth', 3.0);

            if m == 1
                ylabel(yLabelText);
            end
        end

        yAll = [y; yFits(:)];
        yAll = yAll(isfinite(yAll));
        if ~isempty(yAll)
            yr = max(yAll) - min(yAll);
            if yr == 0, yr = 1; end
            yLimits = [min(yAll) - 0.06 * yr, max(yAll) + 0.06 * yr];

            axesList = findall(fig, 'Type', 'axes');
            set(axesList, 'YLim', yLimits);

            if contains(conditionName, ' Perf ')
                tickStart = ceil(yLimits(1) / 10) * 10;
                tickEnd = floor(yLimits(2) / 10) * 10;
                yTicksVal = tickStart : 10 : tickEnd;
            else
                yTicksVal = ceil(yLimits(1)) : floor(yLimits(2));
            end
            if isempty(yTicksVal)
                yTicksVal = linspace(yLimits(1), yLimits(2), 3);
            end
            set(axesList, 'YTick', yTicksVal);
        end

        outName = sprintf('%02d_%s', subjectIndex, char(subjectName));
        print(fig, fullfile(conditionDir, [outName '.png']), '-dpng', '-r180');
        exportgraphics(fig, fullfile(conditionDir, [outName '.pdf']), 'ContentType', 'vector');
        close(fig);
    end
end

fprintf('--- FIG5 CURVE FIGURE GENERATION  COMPLETE ---\n');


function yhat = predict_fit(row, modelName, timeSec)
    freqHz = row.frequency_hz(1);
    trend = row.c(1) .* timeSec + row.k(1);

    if strcmp(modelName, 'M1')
        yhat = row.a(1) .* bounded_exp(row.lambda(1) .* timeSec) + trend;
        return;
    end

    phase = 2 * pi * freqHz .* timeSec;
    oscillation = row.a(1) .* cos(phase) + row.b(1) .* sin(phase);

    if strcmp(modelName, 'M2')
        yhat = oscillation + trend;
        return;
    end

    if strcmp(modelName, 'M3')
        envelope = bounded_exp(row.lambda(1) .* timeSec);
        yhat = envelope .* oscillation + trend;
        return;
    end

    error('Unknown model name: %s', modelName);
end


function color = model_color(modelName)
    if strcmp(modelName, 'M1')
        color = [0.85, 0.33, 0.10];
    elseif strcmp(modelName, 'M2')
        color = [0.47, 0.67, 0.19];
    elseif strcmp(modelName, 'M3')
        color = [0.49, 0.18, 0.56];
    else
        color = [1, 0, 0];
    end
end


function y = bounded_exp(x)
    y = exp(min(max(x, -60), 20));
end
