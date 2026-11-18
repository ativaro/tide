# Order import for purchasing

A purchasing clerk imports orders from multiple suppliers into a local SQLite database on Linux. After an interruption, they must be able to submit the file again, see which lines are still outstanding, and understand any rejection. Prices and totals are integer euro cents.

## Interface and business rules

- The input is a UTF-8 JSON document such as `{"supplier":"ACME","events":[...]}`. An order event contains `id`, `kind:"order"`, `order`, `line`, `sku`, `qty` and `unit_cents`. The order-line key is (supplier, order, line). The event key is (supplier, event ID). Identifiers are nonempty Unicode strings of at most 64 UTF-8 bytes. Compare the original text exactly, including case.
- A document contains at most 1,000 events. Quantities are integers from 1 through 1,000,000. Unit prices range from 0 through 100,000,000 cents. Missing required fields, wrong types, invalid UTF-8 and overflow are errors. Ignore unknown fields. An empty list succeeds with both counters at zero.
- The first valid order event creates the line. Redelivery of an event with the same business fields increments the duplicate count. Reusing its ID with a different payload is a conflict. A second order for the same line under a new event ID is also a conflict.
- Use bound SQL parameters and process events in document order within one transaction. On error, roll back every change from this document. Previously committed documents retain their effect.
- The first extension is `kind:"cancel"`. Each cancellation has its own event ID, order, line and positive quantity. It reduces the outstanding quantity and may bring it to zero. Reject a cancellation for an unknown line or for more than its outstanding quantity. The outstanding value is the outstanding quantity times the original unit price.
- Return `applied` and `duplicates` on success. A line lookup returns its original quantity, outstanding quantity and outstanding value. Report a stable business reason on failure, a zero-based event index for event errors and a JSON Pointer for field errors. The CLI requires explicit input and database grants.

## Acceptance cases

| Action for supplier ACME, unless specified | Expected result |
|---|---|
| E1 creates O7/1, SKU A, 3 units at 125 cents | 1 applied, 0 duplicates, 3 units and 375 cents outstanding |
| Resubmit the document after a process restart | 0 applied, 1 duplicate, 375 cents outstanding |
| E2 cancels 2 units of O7/1 | 1 unit and 125 cents outstanding. Redelivery leaves both values unchanged. |
| Create O7/2 and then cancel another 2 units of O7/1 in the same document | Reject event 1. After reopening the database, O7/2 is absent and O7/1 is still worth 125 cents. |
| Submit E1 with a different unit price | Reject event 0 and keep the original price |
| A second supplier uses the same IDs | Store separate lines and events |
| The first event supplies a string for quantity | Report `/events/0/qty` and persist no line |

## Success criteria

Correctness at the public entry point and in affected modules comes first. Record solve rate, time to independent acceptance, program runtime and peak RSS separately. The initial competitive target is equal or higher correctness and a twofold improvement in total agent tokens or repair time. The three 100× research goals have separate measures. Stages 1–3 test components of purchasing, receiving and shipping on specified input domains. Stage 4 covers the full importer and acceptance after restart. [Project plan](../../tasks/plan.md)

The original wording used to freeze the study is retained as a checksummed input. [Original contract](frozen/contract.de.txt)
