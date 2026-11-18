"""Local CPython comparison. Product build and qualification do not invoke this file."""
import ctypes
import json
import os
import pathlib
import platform
import statistics
import subprocess
import sys
import tempfile
import time

from cpython_report import split_rows, summarize

ROOT = pathlib.Path(__file__).resolve().parents[2]
SOURCE = "apps/report.tide"
REFERENCE = pathlib.Path(__file__).with_name("cpython_report.py")
REPEATS = 31
WARMUP = 5
WARM_BATCH = 96
LIMIT = 80

# Timing bridge only. Both sides start with the same pre-split rows.
BRIDGE = r"""
extern "C" std::uint64_t measure_summary(const char* data,std::size_t size,I limit,I count){
    auto source=decode(std::string(data,size));
    const auto rows=t_lines(source);
    auto initial=f_aot_start();
    initial.v_work-=7+I(size)/32+I(source.size())/32;
    initial.v_memory-=8+4*I(source.size())+f_string_list_bytes(rows);
    std::uint64_t checksum=0;
    for(I i=0;i<count;++i){
        auto gas=initial;
        auto result=compiled_1(gas,rows,limit);
        checksum+=std::uint64_t(result.field_above)+std::uint64_t(result.field_peak.value_or(0));
    }
    return checksum;
}
"""


def command(args, **kwargs):
    return subprocess.run(args, cwd=ROOT, capture_output=True, **kwargs)


def checked(args, **kwargs):
    result = command(args, **kwargs)
    result.check_returncode()
    return result.stdout


def paired(arms, reps, warmup):
    times = {key: [] for key in arms}
    names = list(arms)
    for iteration in range(warmup + reps):
        for n in range(len(names)):
            name = names[(n + iteration) % len(names)]
            start = time.perf_counter_ns()
            result, verify = arms[name]()
            elapsed = time.perf_counter_ns() - start
            verify(result)
            if iteration >= warmup:
                times[name].append(elapsed)
    return times


def run_arms(commands, expected):
    def check(result):
        assert result.returncode == 0 and not result.stderr and result.stdout == expected, result

    def arm(cmd):
        return lambda: (command(cmd), check)
    return {key: arm(value) for key, value in commands.items()}


def dataset(rows):
    if rows == 3:
        return b"80\r\n81\r\n98\r\n"
    return "".join(f"{(19 * row) % 330 - 120}\n" for row in range(rows)).encode()


def outcome(result):
    return result.returncode, result.stdout, result.stderr


def main():
    available = os.sched_getaffinity(0)
    core = 2 if 2 in available else min(available)
    os.sched_setaffinity(0, {core})
    checked(["make", "-s", "aot-runtime", "checker"])
    with tempfile.TemporaryDirectory(prefix="tide-comparison-") as tmp:
        work = pathlib.Path(tmp)
        stage = work / "stage"
        checked(["make", "-s", "install", f"DESTDIR={stage}"])
        tide = stage / "usr/local/bin/tide"
        aot = work / "report"
        start = time.perf_counter_ns()
        checked([tide, "build", "--aot", SOURCE, aot])
        build_ns = time.perf_counter_ns() - start
        cpp = work / "warm.cpp"
        runtime = (ROOT / "build/native/aot-runtime.cpp").read_bytes()
        generated = checked([ROOT / "build/native/checker", "--read-project",
                             ROOT / SOURCE, "A" + SOURCE, "main", ""])
        cpp.write_bytes(runtime + generated + BRIDGE.encode())
        dll = work / "warm.so"
        checked([os.environ.get("CXX", "c++"), "-O2", "-std=c++20", "-shared", "-fPIC", cpp, "-o", dll])
        library = ctypes.CDLL(str(dll))
        native = library.measure_summary
        native.argtypes = [ctypes.c_char_p, ctypes.c_size_t, ctypes.c_int64, ctypes.c_int64]
        native.restype = ctypes.c_uint64

        checked_cases = {}
        data = work / "data"
        error_cases = {
            "empty": b"", "negative_and_i64": b"-9223372036854775808\n-3\n9223372036854775807",
            "invalid_integer": b"80\nx\n", "i64_overflow": b"9223372036854775808\n",
            "bad_utf8": b"\xff", "exact_bytes": b"0" * 131069 + b"81\n",
            "too_many_bytes": b"x" * 131073, "too_many_lines": b"\n" * 4097,
            "exact_work": b"0" * 286 + b"81\n" + b"81\n" * 3423 + b"80\n",
            "work_plus_one": b"0" * 286 + b"81\n" + b"0" * 30 + b"81\n" + b"81\n" * 3422 + b"80\n",
            "work_other_branch": b"1\n" * 4096,
        }

        def commands(path):
            args = ["--read", f"input={path}", "--inputs", '{"limit":80}']
            return {
                "tide_aot": [aot, *args],
                "tide_run": [tide, "run", SOURCE, *args],
                "cpython": [sys.executable, "-S", REFERENCE, *args],
            }

        for label, raw in error_cases.items():
            data.write_bytes(raw)
            results = [outcome(command(args)) for args in commands(data).values()]
            assert results.count(results[0]) == len(results), (label, results)
            code, stdout, stderr = results[0]
            checked_cases[label] = {"status": code, "output": json.loads(stdout or stderr)}
        for label, path in [("missing_file", work / "missing"), ("directory", work)]:
            results = [outcome(command(args)) for args in commands(path).values()]
            assert results.count(results[0]) == len(results), (label, results)
            checked_cases[label] = {"status": results[0][0], "output": json.loads(results[0][2])}

        raw_results = {}
        for size in (3, 512, 2048, 3400):
            raw = dataset(size)
            data.write_bytes(raw)
            text = raw.decode()
            rows = split_rows(text)
            values = list(map(int, rows))
            above = sum(n > LIMIT for n in values)
            peak = max(values)
            expected = (json.dumps({"above": above, "peak": {"some": peak}},
                                   separators=(",", ":")) + "\n").encode()
            runs = paired(run_arms(commands(data), expected), REPEATS, WARMUP)
            work_at_fold = 100000 - 12 - len(raw) // 32 - len(text) // 32
            checksum = (above + peak) * WARM_BATCH

            def verify_sum(result):
                assert result == checksum, (result, checksum)

            def python_batch():
                total = 0
                for _ in range(WARM_BATCH):
                    n, p = summarize(rows, LIMIT, work_at_fold)
                    total += n + p
                return total, verify_sum

            warm = paired({
                "tide_aot": lambda: (native(raw, len(raw), LIMIT, WARM_BATCH), verify_sum),
                "cpython": python_batch,
            }, REPEATS, WARMUP)
            raw_results[str(size)] = {"cli_ns": runs, "warm_batch_ns": warm}
            print(f"{size}: CLI { {k: round(statistics.median(v)/1e6, 3) for k,v in runs.items()} }"
                  f"; warm { {k: round(statistics.median(v)/WARM_BATCH/1e3, 3) for k,v in warm.items()} }",
                  file=sys.stderr, flush=True)
        print(json.dumps({
            "platform": platform.platform(), "cpu": core, "python": sys.version,
            "compiler": checked([os.environ.get("CXX", "c++"), "--version"]).decode().splitlines()[0],
            "samples": REPEATS, "warmups": WARMUP, "warm_batch": WARM_BATCH, "build_ns": build_ns,
            "checked_cases": checked_cases, "results": raw_results,
        }, indent=2))


if __name__ == "__main__":
    main()
