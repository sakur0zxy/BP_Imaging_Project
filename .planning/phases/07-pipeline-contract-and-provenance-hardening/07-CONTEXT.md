# Phase 7: Pipeline Contract And Provenance Hardening - Context

**Gathered:** 2026-04-23
**Status:** Ready for planning
**Source:** In-thread architecture discussion + live codebase audit

<domain>
## Phase Boundary

Phase 7 hardens the existing real/sim imaging pipeline without changing the scientific algorithms.

This phase answers:

- What exactly must `sourceData` contain before any downstream stage can use it?
- How can each run record enough provenance to reproduce an image later?
- How can real/sim share the same post-source pipeline while keeping their public entry points unchanged?
- How can new `result.stages` / `result.provenance` fields be added without breaking existing scripts?

In scope:

- Strengthen `validate_source_data`.
- Add pipeline provenance construction.
- Add run manifest output.
- Extract common post-source processing into one shared pipeline.
- Preserve `run_real_data_pipeline` and `run_sim_data_pipeline` as external entry points.
- Preserve legacy result fields while adding `result.stages` and `result.provenance`.
- Update docs and tests.

Out of scope:

- Moving `recovery_evaluation` out of `src/analysis`.
- Large directory migration to `app/`, `domain/`, or `stages/`.
- MATLAB class conversion.
- Rewriting BP, degradation, recovery, or recovery evaluation algorithms.
- Removing legacy result fields in this phase.
</domain>

<decisions>
## Implementation Decisions

### Scope

- **D-01:** Use the recommended option from prior discussion: contract hardening + run manifest + common pipeline extraction.
- **D-02:** Do this in three waves: 7.1 contract/manifest, 7.2 common pipeline, 7.3 stage/provenance dual-track.
- **D-03:** Do not combine this phase with directory migration or analysis/evaluation restructuring.

### Compatibility

- **D-04:** Keep `run_real_data_pipeline(config)` and `run_sim_data_pipeline(config)` callable with the same signatures.
- **D-05:** Keep legacy output fields such as `result.degradation`, `result.recovery`, `result.image`, and `result.analysis`.
- **D-06:** New code should prefer `result.stages` and `result.provenance`, but old fields remain valid during this transition.

### Source Data Contract

- **D-07:** Treat `sourceData` as the project's internal data language, not a loose struct.
- **D-08:** `validate_source_data` must check field existence, dimensions, units-sensitive radar fields, mask shape/type, and required metadata.
- **D-09:** Real and simulation data may have different metadata, but their downstream BP-facing fields must be aligned.

### Provenance And Manifest

- **D-10:** Each run should have a machine-readable and human-readable trace of data source, config, cache, degradation, recovery, imaging, analysis, and runtime.
- **D-11:** Manifest output must be optional and follow existing `config.output.enableSave` behavior.
- **D-12:** Provenance should summarize stage facts; it should not duplicate large image matrices or echo data.

### Common Pipeline

- **D-13:** Only extract the shared chain after source data is available.
- **D-14:** Real/sim entry points remain responsible for validation, source construction, and source-specific context.
- **D-15:** The shared chain owns degradation, optional recovery, imaging, analysis, optional recovery evaluation, output, summary, checkpoint, and manifest.

</decisions>

<canonical_refs>
## Canonical References

Downstream agents should read these before implementation:

### Planning

- `.planning/PROJECT.md` - project goals and constraints.
- `.planning/REQUIREMENTS.md` - requirement IDs and constraints.
- `.planning/ROADMAP.md` - current phase history. Note: Phase 7 is not yet listed because `gsd-sdk` is unavailable in this environment.
- `.planning/STATE.md` - current project state.
- `.planning/phases/06-analysis-and-hardening/06-CONTEXT.md` - recovery evaluation boundary decisions.

### Current Pipeline

- `src/pipelines/run_real_data_pipeline.m` - current real pipeline.
- `src/pipelines/run_sim_data_pipeline.m` - current simulation pipeline.
- `src/contracts/validate_source_data.m` - current sourceData validator.
- `src/contracts/normalize_source_data.m` - current normalization path.

### Current Stages

- `src/data/degradation/apply_degradation.m` - degradation stage.
- `src/recovery/run_recovery.m` - recovery stage entry.
- `src/bp_core/bp_imaging.m` - imaging stage entry.
- `src/analysis/point_target_analysis.m` - analysis stage entry.
- `src/analysis/run_recovery_evaluation.m` - optional recovery evaluation stage.

### Output And Runtime

- `src/output/prepare_run_dir.m` - run directory layout.
- `src/output/save_summary.m` - summary output behavior.
- `src/output/save_checkpoint.m` - checkpoint output behavior.
- `docs/data_format.md` - current data format doc.
- `docs/pipeline_notes.md` - current pipeline doc.
- `docs/architecture_overview.md` - current architecture doc.
</canonical_refs>

<code_context>
## Existing Code Insights

- Real and sim pipelines already share most post-source logic, but duplicate it in separate files.
- `validate_source_data` exists and is the correct place to strengthen sourceData checks.
- `apply_degradation` already returns `degradationInfo`.
- `run_recovery` already returns a structured `recoveryResult`.
- `bp_imaging` already returns `imageResult` with `meta`, `grid`, `peak`, and `imaging`.
- `point_target_analysis` and `run_recovery_evaluation` already produce structured results.
- `prepare_run_dir` already centralizes run directories, so manifest output should plug into `src/output/`.
</code_context>

<deferred>
## Deferred Ideas

- Move recovery evaluation from `src/analysis` to `src/evaluation` only when batch benchmark or parameter sweep grows.
- Add `src/stages/` only if the common pipeline later becomes too large.
- Remove old result fields only after downstream scripts and tests migrate to `result.stages`.
- Add MATLAB class wrappers only if struct contracts become insufficient.
</deferred>

---

*Phase: 07-pipeline-contract-and-provenance-hardening*
*Context gathered: 2026-04-23*
