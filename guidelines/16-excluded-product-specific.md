# 16. Excluded: product-specific parts

## Intent

Parts of the source system are bound to one product, stack, device or host and stay behind. This file lists them by category and keeps the reusable pattern from each, so a workspace kit can offer the pattern without the product.

## Rules

1. Exclude anything whose value depends on one product's hosts, data, device, stack or compliance regime.
2. Every exclusion still yields a pattern, shipped as procedure guidance or a setup generator.
3. Product state (boards, memory, handoffs, snapshots, history) never travels; only its format does ([08](08-peer-sessions-and-handoffs.md), [10](10-board-and-backlog-engine.md), [13](13-context-cards-and-memory.md)).
4. Keep fleet tools in their own namespace, apart from project tools.

## Architecture

Patterns kept, by excluded category:

- **Browser smoke.** One-shot loopback token hand-off: a script fetches a session token from a secret store and serves it once, on loopback, to an allow-listed host, failing closed; browser automation loads it, so the credential never enters session logs. Test role gates and scope gates separately. A UI stamp without browser evidence is INCONCLUSIVE. Offer a generator for a project-local smoke procedure.
- **Screenshot pipelines.** Capture at a recorded build revision; validate against a spec; mask PINs and real emails; a human publishes, never the model.
- **Hardware bench.** Label evidence with the exact hardware revision and build (bench-confirmed, asserted by handoff, unverified). No physical evidence means INCONCLUSIVE. Released artifacts are immutable with recorded hashes. Product lines never mix. Give the human one step at a time.
- **Legacy orientation.** Use context cards ([13](13-context-cards-and-memory.md)).
- **Brand and UI.** Import UI only through a brand wrapper layer. Prefer the shipped component over a small mockup delta; diverging is an owner call. Stop and ask when a licensed asset is missing.
- **Admin page rules.** A project engineering discipline ([03](03-procedures.md)), without product fields; distinct from implementation discipline (poteto-mode).
- **Cloud sessions and secrets.** On an expired session, print one refresh command and stop. Interactive refreshes run in a real terminal. Back up signing keys encrypted to immutable storage, with the procedure documented. Secret handling otherwise follows [19](19-security-trust-and-incidents.md).
- **Host setup.** Measure capacity rather than copy sizes ([11](11-capacity-and-admission.md)). Offer a charter switch to disable remote-session features when compliance requires it.

## Interactions

- Each pattern maps to a kit module or setup generator ([17](17-adoption-map.md)). Evidence rules tie to the ship bar ([05](05-ship-bar-and-stamps.md)).

## Adapting it

- **Ask at setup:** hardware, a mobile build, a shared screenshot destination, compliance limits on remote features. Each answer enables the matching guidance.

## Pitfalls

- Avoid mixing product and fleet tools with no marker.
- Avoid carrying another project's state when adopting its patterns.
- Avoid letting a model publish to shared human destinations or hold raw credentials in context.
