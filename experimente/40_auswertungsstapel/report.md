# Folds in the native evaluator

A control program uses the same inputs and function definitions as the two loops and returns the length of each respective list via two additional entry points. For 4,096 numbers, the length call took 6.44 ms and the sign counting took 37.38 ms. For 4,096 text lines, it took 9.87 ms for the length and 59.10 ms for the first occurrence of the maximum. The four values are medians from 17 runs. The difference includes the evaluation of the respective function body including the generation of the result.

The evaluator now accesses the active frame directly. When removing this frame, it takes over the previous frames from the existing stack. Previously, it first generated a separate list of position markers to copy the same frames. This change applies to the general evaluator. [Evaluation stack](../../native/bootstrap/function_run.tide)

| Task | Values | TIDE before | TIDE now | External CPython |
|---|---:|---:|---:|---:|
| Sign counting | 16 | 5.42 ms | 5.38 ms | 9.07 ms |
| Sign counting | 4,096 | 36.72 ms | 27.64 ms | 9.37 ms |
| First occurrence of the maximum | 16 | 6.15 ms | 6.08 ms | 9.10 ms |
| First occurrence of the maximum | 4,096 | 60.35 ms | 45.68 ms | 9.77 ms |

Each table cell is the median of 21 process starts after three warm-up rounds on the same CPU core. The start order varied, and each output was verified. The public call was measured until process end, including source checking at TIDE and importing the JSON library in CPython. For both large inputs, the new TIDE version was faster in all 21 pairs than the old one. CPython continued to have the shorter runtime for these inputs. The repair time and token consumption of a model were not measured in this run. [Measurement values, sources, and input sequences](messung.json)

The counter-measurement with CPython ran outside the TIDE acceptance test. Separately, `make check-no-python` built the tools in a Debian image without Python, ran the native test suite, and checked the installation as well as a balance repair in the runtime image. [Build and package check](../../native/bootstrap/no-python.Dockerfile)
