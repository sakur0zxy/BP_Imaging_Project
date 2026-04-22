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
    if localHasPointProfile(caseResult)
        plot(caseResult.artifacts.analysisResult.pointTarget.xProfile.profileDb, 'LineWidth', 1.0);
        grid on;
        xlabel('Sample');
        ylabel('dB');
        title(sprintf('PSLR %.2f | ISLR %.2f', ...
            caseResult.artifacts.analysisResult.pointTarget.xProfile.metrics.pslrDb, ...
            caseResult.artifacts.analysisResult.pointTarget.xProfile.metrics.islrDb));
    else
        axis off;
        text(0.05, 0.75, sprintf('status: %s', caseResult.status), 'Interpreter', 'none');
        text(0.05, 0.50, sprintf('peak: %.4g', caseResult.metrics.peak.value), 'Interpreter', 'none');
        text(0.05, 0.25, sprintf('recovery: %s', caseResult.metrics.recovery.status), 'Interpreter', 'none');
    end
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

function tf = localHasPointProfile(caseResult)
tf = isfield(caseResult, 'artifacts') && isstruct(caseResult.artifacts) ...
    && isfield(caseResult.artifacts, 'analysisResult') ...
    && isstruct(caseResult.artifacts.analysisResult) ...
    && isfield(caseResult.artifacts.analysisResult, 'pointTarget') ...
    && strcmp(localGetField(caseResult.artifacts.analysisResult.pointTarget, 'status', ''), 'completed');
end

function value = localGetField(data, fieldName, defaultValue)
value = defaultValue;
if isstruct(data) && isfield(data, fieldName)
    value = data.(fieldName);
end
end

function localCloseFigure(figureHandle, showPanel)
if ishghandle(figureHandle) && ~showPanel
    close(figureHandle);
end
end
