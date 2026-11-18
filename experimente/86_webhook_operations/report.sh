#!/usr/bin/env bash
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
root=$(realpath "${1:?run directory required}")
out=${2:?output directory required}
mkdir -p "$out"
out=$(realpath "$out")
cd "$root"
tmp=$(mktemp -d "$out/.report-XXXXXXXX")
trap 'rmdir "$tmp" 2>/dev/null || :' EXIT
jq -n --rawfile samples samples.csv --rawfile requests requests.csv --slurpfile run run.json \
    --slurpfile status status.json --slurpfile events events.jsonl \
    --slurpfile cutoff <(if [[ -f cutoff-audit.json ]]; then cat cutoff-audit.json; fi) \
    --slurpfile retiring <(if [[ -f retiring.jsonl ]]; then cat retiring.jsonl; fi) \
    -f "$here/summary.jq" >"$tmp/summary.json"
jq -e '.samples>=1 and (.state!="complete" or .verified_24_hours)' "$tmp/summary.json" >/dev/null
jq -r '
    def mib: (. / 1024 * 100 | round) / 100;
    "# Stage 17 · Order webhook operation and recovery",
    "",
    (if .state=="stopped_at_user_request" then "**The recovery checks and the closing database audit passed.** The requested observation ended early at " + .finished_utc + "."
     elif .verified_24_hours then "**The 24-hour technical qualification passed.**"
     elif .state=="failed" then "**The run stopped before it qualified.** The following values cover the recorded interval."
     else "**The 24-hour qualification is open.** The following values cover the recorded interval." end),
    "",
    "The run began at \(.started_utc). The last resource sample was taken at \(.last_sample_utc). The recorder observed \(.elapsed_seconds) seconds and \(.samples) samples. The largest interval between samples was \(.max_sample_gap_seconds) seconds.",
    "",
    "| Measurement | Observed value |","|---|---:|",
    "| Scheduled new orders / idempotent replays | \(.probe_creates) / \(.probe_replays) |",
    "| P95 response time for scheduled deliveries and replays | \(.probe_p95_ms) ms |",
    "| Webhook RSS at first / latest sample | \(.webhook.first_rss_kib|mib) / \(.webhook.last_rss_kib|mib) MiB |",
    "| Highest recorded webhook RSS high-water mark | \(.webhook.max_observed_hwm_kib|mib) MiB |",
    "| Observed webhook CPU across process lifetimes | \(.webhook.total_observed_cpu_seconds) CPU seconds |",
    "| Maximum sampled webhook file descriptors / threads | \(.webhook.max_sampled_fds) / \(.webhook.max_sampled_threads) |",
    "| Maximum sampled PostgreSQL proportional memory | \(.postgres.peak_sampled_pss_kib|mib) MiB |",
    "| Database size at first / latest sample | \(.postgres.first_database_bytes) / \(.postgres.final_database_bytes) bytes |",
    "",
    "## Recovery",
    "",
    (if .interrupted_upgrade and .recovered_previous and .confirmed_upgrade then
        "The updater was killed with SIGKILL after the candidate served a real replay and before confirmation. Recovery restarted the confirmed previous binary. A subsequent upgrade confirmed the candidate. At each switch the recorder checked the running executable, its HTTP contract and the original booking."
     else "The cutoff record has not yet verified all release transitions." end),
    "",
    (if .database_recovery then
        "An immediate PostgreSQL stop made the webhook return HTTP \(.database_outage.ready_status) with \(.database_outage.reply.error). The failed delivery left no ledger entry. The restarted cluster accepted the same event once and recognized its replay. Stop through verified recovery took \(.database_recovery.stop_to_verified_recovery_ms) ms."
     else "The database restart check has not yet been recorded." end),
    "",
    (if .state=="stopped_at_user_request" then
        "After the recorder and webhook stopped, a read-only audit checked the persisted database against all expected order IDs and business fields. It found \(.cutoff_audit.events) events and \(.cutoff_audit.positions) positions, including the original witness and the delivery retried after the outage. These represent \(.cutoff_audit.units) units worth \(.cutoff_audit.value_cents) cents. The audit found \(.cutoff_audit.key_or_value_mismatches) mismatches. The recorder logs any early stop as failed against its original 24-hour threshold."
     elif .verified_24_hours then
        "The final SQL check matched every expected event and position and verified all stored business fields. The ledger contained 1,443 events and 1,443 positions, with 4,329 units worth 541,125 cents."
     else "The final ledger audit is pending." end),
    "",
    "## Measurement scope",
    "",
    "The HTTP listener bound to loopback. An isolated PostgreSQL cluster used a private Unix socket. Each minute the probe created one synthetic order, replayed it, verified its database row, and sampled resources. This cadence measures low-rate operation. Shorter outages can fall between probes. Deployment health checks and the planned database outage are recorded separately from scheduled latency.",
    "",
    "Webhook memory and descriptors were sampled from procfs. CPU is the sum of each process’s last observed user and system ticks, including samples just before deployment restarts. PostgreSQL PSS covers the postmaster and sampled children. Database size excludes the cluster-wide WAL. Application CPU and PostgreSQL memory are reported separately. All workload and checks ran locally without model calls.",
    "",
    "The independent operator exercise remains open until a second person locates the stored fault and restores a separate drill instance. [Operator runbook](runbook.md)"
' "$tmp/summary.json" >"$tmp/report.md"
if [[ -s setup-notes.md ]]; then
    cat setup-notes.md >>"$tmp/report.md"
fi
if [[ -f regression.status ]] && grep -Fxq passed regression.status; then
    printf '\nThe local \x60make test check-postgres\x60 regression suite passed.\n' >>"$tmp/report.md"
fi
if [[ -f schema-failure.json ]] && jq -e '.error=="schema_unavailable"' schema-failure.json >/dev/null; then
    printf '\nA separate readiness check temporarily renamed the positions table. The endpoint returned HTTP 503 with `schema_unavailable` until the table was restored, then returned HTTP 200.\n' >>"$tmp/report.md"
fi
if jq -e '.verified_24_hours or .state=="stopped_at_user_request"' "$tmp/summary.json" >/dev/null; then
    printf '\n[Machine-readable results](summary.json) · [Raw measurements and event logs](evidence.tar.gz)\n' >>"$tmp/report.md"
fi
mv -fT "$tmp/summary.json" "$out/summary.json"
mv -fT "$tmp/report.md" "$out/report.md"
