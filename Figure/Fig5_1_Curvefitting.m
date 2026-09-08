%% Fit curve-fitting and sensitivity-analysis models and save fit statistics.
% MATLAB implementation of Fig5_Curvefitting_sensitivity.py.
%
% Models:
% M1: Exponential decay + linear trend
% M2: Sustained oscillation + linear trend
% M3: Exponential damping oscillation + linear trend
% M4: Gaussian damping oscillation + linear trend

clear; clc;

scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptDir);

dataDir = fullfile(projectRoot, '01_Data', '02_BehavioralData');
frequencyDir = fullfile(projectRoot, '01_Data', '03_IRASAData');
outDir = fullfile(projectRoot, '01_Data', '04_CurvefittingData');
outName = 'Fig5_Curvefitting_results.csv';

timeMs = (50:10:1500)';
timeSec = timeMs ./ 1000;
subjectOrder = arrayfun(@(idx) sprintf('sub-%02d', idx), 1:19, 'UniformOutput', false);

positiveBound = 1e-9;
negativeBound = -1e-9;
lambdaStarts = [-16.0, -8.0, -4.0, -2.0, -1.0, -0.5, -0.1];
sigmaStarts = [0.05, 0.1, 0.2, 0.35, 0.5, 0.8, 1.2, 2.0, 4.0];

if ~exist(dataDir, 'dir')
    error('Behavioral data directory not found: %s', dataDir);
end
if ~exist(frequencyDir, 'dir')
    error('IRASA frequency directory not found: %s', frequencyDir);
end
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

models = makeModels(positiveBound, negativeBound);
conditionFiles = dir(fullfile(dataDir, '*.mat'));
if isempty(conditionFiles)
    error('No .mat files found in %s', dataDir);
end

rows = emptyResultRows();
rowIndex = 0;

for fileIndex = 1:numel(conditionFiles)
    conditionPath = fullfile(conditionFiles(fileIndex).folder, conditionFiles(fileIndex).name);
    peakPath = fullfile(frequencyDir, ['subject_peaks_' conditionFiles(fileIndex).name]);
    if ~exist(peakPath, 'file')
        continue;
    end
    conditionInfo = parseCondition(conditionFiles(fileIndex).name);
    data = loadCondition(conditionPath, numel(subjectOrder), numel(timeMs));
    frequencies = loadFrequency(frequencyDir, conditionFiles(fileIndex).name, numel(subjectOrder));

    fprintf('Processing %s\n', conditionFiles(fileIndex).name);

    for subjectIndex = 1:numel(subjectOrder)
        y = data(subjectIndex, :)';
        fitMask = isfinite(y);
        freqHz = frequencies(subjectIndex);

        for modelIndex = 1:numel(models)
            model = models(modelIndex);
            [params, residuals] = fitRawModel( ...
                y, model, freqHz, fitMask, timeSec, ...
                lambdaStarts, sigmaStarts, positiveBound);
            metrics = fitStatistics(y, fitMask, residuals, numel(params));

            rowIndex = rowIndex + 1;
            rows(rowIndex) = makeResultRow( ...
                conditionInfo, subjectIndex, subjectOrder{subjectIndex}, ...
                model, freqHz, metrics, params);
        end
    end
end

resultTable = struct2table(rows);
outPath = fullfile(outDir, outName);
writetable(resultTable, outPath);
fprintf('Wrote %d rows to %s\n', height(resultTable), outPath);


function models = makeModels(positiveBound, negativeBound)
models = struct( ...
    'name', {}, ...
    'label', {}, ...
    'paramNames', {}, ...
    'lower', {}, ...
    'upper', {});

models(1).name = 'M1';
models(1).label = 'Exponential Decay + Linear Trend';
models(1).paramNames = {'a', 'lambda', 'c', 'k'};
models(1).lower = [positiveBound, -Inf, -Inf, -Inf];
models(1).upper = [Inf, negativeBound, Inf, Inf];

models(2).name = 'M2';
models(2).label = 'Sustained Oscillation + Linear Trend';
models(2).paramNames = {'a', 'b', 'c', 'k'};
models(2).lower = [-Inf, -Inf, -Inf, -Inf];
models(2).upper = [Inf, Inf, Inf, Inf];

models(3).name = 'M3';
models(3).label = 'Damped Oscillation + Linear Trend';
models(3).paramNames = {'a', 'b', 'lambda', 'c', 'k'};
models(3).lower = [-Inf, -Inf, -Inf, -Inf, -Inf];
models(3).upper = [Inf, Inf, negativeBound, Inf, Inf];

