function caseItems = build_recovery_evaluation_cases(evalConfig, context)
%BUILD_RECOVERY_EVALUATION_CASES 组织待评估案例集合。
if nargin < 2
    context = struct();
end

assert(isstruct(context) && isscalar(context), ...
    'recovery evaluation context 必须是标量结构体。');
assert(isfield(context, 'sourceReference'), ...
    'recovery evaluation context 缺少 sourceReference。');
assert(isfield(context, 'degradedSourceData'), ...
    'recovery evaluation context 缺少 degradedSourceData。');

sourceReference = validate_source_data(context.sourceReference);
degradedSourceData = validate_source_data(context.degradedSourceData);

caseItems = struct();
for idx = 1:numel(evalConfig.caseNames)
    caseName = evalConfig.caseNames{idx};
    switch caseName
        case 'full'
            payload = struct( ...
                'sourceData', sourceReference, ...
                'referenceSourceData', sourceReference, ...
                'fullImageResult', localGetField(context, 'fullImageResult', []));
            caseType = 'full';
            sourceTag = 'reference';
            displayName = 'Full';

        case 'interrupted'
            payload = struct( ...
                'sourceData', degradedSourceData, ...
                'referenceSourceData', sourceReference);
            caseType = 'interrupted';
            sourceTag = 'degraded';
            displayName = 'Interrupted';

        case 'recovered_cs_1d'
            payload = struct( ...
                'sourceData', degradedSourceData, ...
                'referenceSourceData', sourceReference, ...
                'recoveryMethod', 'cs_1d');
            caseType = 'recovered';
            sourceTag = 'recovered';
            displayName = 'Recovered CS 1D';

        case 'recovered_cs_2d'
            payload = struct( ...
                'sourceData', degradedSourceData, ...
                'referenceSourceData', sourceReference, ...
                'recoveryMethod', 'cs_2d');
            caseType = 'recovered';
            sourceTag = 'recovered';
            displayName = 'Recovered CS 2D';

        otherwise
            error('build_recovery_evaluation_cases:UnsupportedCase', ...
                '不支持的 recovery evaluation case: %s', caseName);
    end

    caseItems.(caseName) = struct( ...
        'caseName', caseName, ...
        'caseType', caseType, ...
        'mode', evalConfig.evaluationMode, ...
        'payload', payload, ...
        'sourceTag', sourceTag, ...
        'status', 'ready', ...
        'meta', struct('displayName', displayName));
end
end

function value = localGetField(data, fieldName, defaultValue)
value = defaultValue;
if isstruct(data) && isfield(data, fieldName)
    value = data.(fieldName);
end
end
