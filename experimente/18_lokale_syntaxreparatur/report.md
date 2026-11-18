# A missing bracket in the repair run

In the third journal run with the comparison library, the second model answer changed exactly one character. The new TIDE workbench could derive the same correction from the first answer and the compiler diagnosis. For this observed case, a model call with 20,708 total tokens was omitted. In the subsequent blind comparison on a new double regression, all eight answers solved the error on the first try. There, the local correction was never used. [Historical answers](../17_prioritaeten/messung.json) · [New blind runs](blindmessung.json)

## The observed failure

The first answer replaced two functions in different files. The compiler reported `E_SYNTAX` and `Missing operand` in the modified function `earlier`, immediately after the last token. The TIDE call `closing_retry` compares file, function header, submitted body, line, and column with the candidate copy. It inserts a `)` at this point once and forwards the second edit unchanged. The caller generates a new candidate from the original source version and performs the regular check. The example run was also verified for already correct code and a typo-based answer. [Tool and TIDE examples](../../workbench/function_body.tide) · [Executable run](../../workbench/README.md#repair-grouped-function-bodies)

| Metric | Original journal run | First answer with local correction |
|---|---:|---:|
| Actual total tokens of required model answers | 40,948 | 20,240 |
| Model answers | 2 | 1 |
| Time to first answer in original run | 13.46 s | 13.46 s |
| Total time to public acceptance | 31.09 s measured | 13.70 s reconstructed |
| Public and held-out cases on fresh copy | 40 + 40 passed | 40 + 40 passed |

For reconstruction, the time after the first answer was available was measured twelve times anew. It includes applying the first answer, the failed test run, the local addition, the re-application, and the successful public acceptance. Its median was 0.243 s with a range from 0.238 to 0.252 s. The first model answer and its latency come from the original log. For the local step, no model calls were executed. [Measurement plan](experiment-plan.md) · [Measurement values and input package](replay.json)

In the project directory, the exact correction can be traced back using the archived data.

```sh
set -euo pipefail
data=experimente/18_lokale_syntaxreparatur/replay.json
./tide run workbench/function_body.tide --call closing_retry \
  --inputs "$(jq -c .natural_input "$data")" |
  jq -e --slurpfile saved "$data" '.some == $saved[0].expected_corrected_edits'
```

## Which errors the run covers

All 24 already correct TIDE submissions passed on a new copy with their original text. Subsequently, the last bracket was removed individually from each of their two function bodies. In all 48 cases, the workbench reconstructed the complete correct edit set. Each solution passed all 40 public and 40 held-out cases of its task. Many answers were identical. The 48 variants contained six different erroneous edit sets. [Protocols with content hashes](replay.json)

| Recheck | Result after at most one local attempt |
|---|---|
| A literal operand is missing | The compiler rejects the proposed insertion. |
| Two closing brackets are missing | The compiler reports a syntax error even after the first suggestion. |
| A closing bracket is too many | The workbench provides no suggestion. |
| The function returns an integer instead of a boolean | The type error remains visible. |
| The bracket is missing and the comparison rule is factually incorrect | The inserted expression passes the type check, 33 of 40 public cases fail. |

The mechanism depends on the diagnostic form of the current compiler. Factual verification by the caller is required, even if the local insertion yields a compilable expression.

## New blind comparison

A new double regression was embedded in the existing journal program. Identical events were evaluated as reversals. Additionally, the length of the last interval was output as the longest interval. The errors were in different modules. Both language versions delivered matching results on all 84 inputs before the repair. Publicly, 18/42 cases initially passed. The two isolated reference changes brought the result individually to 22/42 and 37/42. With both changes, all 42 public and 42 held-out tests passed. [Predefined changes, cases, order, and commands](blindplan.json)

Four temporally paired repetitions ran with prepared sources and the first public failure for both languages. The order did not name a file or erroneous function. Both procedures used named function replacements. Each language started twice. The eight ephemeral sessions used `gpt-6-astra` with `xhigh` and requested service class `priority`. All eight answers passed on the first attempt and again on fresh copies including the held-out cases. There were no additional model tool calls. [Prompts, answers, token counters, and times](blindmessung.json)

| Four runs each | TIDE | Python |
|---|---:|---:|
| Time to acceptance, median | 10.54 s | 7.77 s |
| Total tokens, median | 19,929.5 | 19,728.5 |
| Context preparation including initial precheck, median | 0.58 s | 0.04 s |
| Total tokens, sum | 79,693 | 78,900 |
| Total tokens minus cache hits, sum | 6,605 | 7,220 |

The median difference **within pairs** was +2.63 s and +195.5 total tokens for TIDE. TIDE was faster in one of four pairs and never more efficient in total tokens. The workbench addresses the evidenced repetition reason. The greater effort for regular first solves remains a separate measurement question. Preparation before model handover took longer in every pair for TIDE, with differences between 0.54 and 0.70 s.
