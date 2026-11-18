# Stage 13 · Bounded order webhook under load

The native TIDE service now reserves a worker or a place in a FIFO queue before opening the request's PostgreSQL connection. A full queue returns HTTP 503 with `{"error":"queue_full"}` and `Retry-After: 1`. The study used four workers and eight waiting places. Each HTTP 201 corresponded to one committed order. Every over-capacity request received a 503 and left both the order line and event ledger untouched. [Request samples](requests.csv.gz) · [Per-block database-verified counts](blocks.jsonl)

## Throughput and latency

Each cell covers 4,096 attempts across four blocks. A booking is an HTTP 201 with a verified database row. P95 measures the client time to receive a complete response. The separate P95 for booked orders keeps quick overload replies from hiding the latency of successful writes.

| Stage | Parallel clients | Bookings / 4,096 | HTTP 503 | Responses/s | Bookings/s | P95 all (ms) | P95 booked (ms) |
|---|---:|---:|---:|---:|---:|---:|---:|
| 12 | 1 | 4,096 | 0 | 566 | 566 | 2.48 | 2.48 |
| 13 | 1 | 4,096 | 0 | 558 | 558 | 2.45 | 2.45 |
| 12 | 4 | 4,096 | 0 | 1,961 | 1,961 | 3.07 | 3.07 |
| 13 | 4 | 4,096 | 0 | 2,031 | 2,031 | 2.54 | 2.54 |
| 12 | 12 | 4,096 | 0 | 2,245 | 2,245 | 6.36 | 6.36 |
| 13 | 12 | 4,096 | 0 | 2,222 | 2,222 | 6.33 | 6.33 |
| 12 | 32 | 4,096 | 0 | 2,187 | 2,187 | 18.32 | 18.32 |
| 13 | 32 | 331 | 3,765 | 23,176 | 1,873 | 5.36 | 6.71 |

With 12 clients, Stage 13 booked all 4,096 orders and reached the configured maximum of four active and eight waiting. With 32 clients, Stage 12 booked all orders at a P95 of 18.32 ms. Stage 13 rejected 91.9% of attempts, with P95 of 0.62 ms for rejections. Successful bookings had a P95 of 6.71 ms. The four Stage 13 overload bursts each lasted 39–47 ms because the sender immediately moved on after a 503. The 23,176 responses/s includes these refusals. [Full precision results](summary.json) · [Durations and observed queue maxima](blocks.jsonl)

## Cancellation evidence

The test took a PostgreSQL table lock that blocked the order-line insert after the ledger insert. A separate observer identified the waiting backend in `pg_stat_activity`. It kept the lock throughout the disconnect, checked for zero application backends and read both tables before releasing the lock. A successful retry then created exactly one booking. Each fault case used the same real webhook and database as the load test. [Fault observations](faults.jsonl)

| Fault | Observed time to zero application backends | Database result |
|---|---:|---|
| Stage 12, client drops a blocked insert | 4,996 ms | The five-second statement timeout expired. Zero rows before retry, one booking after retry. |
| Stage 13, same client abort, zero queue places | 43 ms | PostgreSQL logged query cancellation. Zero rows before retry, one booking after retry. |
| Stage 13, waiting client drops, then active client drops | 7 ms from the active abort | Both canceled orders left zero rows. A subsequent order succeeded. |
| Stage 13, SIGTERM with an active query and one waiter | 34 ms from signal, including service exit | Both connections to the HTTP clients ended and the database contained zero bookings. |

Times above include observer polling. Each is one observed fault injection in the recorded run. The database lock remained held until the observer finished checking both tables.

The queue test filled one worker and one waiting place. Of two further simultaneous requests, one waited and the other received 503. The observer counted exactly one application connection at saturation. Dropping the waiting client freed its place. Dropping the active client canceled the SQL query. A separate run sent SIGTERM with a blocked query and a full queue. Both cases ended with zero application connections and zero bookings. [Fault driver](reproduce.sh)

## Service limits

Use `--workers 4 --queue 8` when starting the built webhook from Stage 12. The service defaults to four workers and 16 waiting places. Zero waiting places gives immediate admission or rejection. The limit applies to complete requests awaiting a worker. The transport has a separate limit of 128 open connections, including incomplete uploads, and the operating system maintains the TCP listen backlog. A worker reservation counts as active from admission until its handler returns. [Language reference](../../LANGUAGE.md) · [Admission policy](../../native/bootstrap/service_runtime.tide)

The HTTP event loop suspends admitted connections while a fixed pool runs the handlers. Waiting requests hold neither a handler thread nor a database connection. The service checks queued sockets on admission, on worker completion and on a 25 ms timer. Active work observes peer closure through the cancellation checks already used for shutdown, including the PostgreSQL query wait. A client should keep both sides of its socket open until it receives the response. A TCP write-side close after upload signals cancellation. A disconnect can race with commit, so a sender repeats the same event ID when the result is unknown. [Service runtime](../../native/bootstrap/service_abi.tide) · [PostgreSQL integration](../../native/bootstrap/pg_abi.tide) · [Stage 12 post-commit retry evidence](../81_order_webhook/report.md)

An earlier implementation created one transport thread for each connection. Under load, the transport reported thread creation failures and clients received empty replies. The final implementation uses a single HTTP event loop and the configured number of handler threads. The existing process memory limit remains 512 MiB.

## Reproduction and scope

From the repository root, run the following as an unprivileged Linux user. The output directory receives the per-request CSV, per-block results, cancellation observations, environment and summary.

```sh
bash experimente/82_webhook_load/reproduce.sh build/stage13-results
```

The driver builds Stage 12 from local Git commit `ac8fbbc` and Stage 13 from the checkout. It starts a fresh PostgreSQL cluster on a private Unix socket and HTTP on private loopback. It uses the native TIDE build tools, Bubblewrap, PostgreSQL client and server utilities, curl, Bash, jq and gzip. The PostgreSQL observer connects as a different role from the application. The study uses public synthetic orders and local tools throughout. [Reproduction script](reproduce.sh) · [Machine and software versions](environment.json)

Each block starts a new service, sends one warm-up order, clears both tables, then submits 1,024 distinct orders with one event each. Both versions receive the same UTF-8 JSON documents, use the same parameterized SQL and commit durably with `fsync` and `synchronous_commit` enabled. One curl process uses fresh HTTP connections, fixed client concurrency and zero retries. Version and concurrency order reverse on alternate rounds. Every response body is checked. After each block, a TIDE assertion compares the successful request IDs with the IDs in both tables and checks the persisted business fields, including quantity, SKU and price. [TIDE fixtures and assertions](../../apps/orders/webhook_load_checks.tide) · [Per-block results](blocks.jsonl)

Throughput divides the total count by the sum of wall-clock block durations, including curl startup and response collection. P95 is the nearest rank over all individual transfer times in the group, measured by curl. These are one-machine, closed-loop batch results. The overload measurements count each refused attempt once. Production retry traffic, long-running capacity and remote database connection setup were outside this measurement. [Aggregate data](summary.json) · [Individual timings](requests.csv.gz)

The final service passed `make test check-postgres` in a private network namespace. Replaying the Stage 12 durability study produced the same 32 observations byte for byte, including the post-commit lost reply, webhook restart and PostgreSQL crash recovery. The qualification used zero additional model runs. [Stage 12 reference observations](../81_order_webhook/results.jsonl)
