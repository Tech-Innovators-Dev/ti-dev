# 11. Capacity and admission

## Intent

Parallel sessions running tests, builds, dev servers and browsers can take down a small dev host. Capacity control caps parallelism in four layers: admission for agent launches, slots for heavy commands, OS resource limits for agent work, and host protection. Thresholds come from measurement.

## Rules

1. Keep every threshold in one config, with its provenance: slots and wait, heap and test-worker caps, admission thresholds, burst window and limit, session cap.
2. Code defaults equal the shipped config. Generate both from one source.
3. **Admission.** Before each specialist or workflow launch, block when CPU pressure, load per core or free memory crosses its threshold.
4. Also block when admitted launches across sessions exceed a burst limit in a window, because pressure readings lag. Count only admitted launches, under a shared lock.
5. Log every verdict with metrics and reasons. Tell the agent not to retry in a loop: launch fewer or wait a minute.
6. Offer a dry-run check for the launcher. Fail open on an unreadable metric. The admission guard also enforces the fleet spend caps where the platform exposes usage ([12](12-model-policy-and-spend.md)).
7. **Heavy slots.** Block test, build, typecheck and install commands not run through the slot runner, and print the wrapped form.
8. The runner holds one of N shared slots with a portable lock that is reclaimed when its owner dies. It queues with jitter, gives up with a "try later" status, caps heap and test workers, and runs at low priority.
9. **OS limits.** Run all agent work in a resource-limit group with lower CPU weight and memory caps.
10. **Host.** Swap, a low tendency to swap, and agent work weighted below system services, so remote access survives load.
11. **Measure the knee.** Run real CI jobs at rising concurrency and set slots and thresholds where throughput stops rising.
12. Retune from the daily sampler. Raise a threshold only while high-percentile CPU pressure stays low. Edit config, not code.

## Architecture

- **Capacity config.**
- **Admission guard** before launches ([06](06-guards-and-session-events.md)).
- **Heavy-command guard** and **slot runner**.
- **Load sampler**, a scheduled job ([15](15-scheduled-ops-and-governance.md)), and a **calibration ramp**.
- **Agent shell** inside the resource-limit group.

## Interactions

- The launcher refuses when busy or at the session cap ([08](08-peer-sessions-and-handoffs.md)).
- The orchestrator and verifier plan fan-out inside this budget ([05](05-ship-bar-and-stamps.md)).
- The workspace linter checks config keys and that the slot lock works on every supported OS ([14](14-self-verification-and-tests.md)).

## Adapting it

- Map metrics onto your OS load and pressure metrics, resource limits and scheduler. Without pressure metrics, admit on load and memory. Layers 3 and 4 are optional.
- **Per project:** thresholds per host, heavy-command patterns and runtime caps per ecosystem, ramp jobs.
- **At setup,** detect CPUs, memory, OS, metrics and test commands. Ask shared host or laptop, expected sessions, and whether to run the ramp or ship core-scaled defaults. Record which.
- Cover every fan-out path. If nested workflow agents skip the launch check, bound them with slots, the workflow's concurrency cap and OS limits.

## Pitfalls

- Avoid code defaults stricter or looser than the config.
- Avoid capping jobs but not workers. One uncapped test runner saturated every core; the measured result was two slots of two workers each.
- Avoid ignoring nested workflow agents. Consider counting workflow launches against the burst limit.
