# Operating the local order webhook

## Start a qualification

Use a Linux workstation with a running systemd user manager, PostgreSQL server and client tools, curl, jq, util-linux, procfs and the native TIDE build prerequisites. Run as an ordinary user. Keep the machine awake and the user manager running for the full day. The cluster has a private Unix socket, a dedicated application role and local synthetic data. Each run uses its own directory, units and loopback port.

From a checkout, use a new directory on persistent storage. The preparation command builds the previous release from the pinned Stage 16 revision and the candidate from the working sources. It records the SHA-256 of each executable. Keep the paths short enough for a Unix socket.

```sh
study=$PWD/experimente/86_webhook_operations
mkdir -p build/stage17
run=$PWD/build/stage17/run-$(date +%Y%m%d-%H%M%S)
"$study/prepare.sh" "$run"
unit=tide-stage17-$(basename "$run").service
systemd-run --user --unit="$unit" --property=Type=exec \
  --property="WorkingDirectory=$PWD" \
  --property="StandardOutput=append:$run/campaign.log" \
  --property="StandardError=append:$run/campaign.log" \
  "$study/soak.sh" "$run"
```

`status.json` gives the latest verified minute. `run.json` gives the UTC start and fixed duration. Every minute the recorder expects HTTP 201 for a fresh event and HTTP 200 on replay, checks the stored row, verifies the service PID and executable, and samples resources. The final pulse is due 86,400 seconds after the start. A missing pulse, a sample gap over 90 seconds, unexpected response or ledger mismatch prevents acceptance. The cluster and service stop after the last audit. Data and diagnostic files remain in the run directory.

```sh
cat "$run/status.json"
tail -n 3 "$run/samples.csv"
"$study/report.sh" "$run" "$run/report"
```

Use `"$study/finish.sh" "$run" "$run/final"` to wait for the recorder, verify the qualification and write the English report, JSON summary and compressed raw evidence. The archive contains measurements, deployment and recovery events, and release hashes. The database data directory stays on the workstation.

## Locate a failure

Start with the last event and the corresponding request. Inspect the running process and private cluster using the same run directory. Save the observed timestamp, event ID, status, release and evidence before changing state.

```sh
tail -n 8 "$run/events.jsonl"
tail -n 8 "$run/requests.csv"
readlink "$run/active"
readlink "$run/confirmed"
systemctl --user show "$(cat "$run/web.unit")" -p MainPID -p ActiveState
curl --noproxy '*' -si "$(cat "$run/url")/ready"
pg_isready -d "host=$run/socket dbname=postgres user=observer"
tail -n 12 "$run/postgres.log"
```

The candidate returns HTTP 200 with `{"ready":true}` once both order tables exist. A missing schema yields HTTP 503 with `schema_unavailable`. An unavailable database grant yields HTTP 503 with `dependency_unavailable` and a one-second retry hint. The previous release returns HTTP 404 on this path. A replay of the witness booking checks application readiness on both releases.

## Restore service

If a deployment stopped between activation and confirmation, the two links identify the selected and last verified releases. In a designated recovery drill, run the following command. It verifies both artifact hashes, atomically selects the confirmed binary, restarts the local service and checks the running executable, HTTP behavior and witness replay. To roll back an already confirmed upgrade, use `activate previous` in place of `recover`.

```sh
"$run/deploy" "$run" recover
```

If the database is down, start this run’s own data directory. Its persisted settings restore the private socket and disable TCP listeners. Check readiness, then repeat the original request with its original supplier and event ID.

```sh
pg_ctl -D "$run/db" -l "$run/postgres.log" -w start
url=$(cat "$run/url")
curl --noproxy '*' -fsS "$url/ready"
curl --noproxy '*' -sSi -H 'Content-Type: application/json' \
  --data-binary @"$run/pending-order.json" "$url/orders"
```

The operator drill stores its failed delivery in `pending-order.json`. HTTP 201 acknowledges the first booking and HTTP 200 acknowledges an existing booking. Inspect both tables independently.

```sh
psql "host=$run/socket dbname=postgres user=observer" -X -c \
  "SELECT e.id,p.outstanding,p.cents FROM order_webhook.events e JOIN order_webhook.positions p USING(supplier,ord,line) ORDER BY e.id"
```

## Independent operator exercise

A facilitator prepares a **separate fresh directory** and starts the same command with `operator-drill` after the run path. When its status reads `awaiting_operator`, give the second person the drill directory and this runbook. The timed qualification continues independently. The participant should identify the fault from the stored diagnostics before applying recovery.

Record elapsed time, the diagnostic evidence used, the action and the result in `operator-note.txt`. Publish the completed note using a same-directory rename. The recorder verifies readiness, the recovered booking, its idempotent replay and the original witness, then writes `drill_complete` and stops the drill. The facilitator records whether a distinct person performed it. An automated rehearsal provides technical evidence only.
