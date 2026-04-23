function tests = test_contract_normalization
tests = functiontests(localfunctions);
end

function testNormalizeSourceData(testCase)
raw.track = struct('X', [0, 1, 2], 'Y', [0, 0, 0], 'Z', [1, 1, 1]);
raw.echo = complex(ones(4, 3));
raw.radar = struct('numRangeSamples', 4, 'numRangeSamplesUp', 8, 'rangeStep', 0.5);

source = normalize_source_data(raw, struct('kind', 'unit'));

verifyEqual(testCase, source.track.x, [0, 1, 2]);
verifyEqual(testCase, size(source.echo), [4, 3]);
verifyEqual(testCase, numel(source.mask), 3);
verifyEqual(testCase, source.radar.c, 3e8);
verifyEqual(testCase, source.meta.kind, 'unit');
end

function testValidateSourceDataRejectsBadMask(testCase)
raw.track = struct('x', [0, 1, 2], 'y', [0, 0, 0], 'z', [1, 1, 1]);
raw.echo = complex(ones(4, 3));
raw.radar = struct('numRangeSamples', 4, 'numRangeSamplesUp', 8, 'rangeStep', 0.5);

source = normalize_source_data(raw, struct('kind', 'unit'));
source.mask = [1, 0, 2];

verifyError(testCase, @() validate_source_data(source), ...
    'validate_source_data:InvalidMask');
end

function testValidateSourceDataRejectsMissingMeta(testCase)
raw.track = struct('x', [0, 1, 2], 'y', [0, 0, 0], 'z', [1, 1, 1]);
raw.echo = complex(ones(4, 3));
raw.radar = struct('numRangeSamples', 4, 'numRangeSamplesUp', 8, 'rangeStep', 0.5);

source = normalize_source_data(raw, struct('kind', 'unit'));
source = rmfield(source, 'meta');

verifyError(testCase, @() validate_source_data(source), ...
    'validate_source_data:MissingStruct');
end

function testValidateSourceDataNormalizesNumericMask(testCase)
raw.track = struct('x', [0, 1, 2], 'y', [0, 0, 0], 'z', [1, 1, 1]);
raw.echo = complex(ones(4, 3));
raw.radar = struct('numRangeSamples', 4, 'numRangeSamplesUp', 8, 'rangeStep', 0.5);

source = normalize_source_data(raw, struct('kind', 'unit'));
source.mask = [1, 0, 1];

source = validate_source_data(source);

verifyTrue(testCase, islogical(source.mask));
verifyEqual(testCase, source.mask, [true, false, true]);
end
