# Telemetry platform - capacity plan

Three releases of the same chart, one per service, all in namespace `helmissions`:

| release | service port | replicas | what it does |
|---------|--------------|----------|--------------|
| `telemetry-ingest` | 80 | 1 | receives metrics |
| `telemetry-rollup` | 80 | 1 | aggregates them |
| `telemetry-alerts` | 80 | 2 | evaluates alert rules (the two pods must not need to share a node in a real cluster) |

Budget per pod: CPU request up to 250m, memory request up to 512Mi. Every pod must keep a CPU and memory request (cluster policy).
Version 2.0 of all three services shipped in last night's release (`bash release.sh`); pages report `version=2.0` when running.

The pipeline says "timed out waiting for the condition". The services are still on 1.0.
