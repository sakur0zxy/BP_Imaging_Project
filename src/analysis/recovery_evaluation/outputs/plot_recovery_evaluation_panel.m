function panelFile = plot_recovery_evaluation_panel(recoveryEvaluation, panelFile, showPanel)
%PLOT_RECOVERY_EVALUATION_PANEL 生成恢复评估总览图。
if nargin < 2
    panelFile = '';
end
if nargin < 3
    showPanel = false;
end

caseNames = recoveryEvaluation.config.caseNames;
visibility = 'off';
if showPanel
    visibility = 'on';
end

figureHandle = figure('Name', 'Recovery Evaluation Panel', 'Color', 'w', 'Visible', visibility);
cleanup = onCleanup(@() localCloseFigure(figureHandle, showPanel)); %#ok<NASGU>
tiledlayout(2, numel(caseNames), 'Padding', 'compact', 'TileSpacing', 'compact');

for idx = 1:numel(caseNames)
    caseResult = recoveryEvaluation.cases.(caseNames{idx});

    nexttile(idx);
    previewImage = localBuildPreviewImage(caseResult.artifacts.imageResult.image);
    imagesc(previewImage);
    axis image off;
    colormap jet;
    title(strrep(caseResult.displayName, '_', '\_'));

    nexttile(idx + numel(caseNames));
    localDrawMetricCard(caseResult);
end

if ~isempty(panelFile)
    saveas(figureHandle, panelFile);
end
end

function previewImage = localBuildPreviewImage(imageData)
imageAmp = abs(imageData);
maxValue = max(imageAmp(:));
if maxValue <= 0
    previewImage = zeros(size(imageAmp), 'double');
    return;
end

imageDb = 20 * log10(imageAmp / maxValue + eps);
imageDb = max(imageDb, -40);
previewImage = (imageDb + 40) / 40;
end

function localDrawMetricCard(caseResult)
axis off;
metricLines = localBuildMetricLines(caseResult);
text(0.03, 0.95, strjoin(metricLines, newline), ...
    'Units', 'normalized', ...
    'VerticalAlignment', 'top', ...
    'Interpreter', 'none', ...
    'FontName', 'Consolas', ...
    'FontSize', 8);
end

function metricLines = localBuildMetricLines(caseResult)
metricLines = { ...
    sprintf('status: %s', localGetField(caseResult, 'status', '')); ...
    sprintf('recovery: %s', localGetNestedField(caseResult, {'metrics', 'recovery', 'status'}, ''))};

peakValue = localGetNestedField(caseResult, {'metrics', 'peak', 'value'}, NaN);
metricLines{end + 1} = sprintf('peak: %s', localFormatNumber(peakValue, '%.4g'));

pointMetrics = localGetNestedField(caseResult, {'metrics', 'pointTarget'}, struct('available', false));
if isstruct(pointMetrics) && localGetField(pointMetrics, 'available', false)
    metricLines{end + 1} = sprintf('PSLR: %s dB', ...
        localFormatNumber(localGetField(pointMetrics, 'avgPslrDb', NaN), '%.2f'));
    metricLines{end + 1} = sprintf('ISLR: %s dB', ...
        localFormatNumber(localGetField(pointMetrics, 'avgIslrDb', NaN), '%.2f'));
    metricLines{end + 1} = sprintf('IRW: %s m', ...
        localFormatNumber(localGetField(pointMetrics, 'avgIrwPhysical', NaN), '%.4g'));
else
    pointStatus = localGetNestedField(caseResult, ...
        {'artifacts', 'analysisResult', 'pointTarget', 'status'}, 'missing');
    metricLines{end + 1} = sprintf('pointTarget: %s', pointStatus);
end
end

function textValue = localFormatNumber(value, formatText)
if isnumeric(value) && isscalar(value) && isfinite(value)
    textValue = sprintf(formatText, value);
elseif isnumeric(value) && isscalar(value) && isinf(value)
    if value > 0
        textValue = 'Inf';
    else
        textValue = '-Inf';
    end
elseif isnumeric(value) && isscalar(value) && isnan(value)
    textValue = 'NaN';
else
    textValue = '';
end
end

function value = localGetField(data, fieldName, defaultValue)
value = defaultValue;
if isstruct(data) && isfield(data, fieldName)
    value = data.(fieldName);
end
end

function value = localGetNestedField(data, fieldPath, defaultValue)
value = defaultValue;
current = data;
for idx = 1:numel(fieldPath)
    fieldName = fieldPath{idx};
    if ~isstruct(current) || ~isfield(current, fieldName)
        return;
    end
    current = current.(fieldName);
end
value = current;
end

function localCloseFigure(figureHandle, showPanel)
if ishghandle(figureHandle) && ~showPanel
    close(figureHandle);
end
end
