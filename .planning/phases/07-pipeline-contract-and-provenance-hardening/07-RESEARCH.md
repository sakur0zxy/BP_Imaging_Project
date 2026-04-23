# Phase 7: Pipeline Contract And Provenance Hardening - Research

**Date:** 2026-04-23
**Status:** Complete

## Research Summary

Phase 7 should be implemented as a low-risk hardening refactor, not a directory redesign.

The current code already has the right seams:

- `validate_source_data` is the natural sourceData contract gate.
- Real/sim pipelines already create `sourceData` before shared processing begins.
- Stages already return structured outputs.
- Output code already has run directory and summary helpers.

The safest path is to add missing contracts and metadata first, then extract common pipeline logic, then add dual-track stage/provenance fields.

## Existing Patterns To Reuse

### Source Contract

Use:

- `src/contracts/normalize_source_data.m`
- `src/contracts/validate_source_data.m`
- `docs/data_format.md`

Recommended direction:

- Keep `sourceData` as a MATLAB struct.
- Strengthen validation with clear errors.
- Document required/optional fields.
- Do not introduce classes.

### Stage Outputs

Current stage outputs:

- `apply_degradation` -> `[sourceData, degradationInfo]`
- `run_recovery` -> `recoveryResult`
- `bp_imaging` -> `imageResult`
- `point_target_analysis` -> `analysisResult`
- `run_recovery_evaluation` -> `recoveryEvaluation`

Recommended direction:

- Keep these outputs.
- Add a compact `result.stages` summary that references these outputs.
- Do not force every stage to change signature in this phase.

### Output Pattern

Use:

- `prepare_run_dir`
- `safe_save`
- existing `logs`, `mats`, `checkpoint`, and `summary.mat` behavior.

Recommended direction:

- Add `save_run_manifest.m`.
- Save manifest only when `runInfo.enabled` and manifest output is enabled.
- Prefer text/JSON-style manifest for human/debug use and `.mat` if needed later.

## Recommended Plan Shape

### Wave 1: Contract And Manifest Foundation

Purpose:

- Make sourceData and run provenance explicit before refactoring pipeline control flow.

Key files:

- `src/contracts/validate_source_data.m`
- `src/contracts/build_pipeline_provenance.m`
- `src/output/save_run_manifest.m`
- `docs/data_format.md`
- `docs/pipeline_notes.md`
- tests

### Wave 2: Common Pipeline Extraction

Purpose:

- Remove real/sim post-source duplication while preserving public entry points.

Key files:

- `src/pipelines/run_common_data_pipeline.m`
- `src/pipelines/run_real_data_pipeline.m`
- `src/pipelines/run_sim_data_pipeline.m`
- tests

### Wave 3: Stage And Provenance Dual Track

Purpose:

- Add stable `result.stages` / `result.provenance` fields without deleting old fields.

Key files:

- `src/contracts/build_pipeline_provenance.m`
- `src/pipelines/run_common_data_pipeline.m`
- `src/output/save_run_manifest.m`
- docs
- tests

## Risks And Controls

- Risk: extracting common pipeline changes behavior.
  Control: keep real/sim entry signatures and compare existing smoke tests before/after.

- Risk: provenance becomes too large.
  Control: store metadata, paths, statuses, parameters, and counts only; do not store full matrices.

- Risk: tests depend on user defaults.
  Control: smoke tests should explicitly set recovery/evaluation/output switches.

- Risk: contract tightening rejects valid legacy data.
  Control: strengthen checks around fields already produced by normalization first; avoid speculative required fields.

## Verification Strategy

Minimum verification:

- `git diff --check`
- MATLAB full test suite: `runtests('tests')`
- Specific checks that real/sim pipelines still run with output disabled.
- Specific checks that manifest is not written when saving is disabled.
- Specific checks that `result.stages` and legacy fields agree.

## Done Definition

- `sourceData` contract is documented and enforced.
- Each run can produce a compact manifest.
- Real/sim pipelines share a common post-source processing function.
- Legacy result fields remain available.
- New `result.stages` and `result.provenance` are populated.
- Full tests pass.
