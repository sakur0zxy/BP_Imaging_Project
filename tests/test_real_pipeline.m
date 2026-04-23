function tests = test_real_pipeline
tests = functiontests(localfunctions);
end

function testDefaultRealConfigDoesNotDegrade(testCase)
cfg = default_real_config();

verifyFalse(testCase, cfg.degradation.enable);
verifyEqual(testCase, cfg.degradation.mode, 'none');
verifyEqual(testCase, cfg.degradation.missingRatio, 0);
end

function testRealPipelineSmoke(testCase)
startup();

rootDir = tempname;
mkdir(rootDir);
dataDir = fullfile(rootDir, 'real_data');
mkdir(dataDir);

data = struct();
data.x = 0:15;
data.y = zeros(1, 16);
data.z = 10 * ones(1, 16);
data.fp = complex(ones(8, 16));
data.freq = linspace(9.5e9, 9.6e9, 8);
save(fullfile(dataDir, 'data_3dsar_pass1_az001_VV.mat'), 'data');

cfg = load_real_config(struct( ...
    'path', struct('projectRoot', rootDir, 'realDataRoot', dataDir), ...
    'source', struct('numFiles', 1), ...
    'output', struct('enableSave', false), ...
    'analysis', struct( ...
        'enablePointAnalysis', false, ...
        'recoveryEvaluation', struct('enable', false)), ...
    'degradation', struct('mode', 'none', 'enable', false), ...
    'imaging', struct('grid', struct('numPixels', 32, 'xLimits', [-5, 5], 'yLimits', [-5, 5]), ...
                      'showProgress', false)));

result = run_real_data_pipeline(cfg);

verifyEqual(testCase, size(result.image.image), [32, 32]);
verifyEqual(testCase, result.degradation.totalMissing, 0);
verifyEqual(testCase, result.image.grid.numPixels, 32);
verifyEqual(testCase, result.image.meta.usedAzimuthCount, 16);
verifyGreaterThan(testCase, result.image.peak.value, 0);
verifyEqual(testCase, result.recoveryEvaluation.status, 'disabled');
verifyEqual(testCase, result.summary.recoveryEvaluationStatus, 'disabled');
verifyTrue(testCase, isfield(result.summary, 'referenceCacheHit'));
verifyEqual(testCase, result.summary.referenceCacheHit, false);
verifySubstring(testCase, result.summary.referenceCacheFolder, 'real_data_baseline_');

cacheDir = fullfile(rootDir, 'cache', result.summary.referenceCacheFolder);
verifyTrue(testCase, exist(cacheDir, 'dir') == 7);
verifyTrue(testCase, exist(fullfile(cacheDir, 'image_data.mat'), 'file') == 2);
verifyTrue(testCase, exist(fullfile(cacheDir, 'parameters_info.txt'), 'file') == 2);
verifyTrue(testCase, exist(fullfile(cacheDir, '缓存说明.txt'), 'file') == 2);
end
