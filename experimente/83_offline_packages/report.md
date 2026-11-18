# Stage 14 · Reproducible offline packages

Two clean Linux build roots produced byte-identical order-import executables and byte-identical measurement-report executables. Both independent projects used the same `jsoninput@2.0.0` source, SHA-256 `6d290454ca80561815b330e81d566194f4d79068e5c6a8f491358d52d20d3b3e`. Each project supplied its own application-specific `Document` type. [Order project manifest](../../apps/orders/tide.packages) · [Measurement project manifest](../../apps/report_packages/tide.packages) · [Recorded results](results.jsonl)

| Application | 2.0.0 ELF SHA-256 in both clean builds and after upgrade | 1.0.0 ELF SHA-256 before upgrade and after rollback | Examples per build |
|---|---|---|---:|
| Order import | `5fbb21ff3554e5e5bda67ac358ce9b578952dcec42266533336c69f0c336c9dc` | `41745e32cbe69d76efda687b0219de68733ee121353f661f2c0cdb54cb13dcb2` | 13 |
| Measurement report | `5de764a61a084e48f88912160138469d9e48a47ea047e7ddf7611c63a0d82c04` | `79f90a01e962a2c70068ad0c9e1dbe98bba2a436b8a3f58d90a77cb36d3a7a57` | 9 |

Each of the ten builds ran its native executable. The importer applied one order, then recognized its redelivery. An independent SQLite query found one ledger row and one position with three units outstanding, worth 375 cents. The report read three measurements, counted two above threshold and returned a peak of 98. [Executable checks](project-run.sh) · [Build hashes and application receipts](results.jsonl)

## Package installation and integrity

TIDE 0.6.12 installs packages from a local directory. The project source selects the exact version. The trusted `tide.lock` binds the tool, operation catalog and SHA-256 of the complete `tide.packages` manifest. Each manifest row binds a vendored source path to its SHA-256. The report project also lists its existing `rowtext` and `measurements` releases. The projects therefore have different manifest hashes and the same JSON library hash. [Independent release directories](../../packages) · [Package lock implementation](../../native/bootstrap/package_lock.tide)

| Check | Observed result |
|---|---|
| Change one release file in the distribution, keeping its name and version | Installation returned `E_PACKAGE_LOCK`. A failure in the last of the report's three files left a fresh consumer without a vendor directory. |
| Change an installed JSON package by one newline | `check`, `run`, `test` and `build --aot` rejected the altered file in both projects. The previous ELF stayed byte-identical. Reinstallation from the good store preserved the conflicting local file and reported the mismatch. |
| Change the manifest to match the altered library, or remove the manifest | Both projects rejected the build because their trusted tool locks still pinned the original manifest. |
| Change a helper imported by a package entry, or omit its digest | The project rejected the helper. This checks coverage of sibling modules beyond `package.tide`. |
| Start two installations into the same empty project | One installed both sources and the other installed zero. The resulting two-file library passed its TIDE example. |
| Write a mixed edit spanning the caller and a locked dependency | The write failed with `E_PACKAGE_LOCK`. The complete project revision still matched its value before the edit. |

The run recorded 20 integrity rejections with `E_PACKAGE_LOCK`. The installer validates the source bytes before publishing missing files under the existing project writer lock. The loader verifies the bytes it passes to the compiler. These checks trust the application revision containing the lock and the installed toolchain. The package hashes establish content identity. Publisher identity and signing are outside this study. [Installer](../../native/bootstrap/project_io_abi.tide) · [File verification and project loading](../../native/bootstrap/seed.tide) · [Fault receipts](results.jsonl)

## Upgrade and rollback

The upgrade used the actual 1.0.0 consumers from commit `cb93e76` and the released 2.0.0 API. Changing only the source pins produced `E_TYPE` at both callers. Migrating the bounded order read to `ReadBudget` and the measurement read to `snapshot` restored both applications. Their upgraded executables matched the two fresh 2.0.0 builds. [Original migration](../76_package_migration/report.md) · [Recorded caller diagnostics](results.jsonl)

For rollback, the driver restored each project's old application sources, manifest and tool lock. The earlier package version remained installed alongside the new one. The driver rebuilt both applications in namespaces with the distribution directory unmounted. Both executables matched their respective pre-upgrade files byte for byte and passed their application checks. [Upgrade and rollback driver](reproduce.sh)

## Reproduce

Run the following from the repository root on Linux x86-64 with the native TIDE build dependencies, Bubblewrap, GNU tools, Bash, jq and the SQLite CLI installed. The local Git history must contain the Stage 6 consumer revision. The output directory receives the results and both verified 2.0.0 executables.

```sh
bash experimente/83_offline_packages/reproduce.sh build/stage14-results
sha256sum build/stage14-results/bin/{order-import,measurement-report}
```

The driver bootstraps and installs TIDE in a network namespace with an empty build directory. Each application build then gets its own empty home and temporary directory, the installed toolchain, the host system compiler and libraries, and its exported project files. It has no checkout, user cache or external network route. For initial installation the distribution is mounted read-only. The fresh roots use different absolute paths and source timestamps from 2000 and 2024. Both invoke AOT with the same project-relative entry name, which also appears in diagnostics. [Qualification script](reproduce.sh) · [Toolchain fingerprints](results.jsonl)

The reproducibility result covers this Linux x86-64 workstation with GCC 16.2.1 and its system libraries. The repository regression targets `make test check-postgres` passed without network access. TIDE 0.6.11 reported `E_VERSION` when asked to check the new order project. All builds and checks used local tools and zero additional model calls.