models(4).name = 'M4';
models(4).label = 'Gaussian Damping + Linear Trend';
models(4).paramNames = {'a', 'b', 'sigma', 'c', 'k'};
models(4).lower = [-Inf, -Inf, positiveBound, -Inf, -Inf];
models(4).upper = [Inf, Inf, Inf, Inf, Inf];

end


function rows = emptyResultRows()
rows = struct( ...
    'condition_file', {}, ...
    'measure', {}, ...
    'validity', {}, ...
    'cue', {}, ...
    'subject_index', {}, ...
    'subject', {}, ...
    'model', {}, ...
    'model_label', {}, ...
    'frequency_hz', {}, ...
    'n_eval', {}, ...
    'n_parameters', {}, ...
    'sse', {}, ...
    'tss', {}, ...
    'rmse', {}, ...
    'mae', {}, ...
    'r2', {}, ...
    'adjusted_r2', {}, ...
    'a', {}, ...
    'lambda', {}, ...
    'b', {}, ...
    'sigma', {}, ...
    'c', {}, ...
    'k', {});
end


function info = parseCondition(fileName)
[~, stem, ext] = fileparts(fileName);
nameWithSpaces = [' ' stem ' '];

info.condition_file = [stem ext];
if contains(nameWithSpaces, ' Perf ')
    info.measure = 'Perf';
else
    info.measure = 'Visi';
end

if contains(nameWithSpaces, ' I ')
    info.validity = 'Invalid';
else
    info.validity = 'Valid';
end

cueMatch = regexp(stem, '\((Left|Right)-C\)', 'tokens', 'once');
if isempty(cueMatch)
    info.cue = 'Unknown';
else
    info.cue = cueMatch{1};
end
end


function data = loadCondition(path, nSubjects, nTimepoints)
loaded = load(path, 'Group_data');
if ~isfield(loaded, 'Group_data')
    error('%s does not contain Group_data', path);
end

data = double(loaded.Group_data);
expectedShape = [nSubjects, nTimepoints];
if ~isequal(size(data), expectedShape)
    if isequal(size(data), fliplr(expectedShape))
        data = data';
    else
        error('%s Group_data shape is %s; expected %s', ...
            path, mat2str(size(data)), mat2str(expectedShape));
    end
end
end


function frequencies = loadFrequency(frequencyDir, conditionFileName, nSubjects)
path = fullfile(frequencyDir, ['subject_peaks_' conditionFileName]);
loaded = load(path, 'all_subject_peaks');
if ~isfield(loaded, 'all_subject_peaks')
    error('%s does not contain all_subject_peaks', path);
end

peaks = double(loaded.all_subject_peaks);
if size(peaks, 1) ~= nSubjects && size(peaks, 2) == nSubjects
    peaks = peaks';
end

frequencies = peaks(:, 1);
if numel(frequencies) ~= nSubjects || any(~isfinite(frequencies)) || any(frequencies <= 0)
    error('Invalid frequency values in %s', path);
end
end


function [params, residuals] = fitRawModel( ...
    y, model, freqHz, fitMask, timeSec, ...
    lambdaStarts, sigmaStarts, positiveBound)

yFit = y(fitMask);
starts = startsForModel(model, y, fitMask, freqHz, timeSec, ...
    lambdaStarts, sigmaStarts, positiveBound);

bestRss = Inf;
bestParams = starts(1, :);
bestResiduals = predictModel(model, bestParams, freqHz, timeSec);
bestResiduals = bestResiduals(fitMask) - yFit;

for startIndex = 1:size(starts, 1)
    start = starts(startIndex, :);
    [candidateParams, candidateResiduals] = solveLeastSquares( ...
        model, start, yFit, fitMask, freqHz, timeSec);
    rss = sum(candidateResiduals .^ 2);
    if rss < bestRss
        bestRss = rss;
        bestParams = candidateParams;
        bestResiduals = candidateResiduals;
    end
end

params = bestParams;
residuals = bestResiduals;
end


function [params, residuals] = solveLeastSquares(model, start, yFit, fitMask, freqHz, timeSec)
residualFun = @(p) predictModel(model, p, freqHz, timeSec);
useLsqnonlin = exist('lsqnonlin', 'file') == 2;

if useLsqnonlin
    options = optimoptions( ...
        'lsqnonlin', ...
        'Display', 'off', ...
        'MaxFunctionEvaluations', 20000, ...
        'StepTolerance', 1e-9, ...
        'FunctionTolerance', 1e-9, ...
        'OptimalityTolerance', 1e-9);
    params = lsqnonlin( ...
        @(p) modelResiduals(p, residualFun, fitMask, yFit), ...
        start, model.lower, model.upper, options);
