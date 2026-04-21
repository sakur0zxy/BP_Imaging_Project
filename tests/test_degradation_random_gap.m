function tests = test_degradation_random_gap
tests = functiontests(localfunctions);
end

function testRandomGapMaskIsDeterministic(testCase)
config = struct( ...
    'numSegments', 4, ...
    'missingRatio', 0.2, ...
    'gapMinMeters', 1, ...
    'gapMaxMeters', 3, ...
    'randomSeed', 42);

[maskA, gapsA, seedA] = apply_random_gap(20, 1, config);
[maskB, gapsB, seedB] = apply_random_gap(20, 1, config);

verifyEqual(testCase, seedA, seedB);
verifyEqual(testCase, maskA, maskB);
verifyEqual(testCase, gapsA, gapsB);
end

