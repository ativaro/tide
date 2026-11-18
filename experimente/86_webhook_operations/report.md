# Stage 17 · Order webhook operation and recovery

**The 24-hour qualification is open.** The following values cover the recorded interval.

The run began at 2026-11-18T21:11:05Z. The last resource sample was taken at 2026-11-18T21:16:05Z. The recorder observed 300.06 seconds and 6 samples. The largest interval between samples was 60.83 seconds.

| Measurement | Observed value |
|---|---:|
| Scheduled new orders / idempotent replays | 6 / 6 |
| P95 response time for scheduled deliveries and replays | 293.845 ms |
| Webhook RSS at first / latest sample | 12.27 / 8.41 MiB |
| Highest recorded webhook RSS high-water mark | 12.28 MiB |
| Observed webhook CPU across process lifetimes | 0.13 CPU seconds |
| Maximum sampled webhook file descriptors / threads | 5 / 6 |
| Maximum sampled PostgreSQL proportional memory | 27.4 MiB |
| Database size at first / latest sample | 7935679 / 7935679 bytes |

## Recovery

The updater was killed with SIGKILL after the candidate served a real replay and before confirmation. Recovery restarted the confirmed previous binary. A subsequent upgrade confirmed the candidate. At each switch the recorder checked the running executable, its HTTP contract and the original booking.

An immediate PostgreSQL stop made the webhook return HTTP 503 with dependency_unavailable. The failed delivery left no ledger entry. The restarted cluster accepted the same event once and recognized its replay. Stop through verified recovery took 1390 ms.

The final ledger audit is pending.

## Measurement scope

The HTTP listener bound to loopback. An isolated PostgreSQL cluster used a private Unix socket. Each minute the probe created one synthetic order, replayed it, verified its database row, and sampled resources. This cadence measures low-rate operation. Shorter outages can fall between probes. Deployment health checks and the planned database outage are recorded separately from scheduled latency.

Webhook memory and descriptors were sampled from procfs. CPU is the sum of each process’s last observed user and system ticks, including samples just before deployment restarts. PostgreSQL PSS covers the postmaster and sampled children. Database size excludes the cluster-wide WAL. Application CPU and PostgreSQL memory are reported separately. All workload and checks ran locally without model calls.

The independent operator exercise remains open until a second person locates the stored fault and restores a separate drill instance. [Operator runbook](runbook.md)

## Setup and independent checks

The first attempt stopped at its first database restart. PostgreSQL initially received the private socket path as a start argument. A later start used its default path and failed before it could serve requests. The launcher now persists the socket directory, disabled TCP listeners and log prefix in the cluster configuration. Another startup encountered an occupied port before measurement began. The service now asks the kernel to bind an available loopback port and saves that address for subsequent restarts. Neither attempt contributes time to this qualification.

The previous binary was built from Stage 16 commit `8a268bd`. The candidate adds the database-backed `GET /ready` endpoint. Its service backend returns HTTP 503 and a retry hint when the database grant cannot be opened. Both releases use the same database schema. The deployment experiment covers a compatible upgrade. The archive records both exact binary hashes.

A separate automated operator-drill rehearsal recovered the pending request using the stored error and the persisted database configuration. It used a separate cluster and port. It contributes no human operator result.

The workstation ran TIDE 0.6.12 and PostgreSQL 18.6 on Linux 7.3.4-1-cachyos x86-64 with an AMD Ryzen 9 9950X3D. A separate preparation from the pinned revision rebuilt both binaries and passed three TIDE webhook examples. The candidate matched the timed binary byte for byte. The previous binary from the separate checkout had a different SHA-256. The timed rollback used the original archived binary and verified its identity and HTTP behavior at every switch.

The local `make test check-postgres` regression suite passed.

A separate readiness check temporarily renamed the positions table. The endpoint returned HTTP 503 with `schema_unavailable` until the table was restored, then returned HTTP 200.
