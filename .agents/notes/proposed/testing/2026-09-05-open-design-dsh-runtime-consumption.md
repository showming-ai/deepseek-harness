# Agent Note: Consume the OpenDesign dsh-runtime profile in Harness tests

Status: proposed

## Problem

OpenDesign (`nexu-io/open-design`) drives a user-installed DeepSeek Harness
through the `dsh --profile open-design {--probe|--models|--stdio}` surface. The
profile adapter (`@open-design/dsh-runtime`) is owned and versioned by
OpenDesign; DeepSeek Harness only hosts it via `cordis.patch.yml`. Harness
releases can change the packages the profile loads (agent, session, llm,
cmdline) without changing the OpenDesign wire contract, and OpenDesign releases
can evolve the wire contract independently. Today Harness has no test that
consumes the built `open-design-dsh-runtime` tarball through the
`open-design` profile, so a drift on either side is silent until a user runs a
design task and sees a profile failure.

## Proposal

Add a small, keyless consumption test owned by DeepSeek Harness:

- In Harness CI (or the release-candidate gate), install the built
  `open-design-dsh-runtime-<v>.tgz` produced by OpenDesign into an ephemeral
  `open-design` profile and replay a recorded session through
  `dsh --profile open-design --stdio` (probe, models, and one minimal
  execute-to-result run).
- Keep the golden replay corpus small and versioned next to the test; reuse the
  repo's existing keyless recorded-session snapshot machinery where possible.
- Do not vendor OpenDesign source or copy the protocol schema into this repo;
  the schema's single source of truth stays at
  `open-design/packages/dsh-runtime/docs/` (`protocol.md` +
  `dsh-stdio-contract.schema.json`). Harness tests consume the built artifact.
- Record an OpenDesign-Harness version compatibility matrix (Harness version x
  dsh-runtime version) alongside the test so a mismatch fails loudly at CI
  time, not on a user machine.

Scope: this note covers the Harness-side consumer. OpenDesign-side contract
ownership and its own golden tests are out of scope here and are tracked by
OpenDesign.

## Alternatives considered

### Golden JSON fixtures copied from the OpenDesign schema

Rejected: a second schema copy in this repo would drift from the owner and
re-create the very gap the contract exists to close. If a fixture is needed for
an offline unit test, generate it from the owned schema in CI instead of
checking in a hand-maintained copy.

### Full end-to-end OpenDesign design run in Harness CI

Rejected: it couples Harness CI to OpenDesign's daemon, project fixtures, and
model availability. The profile boundary is the interface Harness must honor;
testing that boundary with a recorded replay is sufficient and cheaper.

### No Harness-side test (status quo)

Rejected: the OpenDesign wire contract is already consumed by Harness releases,
so the absence of a consumer test makes the integration contract untestable
from the host side.

## Acceptance criteria

- A CI job (or release-candidate gate) installs the OpenDesign-built
  `open-design-dsh-runtime` tarball into an ephemeral `open-design` profile and
  replays a recorded session successfully on the supported platforms.
- The compatibility matrix is checked in and updated when either version moves.
- The test fails loudly when the probe identity, models frame, or a required
  run frame drifts from the recorded replay.

## Risks

- The OpenDesign tarball is an external build input; the job must pin or record
  the exact version it consumed and fail clearly when it is unavailable.
- Windows is best-effort in both repositories; the replay should be marked for
  the platforms where Harness is supported, and Windows-only failures must not
  be conflated with wire drift.
- Pre-release churn: while both sides are pre-stable, replay fixtures will need
  regeneration on intentional contract changes; that cost is the price of
  catching unintentional drift.
