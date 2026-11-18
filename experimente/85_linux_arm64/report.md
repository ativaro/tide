# Stage 16 · Linux x86-64 and ARM64

Stage 16 passes for Linux x86-64 and locally emulated Linux ARM64. Both architectures built and installed TIDE from source without Python. The order importer and measurement report produced identical results from the same locked packages.

| Check | Linux x86-64 | Linux ARM64 under QEMU |
|---|---|---|
| Installed CLI | TIDE 0.6.12 | TIDE 0.6.12 |
| Clean installation, bootstrap self-rebuild and full `make test` | Passed | Passed |
| Plain build of the balance program | 97 | 97 |
| Bounded fold and range scan | 8 and `[false,true,true,true,false]` | Same values |
| `make program` for the light rule | x86-64 ELF, `[true,true,false]` | AArch64 ELF, `[true,true,false]` |
| PostgreSQL, TLS POST, repeat delivery, concurrency and cancellation | Passed | Passed |
| Order import in `run` and AOT | 13 examples passed. One booking, one duplicate, 3 units worth 375 cents. | Same outcomes. Direct SQLite inspection found one ledger row. |
| Measurement report in `run` and AOT | 9 examples passed. Two readings exceeded their thresholds and the peak was 98. | Same outcomes. |

The checks compared project revisions, tool lock and manifest digests, the shared `jsoninput@2.0.0` hash, installed file counts and application outputs. Each application's ELF digest differed across architectures. The x86-64 compiler-free runtime also passed `make check-no-python`. [x86-64 receipts](x86_64.jsonl) · [ARM64 receipts](aarch64.jsonl)

The target-machine ELF headers and the application runs establish ARM64 userspace compatibility under emulation. Performance, physical hardware and a separate ARM Linux kernel remain unmeasured.

## Environment

Both builds started with an empty build directory and installation prefix on the same x86-64 workstation. Each had its own Debian 13 root filesystem, GCC 14.2.0 and target-native libraries. The ARM64 root ran AArch64 executables through QEMU user-mode emulation. Its compiler, assembler, linker and TIDE executables all ran in that root. The two guests shared the host Linux kernel. Build and qualification used isolated network namespaces with only loopback. System packages came from a separate provisioning step.

The base image was `debian:trixie-slim` at multi-platform digest `sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2`. The emulator was QEMU 11.1.3. Its binary-format registration was scoped to a user namespace. The qualification checks for Python executables, libraries, headers and the standard library in the target toolchain. No additional model runs were used.

## Build interface

Use `tide build --aot FILE OUTPUT [ENTRY]` on either architecture for the same checked build and named JSON or file arguments. Plain `tide build` on x86-64 retains the compact emitter and its positional arguments for supported folds and scans. On ARM64 plain `tide build` and `make program` use the AOT backend. Building an ARM64 application needs the system C++20 compiler. The resulting static application runs directly. For instance, a scan compiled for ARM64 accepts `--inputs '{"events":[-3,-2,-1,2,3]}'`. The compact x86-64 scan accepts the five numbers as separate arguments.

During qualification the ARM64 linker wrote a diagnostic note to standard output. TIDE now directs compiler and linker messages to standard error. This keeps a successful build's standard output available for callers that collect machine-readable results.

## Bootstrap provenance

Make selects the compressed seed for the local architecture and verifies the checksum manifest. The original x86-64 seed supplied the translation used to mint the ARM64 seed. The following commands reproduce its input from commit `fff975e1283d7dcc6afc665c9e42eba3a700bc62`. Run the first block in an x86-64 checkout. [Seed checksums](../../native/bootstrap/seed.sha256)

```sh
work=$(mktemp -d)
for unit in syntax seed sqlite_abi https_abi write_abi pg_abi project_io_abi; do
    git show "fff975e:native/bootstrap/$unit.tide"
    echo
done > "$work/bootstrap.tide"
xz -dc native/bootstrap/seed-linux-x86_64.xz > "$work/seed0"
chmod +x "$work/seed0"
"$work/seed0" < "$work/bootstrap.tide" > "$work/seed-source.cpp"
sha256sum "$work/seed-source.cpp"
```

The generated source has SHA-256 `500fdfdafa3590a0534e432f70f3449088f4cfee544254fd2b311f31670a0ebe`. In the ARM64 environment, with Debian `g++-14 14.2.0-19` and `libc6-dev 2.41-12+deb13u4`, compile it as follows. Two builds produced the exact checked-in compressed bytes.

```sh
g++ -std=c++20 -O1 -fno-ident -Wl,--build-id=none -s -static seed-source.cpp -o tide-seed
xz -c -9 tide-seed > seed-linux-aarch64.xz
sha256sum seed-linux-aarch64.xz
```

In the subsequent clean builds, the current TIDE bootstrap produced the same `build/native/seed.cpp` on both architectures, SHA-256 `e38a1c8ab8877a285a631bacdaa640a2b113eabe8a388753ee1ac22aa75ec4da`. Each target then built consecutive compiler generations and compared their source and executable bytes using `make bootstrap-check`.

## Reproduce the application checks

Use a fresh checkout or source export in each target environment. On Debian 13 the build uses `g++ make xz-utils xxd libcurl4-openssl-dev libpq-dev libmicrohttpd-dev`. The tests also use `openssl curl socat sqlite3 jq postgresql-17`. Provision these first. Then disconnect external networking, keep loopback up and run the following commands as an ordinary user with a writable checkout.

```sh
set -eu
prefix=$(mktemp -d)
make -j4 install-native PREFIX="$prefix"
make -j4 test
make check-postgres
bash experimente/85_linux_arm64/qualify.sh "$prefix" > receipts.jsonl
```

The last command checks the ELF machine and static linkage of the installed tools, bootstrap generations and each application executable. It installs pinned dependencies into fresh application copies and uses the Stage 14 acceptance values in both `run` and AOT. To compare the two receipt files, remove the architecture label and architecture-specific ELF digest from the application rows and compare the remaining JSON objects. [Qualification driver](qualify.sh) · [Reference application checks](../83_offline_packages/project-run.sh)

```sh
for arch in x86_64 aarch64; do
    jq -cS 'select(.project) | del(.architecture,.elf_sha256)' "$arch.jsonl" > "$arch.apps"
done
cmp x86_64.apps aarch64.apps
```
