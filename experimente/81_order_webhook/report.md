# Stage 12 · Order webhook with PostgreSQL

The TIDE webhook passed the local Stage 12 acceptance test. Eight simultaneous deliveries of the same supplier event produced one booking. The same booking survived a lost HTTP receipt, a forced webhook restart after commit and a PostgreSQL restart with crash recovery. In each case a separate database session read one ledger event and one order line for three units at 125 cents each, worth 375 cents. [Recorded HTTP outcomes and database rows](results.jsonl)

## Faults and observed results

Two runs on this machine, each with a newly built TIDE 0.6.11 service and a fresh PostgreSQL 18.6 cluster, produced byte-identical results. Each run recorded 32 observations, including 13 database snapshots. Each scenario below used a separate supplier with the same event ID, order number and line number. The observer read both tables in one SQL statement and compared every business field with independently specified TIDE expectations. All tests used local tools without additional model calls. [Fault driver](reproduce.sh) · [Requests and expected rows](../../apps/orders/webhook_checks.tide)

| Scenario | Evidence at the fault | Result after delivery or retry |
|---|---|---|
| Concurrent redelivery | Eight HTTP requests reached four workers. The database observer saw at least two ledger inserts blocked on the same table before releasing the lock. | One HTTP 201, seven HTTP 200. One event and one line worth 375 cents. |
| SQL timeout before commit | A lock blocked the position insert after the ledger insert. PostgreSQL reported statement timeout `57014`. The client received HTTP 503. Both tables were empty for this supplier. | The retry returned 201. One event and one line worth 375 cents. |
| Client timeout after commit | A loopback relay captured the service's 201 and withheld the entire response. The observer read the booking while the client was still waiting. The client timed out with zero response bytes. | The retry returned 200 with one duplicate. The line was still worth 375 cents. |
| Webhook killed after commit | The observer read the committed booking while the relay held the 201. The test sent `SIGKILL` to the service, verified exit 137 and read the booking again while the service was down. The client received an empty reply. | A new webhook process accepted the same delivery and returned 200 with one duplicate. One event and one line worth 375 cents. |
| PostgreSQL restarted after commit | After the initial 201, the database was stopped in immediate mode and restarted on the same data directory. Its log confirmed automatic recovery. The observer read the booking before the retry. | The running webhook accepted the retry and returned 200 with one duplicate. One event and one line worth 375 cents. |

A changed price under the same event ID returned 409 at event 0. A two-event document created a new line and then tried to cancel too many units. It returned 409 at event 1 and rolled back the new line and its ledger entry. Malformed JSON returned 422. A subsequent cancellation of two units returned 201, and replaying it returned 200. The database contained one order event, one cancellation event and one line with one unit outstanding worth 125 cents. [Database snapshots, errors and receipts](results.jsonl)

## Webhook contract

`POST /orders` accepts the existing order-import document through `jsoninput@2.0.0`. A sender retries with the original supplier and event ID. Each document runs in one PostgreSQL transaction. A unique constraint on that pair arbitrates concurrent inserts. If another transaction wins, a subsequent statement at `READ COMMITTED` compares the stored business fields with the submitted event. A matching event counts as a duplicate. A mismatch rejects the document. A second unique constraint protects the supplier, order and line combination. Order and cancellation changes use bound parameters. [Handler](../../apps/orders/webhook.tide) · [PostgreSQL transactions](../../apps/orders/pg_store.tide) · [Shared order validation](../../apps/orders/model.tide)

After commit, the service returns JSON counters `applied` and `duplicates`. HTTP 201 means the document applied at least one event. HTTP 200 means it applied zero events. A sender can lose that receipt even though the transaction committed. The scope of the guarantee is the stored order and event ledger for a stable supplier and event ID. The experiment covered one machine and local storage. [Raw observations](results.jsonl)

## Run locally

From the repository root, use a PostgreSQL database where the application role can create its schema. Set `DSN` to that role's libpq connection string. In a second terminal, repeat the example POST to see the duplicate receipt.

```sh
./tide run apps/orders/webhook.tide --call prepare --pg "pg=$DSN"
mkdir -p build
./tide build --service apps/orders/webhook.tide build/order-webhook main
build/order-webhook --listen 127.0.0.1:8080 --workers 4 --pg "pg=$DSN"
```

```sh
curl -i -H 'Content-Type: application/json' --data-binary \
  '{"supplier":"ACME","events":[{"id":"E1","kind":"order","order":"PO7","line":"1","sku":"A","qty":3,"unit_cents":125}]}' \
  http://127.0.0.1:8080/orders
```

To reproduce the experiment on Linux, run the command below as an unprivileged user with the TIDE build tools, PostgreSQL client and server tools, Bubblewrap, curl, socat and jq installed. Each run builds the native service, creates a temporary cluster and runs inside a private network namespace. PostgreSQL uses a Unix socket with `fsync` and `synchronous_commit` enabled. The application and observer use separate roles and connections. The shell controls the processes, locks and network faults. TIDE supplies the application, test documents and business assertions.

```sh
bash experimente/81_order_webhook/reproduce.sh > /tmp/tide-webhook-results.jsonl
```

The repository regression targets `make test check-postgres` also passed in a private network namespace. They include the three webhook fixture examples and the existing native, SQLite, HTTPS and PostgreSQL checks.
