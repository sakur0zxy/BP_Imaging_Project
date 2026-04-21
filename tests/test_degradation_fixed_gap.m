function tests = test_degradation_fixed_gap
tests = functiontests(localfunctions);
end

function testFixedGapMask(testCase)
config = struct('fixedGapRanges', [4, 6], 'missingRatio', 0.3);
[mask, gaps] = apply_fixed_gap(10, config);

verifyEqual(testCase, gaps, [4, 6]);
verifyFalse(testCase, any(mask(4:6)));
verifyEqual(testCase, sum(mask), 7);
end