else
    options = optimset('Display', 'off', 'MaxFunEvals', 20000, 'MaxIter', 20000, ...
        'TolX', 1e-9, 'TolFun', 1e-9);
    objective = @(p) fallbackObjective(p, model, yFit, fitMask, freqHz, timeSec);
    params = fminsearch(objective, start, options);
    params = clipParams(params, model);
end

prediction = predictModel(model, params, freqHz, timeSec);
residuals = prediction(fitMask) - yFit;
end


function residuals = modelResiduals(params, residualFun, fitMask, yFit)
prediction = residualFun(params);
residuals = prediction(fitMask) - yFit;
end


function value = fallbackObjective(params, model, yFit, fitMask, freqHz, timeSec)
lowerViolation = max(model.lower - params, 0);
upperViolation = max(params - model.upper, 0);
finiteLower = isfinite(lowerViolation);
finiteUpper = isfinite(upperViolation);
penalty = 1e12 * (sum(lowerViolation(finiteLower) .^ 2) + sum(upperViolation(finiteUpper) .^ 2));

params = clipParams(params, model);
prediction = predictModel(model, params, freqHz, timeSec);
residuals = prediction(fitMask) - yFit;
value = sum(residuals .^ 2) + penalty;
end


function starts = startsForModel(model, y, fitMask, freqHz, timeSec, ...
    lambdaStarts, sigmaStarts, positiveBound)

