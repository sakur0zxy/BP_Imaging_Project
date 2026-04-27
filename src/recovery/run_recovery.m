function result = run_recovery(sourceData, recoveryConfig, referenceSourceData)
%RUN_RECOVERY 恢复模块唯一入口。
if nargin < 2
    error('run_recovery:NotEnoughInputs', ...
        '至少需要 sourceData 和 recoveryConfig。');
end
if nargin < 3
    referenceSourceData = [];
end

sourceData = validate_source_data(sourceData);
if ~isempty(referenceSourceData)
    referenceSourceData = validate_source_data(referenceSourceData);
end

recoveryConfig = prepare_recovery_config(recoveryConfig);
problem = build_recovery_problem(sourceData, referenceSourceData);

if ~recoveryConfig.enable
    result = pack_recovery_result('disabled', 'recovery-disabled', ...
        recoveryConfig.method, sourceData, problem, sourceData.echo, struct(), struct());
    return;
end

if recoveryConfig.common.skipWhenNoMissing && ~any(problem.missingMatrixMask(:))
    result = pack_recovery_result('skipped', 'no-missing-samples', ...
        recoveryConfig.method, sourceData, problem, sourceData.echo, struct(), struct());
    return;
end

registry = get_recovery_registry();
methodEntry = registry.(recoveryConfig.method);
methodConfig = get_method_config(recoveryConfig, recoveryConfig.method);
methodResult = methodEntry.handler(problem, methodConfig, recoveryConfig.common);
metrics = compute_recovery_metrics(methodResult.echo, problem);

result = pack_recovery_result('completed', '', recoveryConfig.method, ...
    sourceData, problem, methodResult.echo, methodResult.info, metrics);
end
