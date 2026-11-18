# Stage 8 · Atomic project edits

TIDE 0.6.9 committed one revision-bound edit spanning a versioned library, its caller and the function used by its example. Every TIDE project reader in the study saw the complete old or new revision. All 19 checks passed on both Btrfs and tmpfs on the same Linux x86-64 workstation. Both runs produced identical [results](results.jsonl).

## What was changed

The example calls `verify(10)` and expects 17. The old version adds 4 in the package, 2 in the caller and 1 in the test helper. The new version adds 1, 4 and 2 respectively. Each of the six possible partial updates fails the example. The test also compares the complete source trees, including an unrelated file, and the permission bits on all three edited files. [TIDE fixture and edit request](../../native/bootstrap/fixtures/atomic_edit)

The editor validates the combined candidate and its examples, takes a second snapshot of the base under the write lock, and installs the staged files. Until commit, the journal holds enough information to reverse each completed exchange. Removing the journal's undo marker commits the entire set. The next TIDE project command finishes any interrupted recovery or cleanup before returning a snapshot. Directly opening the versioned package uses the same lock as opening its consumer. [TIDE edit workflow](../../native/bootstrap/editor_transaction.tide) · [Linux filesystem operations](../../native/bootstrap/project_io_abi.tide)

## Process death at the commit boundary

GDB stopped the shipped native editor at real syscall boundaries and killed its process. The middle column counts updated files by comparing their raw bytes **before** opening TIDE again. For each row, the first opener was a check of the vendored package. The replay then verified the whole project revision, source bytes, permissions, example and removal of the journal.

| Editor killed | New files on disk before recovery | Revision after reopening |
|---|---:|---|
| While staging | 0 of 3 | Old |
| Immediately before the first exchange | 0 of 3 | Old |
| After the first exchange | 1 of 3 | Old |
| After the second exchange | 2 of 3 | Old |
| After the third exchange, before commit | 3 of 3 | Old |
| Immediately after commit | 3 of 3 | New |
| During cleanup | 3 of 3 | New |

After rollback, retrying the original request succeeded. After commit, retrying with the old base returned `E_REVISION`. An additional test killed the writer after two exchanges, then killed the recovering checker after it restored one file. The next checker restored the remaining file and returned the original revision.

## Other failure and concurrency tests

| Condition | Observed result |
|---|---|
| Reuse a committed base | `E_REVISION`. The committed files stayed intact. |
| An external writer changes a reachable source after staging | The editor returned `E_REVISION` and preserved the external edit byte for byte. |
| Submit a partial edit that fails the example | `E_EXAMPLE`. The tree stayed at the old revision. |
| Deny permission to create the journal | `E_IO`. All three originals remained intact. |
| Set the editor's file size limit to zero | The kernel rejected the staged data write with `EFBIG`. TIDE reported `E_IO` and removed the staging files. |
| Deny the third exchange after two successful exchanges | TIDE reported `E_IO` at the package path and restored both earlier files before returning. Restoring directory permissions allowed a successful retry. |
| Open a reader while the first exchanged file is visible on disk | The checker waited on the directory lock. Its first snapshot had the complete candidate revision. |
| Start two writers from the same base | One committed. The other returned `E_REVISION`. |

## Scope and reproduction

The visibility guarantee covers TIDE project snapshots. An external program that reads individual paths without the lock can see a mixture, as the raw file counts demonstrate. The transaction requires cooperating writers and a local filesystem supporting hard links, directory synchronization, directory locks and `RENAME_EXCHANGE` across the targets. Recovery needs access as the journal owner. This study exercised process death. Power-loss durability and network filesystems remain untested.

Run the replay from the repository root as a non-root user with Bash, GDB, jq and the usual Linux command-line tools. It creates fresh project copies below `TMPDIR`. Set that variable to repeat on a different filesystem. The two recorded fault runs used isolated network namespaces. No model calls were made.

```sh
make -s -j4 editor checker inspector catalog
experimente/77_atomic_edits/reproduce.sh > /tmp/tide-atomic-edits.jsonl
diff -u experimente/77_atomic_edits/results.jsonl /tmp/tide-atomic-edits.jsonl
make -s -j4 test check-postgres
```

The full native and PostgreSQL regression suites passed locally. The installed CLI also passed preview, commit, example execution and stale-base rejection in a network-isolated filesystem without Python or a compiler. [Default regression check](../../native/bootstrap/atomic-edit-check.mk) · [Fault replay](reproduce.sh)
