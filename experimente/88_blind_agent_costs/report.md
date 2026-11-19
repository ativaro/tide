# Stage 19 · Preparing the blind agent-cost comparison

**Actual model sessions: 0.** Success rates, tokens per correct solution and time to a successful repair remain unmeasured. The two-repetition design would require 60 sessions for each selected model. All preparation ran locally. The 15 final task descriptions and cases remained sealed. [Protocol](protocol.md) · [Machine-readable preparation record](preparation.json)

## What was checked

| Check | Local observation |
|---|---|
| Inputs and order | The four public study hashes matched. The schedule contained 15 unique commitments, five per family. Each appeared in both languages and both repetitions. The first language switched for every task. |
| Reference execution | TIDE 0.6.12 and CPython 3.14.10 produced the expected value on all seven published inputs for the open W01 task. This exercised the existing reference programs. |
| Cost accounting | Sixteen scorer examples and two scheduler examples passed. A synthetic 60-slot ledger produced six family/language summaries. In a fixture group with five successes, two calls in each of ten runs contributed 200 tokens in total, or 40 per success. A group with zero successes returned an undefined ratio. |
| Time and variance | Each fixture arm had ten sessions per family. The scorer reproduced the independently calculated sample variance of 100,000/9 ms² for each group. Five synthetic successful repair pairs retained both languages’ times. |
| Incomplete evidence | The scorer rejected missing or duplicated slots, unknown outcomes, incomplete usage, negative counters or time, and cached input larger than total input. A verified early timeout with no calls stayed in the denominator. Any other outcome without calls was rejected. `tide test` on the scorer and scheduler reproduces each rejection. A duplicate task commitment was rejected by the scheduler. |

The scorer and both the schedule and rehearsal generators are written in TIDE. The preparation file identifies the frozen TIDE source revision, the SHA-256 of the native checker built from it (`build/native/checker`) and the local CPython binary. The Git revision of this report pins the scorer and protocol. Selection of the actual model, its configuration and the separately funded trial budget are open.

## Reproduce without a model

From the repository root, generate the schedule from the public manifest. The SHA-256 of the compact, key-sorted JSON including its final newline is recorded in the preparation file.

```sh
study=experimente/88_blind_agent_costs
base=experimente/72_bestellimport_basis
seal=$base/versiegelung.json
out=$(mktemp -d)
(cd "$base" && sha256sum -c vertrag.sha256)
./tide run "$study/schedule.tide" --call plan --read seal="$seal" | jq -cS . > "$out/schedule.json"
sha256sum "$out/schedule.json"
./tide test "$study/score.tide"
./tide test "$study/schedule.tide"
./tide run "$study/rehearsal.tide" --call synthetic_ledger --read seal="$seal" | jq -er . > "$out/synthetic.json"
./tide run "$study/score.tide" --read seal="$seal" --read ledger="$out/synthetic.json" > "$out/summary.json"
jq '{kind, groups: (.groups | length), matched_repairs: (.jointly_solved_repairs | length)}' "$out/summary.json"
```

The final command returns `synthetic`, six groups and five matched repairs. The open W01 inputs and both reference sources are available in the baseline study. [Public task definitions](../72_bestellimport_basis/public-tasks.md) · [Published input cases](../72_bestellimport_basis/aufgaben.json)
