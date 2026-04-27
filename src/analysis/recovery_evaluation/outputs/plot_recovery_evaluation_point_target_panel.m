function panelFile = plot_recovery_evaluation_point_target_panel(recoveryEvaluation, panelFile, showPanel)
%PLOT_RECOVERY_EVALUATION_POINT_TARGET_PANEL 生成点目标细节对比图。
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

figureHandle = figure('Name', 'Recovery Evaluation Point Target Panel', ...
    'Color', 'w', 'Visible', visibility);
cleanup = onCleanup(@() localCloseFigure(figureHandle, showPanel)); %#ok<NASGU>

numCases = numel(caseNames);
layout = tiledlayout(3, numCases, 'Padding', 'compact', 'TileSpacing', 'compact');
referencePeak = localFindReferencePeak(recoveryEvaluation, caseNames);
colors = lines(max(numCases, 1));

for idx = 1:numCases
    caseResult = recoveryEvaluation.cases.(caseNames{idx});

    nexttile(layout, idx);
    pointImage = localGetPointImage(caseResult);
    if isempty(pointImage)
        axis off;
        text(0.05, 0.55, localPointTargetStatus(caseResult), 'Interpreter', 'none');
    else
        imagesc(localBuildPreviewImage(pointImage, referencePeak));
        axis image off;
        colormap jet;
    end
    title(strrep(caseResult.displayName, '_', '\_'));
end

nexttile(layout, numCases + 1, [1, numCases]);
localPlotProfileOverlay(recoveryEvaluation, caseNames, colors, 'xProfile', 'X profile overlay');

nexttile(layout, 2 * numCases + 1, [1, numCases]);
localPlotProfileOverlay(recoveryEvaluation, caseNames, colors, 'yProfile', 'Y profile overlay');

if ~isempty(panelFile)
    saveas(figureHandle, panelFile);
end
end

function referencePeak = localFindReferencePeak(recoveryEvaluation, caseNames)
referencePeak = 0;
for idx = 1:numel(caseNames)
    caseResult = recoveryEvaluation.cases.(caseNames{idx});
    pointImage = localGetPointImage(caseResult);
    if ~isempty(pointImage)
        referencePeak = max(referencePeak, max(abs(pointImage(:))));
    end
end

if referencePeak <= 0 || ~isfinite(referencePeak)
    referencePeak = 1;
end
end

function previewImage = localBuildPreviewImage(imageData, referencePeak)
imageDb = 20 * log10(abs(imageData) / referencePeak + eps);
imageDb = max(imageDb, -40);
previewImage = (imageDb + 40) / 40;
end

function pointImage = localGetPointImage(caseResult)
pointImage = [];
pointTarget = localGetNestedField(caseResult, {'artifacts', 'analysisResult', 'pointTarget'}, struct());
if ~isstruct(pointTarget) || ~strcmp(localGetField(pointTarget, 'status', ''), 'completed')
    return;
end

pointImage = localGetNestedField(pointTarget, {'upsampled', 'image'}, []);
if isempty(pointImage)
    pointImage = localGetNestedField(pointTarget, {'cutout', 'image'}, []);
end
end

function localPlotProfileOverlay(recoveryEvaluation, caseNames, colors, profileName, titleText)
hold on;
plottedLabels = {};
for idx = 1:numel(caseNames)
    caseResult = recoveryEvaluation.cases.(caseNames{idx});
    profileDb = localGetNestedField(caseResult, ...
        {'artifacts', 'analysisResult', 'pointTarget', profileName, 'profileDb'}, []);
    if isempty(profileDb)
        continue;
    end

    plot(profileDb(:), 'LineWidth', 1.1, 'Color', colors(idx, :));
    plottedLabels{end + 1} = caseResult.displayName; %#ok<AGROW>
end
hold off;
grid on;
xlabel('Sample');
ylabel('dB');
title(titleText);
if isempty(plottedLabels)
    axis off;
    text(0.05, 0.55, 'No completed pointTarget profile.', 'Interpreter', 'none');
else
    legend(strrep(plottedLabels, '_', '\_'), 'Location', 'best');
end
end

function statusText = localPointTargetStatus(caseResult)
statusText = localGetNestedField(caseResult, ...
    {'artifacts', 'analysisResult', 'pointTarget', 'status'}, 'missing pointTarget');
statusText = sprintf('pointTarget: %s', statusText);
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
