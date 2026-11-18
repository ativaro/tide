# Which branches did the faulty example choose?

For the package with exactly 500 grams, the contract expects the price 6. The program calculates 8. From the entry point, ten functions are reachable. The observation run first enters `charge`, then `packet`, and finally `large`. The finding shows the taken `else` branch and the condition `(< grams 500)` in `tariffs.tide`. This allows the incorrect boundary decision in the caller to be recognized. [Tariff example](tarif/checkout.tide) · [Complete finding](messung.json)

Both views can be retrieved from the directory `experimente/42_ausgefuehrte_zweige/tarif` with the installed package. Status 1 is the expected result for this intentionally faulty input.

```sh
tide test checkout.tide --explain
tide test checkout.tide --explain=executed
```

## Size and deployment time

| Example | Tokens statically | Tokens observed | Static, ms | Observed, ms |
|---|---:|---:|---:|---:|
| Package price, three files | 452 | 255 | 5.91 | 5.87 |
| Equality at coordinates | 265 | 327 | 6.13 | 6.31 |
| Rounding to grid points | 264 | 306 | 6.04 | 6.10 |
| Sum of deductions, 32 values | 208 | 226 | 5.66 | 5.84 |
| Sum of deductions, 4,096 values | 8,341 | 166 | 19.85 | 32.59 |
| Balance, all three examples correct | 5 | 5 | 5.98 | 5.99 |

The first measurement counts the entire CLI response including the line ending with `o200k_base` (gpt-tokenizer 3.4.0). Time runs from the start of the installed CLI process until exit. Per cell, after three warm-up rounds, 21 runs were measured in alternating order on core 2 of a Ryzen 9 9950X3D. Static responses before and after the change were byte-identical in all six cases. Individual times, binary and source checksums are recorded. [Raw data](messung.json)

In case of a tie and rounding, all three reachable functions were traversed. Branch annotations cost here 62 and 42 additional tokens. This supports the static standard view for short, fully traversed call chains. The package price shows when the other view becomes worthwhile. For 4,096 values, the largest space gain stems from the reference to the example input. The additional runtime costs a median of 12.74 ms. Anyone reloading the list must add their transfer to their own token consumption.

Both folds have the same body and use, in sequence, −1, 0 and 1. The first list contains 32 entries and expects 11, the second 4,096 and expects 1.366. The faulty body sums negative values with their sign. The example requires their absolute values. [Fold with 32 entries](faltung.tide) · [Original projects for tie and rounding with inputs and expectations](../38_fehlerkontext/versuchsplan.json)

## Verification of findings

A correction of the tariff limit via the public editor passed 14 examples. The repaired deduction balance passed seven, including the empty list, mixed signs, and the largest representable amount. In the long fold, TIDE observed both branches. The full contract could be retrieved again at the same revision via the specified example name. Further cases checked input sizes precisely at and above the output limit, Unicode in an imported example, a rule with 1,200 events, short-circuit evaluation, and a condition whose calculation fails before branch selection. The permanent TIDE test additionally checks the limit on 64 different branch decisions. [TIDE tests](../../native/bootstrap/inspection_checks.tide)

The six TIDE repair proposals from the earlier blind trial were each applied to a fresh project copy using the node identifiers of the new finding. Each version passed its six public and 72 held-out cases. This repetition checks whether the change locations required at the time are available in the finding. Model total tokens and time until successful repair for the new view were not collected in this trial. The measurements from the time for TIDE and Python with prepared context are in [Blind comparison](../38_fehlerkontext/report.md).