switch model.name
    case 'M1'
        starts = nan(numel(lambdaStarts), numel(model.paramNames));
        for index = 1:numel(lambdaStarts)
            starts(index, :) = startForLambda(model, y, fitMask, freqHz, timeSec, ...
                lambdaStarts(index), positiveBound);
        end
    case 'M2'
        [cosT, sinT] = oscillationBasis(freqHz, timeSec);
        coef = linearCoef([cosT, sinT, timeSec, ones(size(timeSec))], y, fitMask);
        starts = clipParams(coef', model);
    case 'M3'
        starts = nan(numel(lambdaStarts), numel(model.paramNames));
        for index = 1:numel(lambdaStarts)
            starts(index, :) = startForLambda(model, y, fitMask, freqHz, timeSec, ...
                lambdaStarts(index), positiveBound);
        end
    case 'M4'
        starts = nan(numel(sigmaStarts), numel(model.paramNames));
        for index = 1:numel(sigmaStarts)
            starts(index, :) = startForDamping(model, y, fitMask, freqHz, timeSec, ...
                sigmaStarts(index), positiveBound);
        end
    otherwise
        error('Unknown model: %s', model.name);
end
end


function start = startForLambda(model, y, fitMask, freqHz, timeSec, lambdaValue, positiveBound)
envelope = boundedExp(lambdaValue .* timeSec);

switch model.name
    case 'M1'
        coef = linearCoef([envelope, timeSec, ones(size(timeSec))], y, fitMask);
        a = coef(1);
        c = coef(2);
        k = coef(3);

        if a <= 0
            [spread, head, tail] = dataScaleStart(y, fitMask);
            a = max([head - tail, 0.25 * spread, positiveBound]);
            coefTrend = linearCoef([timeSec, ones(size(timeSec))], y - a .* envelope, fitMask);
            c = coefTrend(1);
            k = coefTrend(2);
            if ~isfinite(k)
                k = tail;
            end
        end

        start = [a, lambdaValue, c, k];
    case 'M3'
        [cosT, sinT] = oscillationBasis(freqHz, timeSec);
        coef = linearCoef([envelope .* cosT, envelope .* sinT, timeSec, ones(size(timeSec))], y, fitMask);
        start = [coef(1), coef(2), lambdaValue, coef(3), coef(4)];
    otherwise
        error('%s does not use lambda starts', model.name);
end

start = clipParams(start, model);
end


function start = startForDamping(model, y, fitMask, freqHz, timeSec, dampingValue, positiveBound)
[cosT, sinT] = oscillationBasis(freqHz, timeSec);

switch model.name
    case 'M4'
        envelope = gaussianDamping(dampingValue, timeSec, positiveBound);
    otherwise
        error('%s does not use damping starts', model.name);
end

coef = linearCoef([envelope .* cosT, envelope .* sinT, timeSec, ones(size(timeSec))], y, fitMask);
start = clipParams([coef(1), coef(2), dampingValue, coef(3), coef(4)], model);
end


function coef = linearCoef(design, y, fitMask)
coef = design(fitMask, :) \ y(fitMask);
end


function params = clipParams(params, model)
params = min(max(params, model.lower), model.upper);
end


function yhat = predictModel(model, params, freqHz, timeSec)
switch model.name
    case 'M1'
        yhat = params(1) .* boundedExp(params(2) .* timeSec) + params(3) .* timeSec + params(4);
    case 'M2'
        [cosT, sinT] = oscillationBasis(freqHz, timeSec);
        yhat = params(1) .* cosT + params(2) .* sinT + params(3) .* timeSec + params(4);
    case 'M3'
        [cosT, sinT] = oscillationBasis(freqHz, timeSec);
        envelope = boundedExp(params(3) .* timeSec);
        yhat = envelope .* (params(1) .* cosT + params(2) .* sinT) + params(4) .* timeSec + params(5);
    case 'M4'
        [cosT, sinT] = oscillationBasis(freqHz, timeSec);
        envelope = gaussianDamping(params(3), timeSec, 1e-9);
        yhat = envelope .* (params(1) .* cosT + params(2) .* sinT) + params(4) .* timeSec + params(5);
    otherwise
        error('Unknown model: %s', model.name);
end
end


function [cosT, sinT] = oscillationBasis(freqHz, timeSec)
phase = 2 .* pi .* freqHz .* timeSec;
cosT = cos(phase);
sinT = sin(phase);
end


function y = boundedExp(x)
y = exp(min(max(x, -60), 20));
end


function envelope = gaussianDamping(sigma, timeSec, positiveBound)
sigma = max(double(sigma), positiveBound);
exponent = -(timeSec .^ 2) ./ (2 .* sigma .^ 2);
envelope = exp(min(max(exponent, -60), 0));
end


function [spread, head, tail] = dataScaleStart(y, fitMask)
yFit = y(fitMask);
spread = max([max(yFit) - min(yFit), std(yFit, 0, 'omitnan'), 1e-6]);
head = yFit(1);
tail = yFit(end);
end


function metrics = fitStatistics(y, fitMask, residuals, nModelParams)
yFit = y(fitMask);
valid = isfinite(yFit) & isfinite(residuals);
yFit = yFit(valid);
residuals = residuals(valid);
n = numel(yFit);

metrics.n_eval = n;
metrics.n_parameters = nModelParams;

if n == 0
    metrics.sse = NaN;
    metrics.tss = NaN;
    metrics.rmse = NaN;
    metrics.mae = NaN;
    metrics.r2 = NaN;
    metrics.adjusted_r2 = NaN;
    return;
end

metrics.sse = sum(residuals .^ 2);
metrics.tss = sum((yFit - mean(yFit)) .^ 2);
metrics.rmse = sqrt(metrics.sse ./ n);
metrics.mae = mean(abs(residuals));

if metrics.tss <= realmin
    if metrics.sse <= realmin
        metrics.r2 = 1;
    else
        metrics.r2 = NaN;
    end
else
    metrics.r2 = 1 - metrics.sse ./ metrics.tss;
end

if isfinite(metrics.r2) && n > nModelParams + 1
    metrics.adjusted_r2 = 1 - (1 - metrics.r2) .* (n - 1) ./ (n - nModelParams - 1);
else
    metrics.adjusted_r2 = NaN;
end
end


function row = makeResultRow(conditionInfo, subjectIndex, subject, model, freqHz, metrics, params)
row = struct( ...
    'condition_file', conditionInfo.condition_file, ...
    'measure', conditionInfo.measure, ...
    'validity', conditionInfo.validity, ...
    'cue', conditionInfo.cue, ...
    'subject_index', subjectIndex, ...
    'subject', subject, ...
    'model', model.name, ...
    'model_label', model.label, ...
    'frequency_hz', freqHz, ...
    'n_eval', metrics.n_eval, ...
    'n_parameters', metrics.n_parameters, ...
    'sse', metrics.sse, ...
    'tss', metrics.tss, ...
    'rmse', metrics.rmse, ...
    'mae', metrics.mae, ...
    'r2', metrics.r2, ...
    'adjusted_r2', metrics.adjusted_r2, ...
    'a', NaN, ...
    'lambda', NaN, ...
    'b', NaN, ...
    'sigma', NaN, ...
    'c', NaN, ...
    'k', NaN);

for index = 1:numel(model.paramNames)
    row.(model.paramNames{index}) = params(index);
end
end
