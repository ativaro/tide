# Native function verification and execution

Acceptance test on the unchanged library module `lib/ordering.tide` with its eight examples, on additional modules, and on newly generated programs. The comparison uses the same files, arguments, and expected values. It compares at `check`, `run`, and `test` JSON including error location and exit status, and at `fmt` the output byte-by-byte. Own TIDE test cases capture equivalences, short circuits, erroneous operand types, and the location indication of an error in the import. The previous standard installation reported at the library module E_BACKEND.

Timing after build. Three warm-up pairs per task, followed by 20 measurement pairs in alternating start order. Tasks are verification of the library, execution of the example suite, and a parameterized equivalence call. The Python reference runs outside the Python-free acceptance process. Model time and tokens belong to a separate repair attempt.
