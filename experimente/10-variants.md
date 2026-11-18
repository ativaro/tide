# What does TIDE find when adding a game phase?

On 16 November 2026, I converted the five text values of Space Invaders into the variant type `Phase`. Before the attempt, I chose `respawn` as the sixth phase. A surviving hit shall trigger a brief game pause, provided the match continues.

| Change to the Game | Observation in the respective intermediate state |
|---|---|
| The five old phases receive named cases. `tick` and `draw` handle each case. | `tide check` successful, 9 of 9 TIDE examples successful. The simulations reach win and loss. The terminal test starts, pauses, and ends the game. |
| Exclusively `respawn` appended to the declaration. | A `tide check apps/space_invaders.tide` ends with status 1. Under `E_MATCH` there are two entries with `missing: ["respawn"]`. They point to `draw` in the entry file (line 72, column 1) and `tick` in the module `invaders_game.tide` (then line 139, column 1). |
| `tick` and `draw` handle the new case. The hit logic is still the old one. | `check` successful, all 9 old examples successful. A call of `tick` with an incoming bomb and three ships yields two ships, protection time 16 and still `playing`. |
| The same hit receives in the new example `surviving_hit` the expectation `respawn`. | `tide test` reports `E_EXAMPLE`. In the entire result, exactly the field `mode` differs. |
| `battle` returns `respawn` for a surviving hit in an ongoing match. | All 10 examples pass. The Python test player aborts prematurely at the first re-entry. After adjusting its abort criterion to `won` and `lost`, its runs end again with the expected results. |

For me, the gain in changing lay in that I had the two responsible branches in front of me in a test run. For two further decisions, I needed the game rule. First, a hit must trigger re-entry. Second, an already established game end takes precedence. If the last own shot and an enemy bomb hit simultaneously, with one ship remaining, it counts as a loss; with two ships, it counts as a win. Both are now tested.

The final re-entry freezes the game board for eight ticks. Start, pause, movement, and fire also do not change it during this time. Afterwards, the game continues automatically with eight ticks of hit protection.

## Repeat the reference test from back then

The following commands belong to the reference system [](referenzsystem/README.md). In the current package, `make check-no-python` checks the additional game phase with the installed native tools. [Native result and locations](44_native_varianten/report.md)

```sh
./tide test apps/space_invaders.tide
python3 -m unittest discover -s tests -p test_invaders.py -v
```

`test_one_more_phase` extends the current declaration in memory by one more case and expects exactly the two open slots again. `test_respawn` checks hits, display, countdown, inputs, and the end of protection. The test explicitly proves coverage of explicit branches in this game. Whether a transition is missing from a technical standpoint cannot be derived from the list of permissible phases alone.
