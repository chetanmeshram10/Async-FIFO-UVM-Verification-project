#!/usr/bin/env python3
"""Regression runner and log classifier for the async FIFO UVM testbench.

  parse : classify existing simulator logs (e.g. copied from EDA Playground)
  run   : launch a local simulator for tests x seeds, then classify the logs

A run counts as PASS only if the scoreboard printed *** TEST PASSED ***
AND there is no UVM_ERROR, no UVM_FATAL and no failed SVA assertion.
The simulator exit code is NOT used: UVM_ERROR alone leaves it at 0.

Add --bug when the logs come from bug-injected builds: the verdict becomes
DETECTED / ESCAPED and a caught_by column shows which check fired.
"""
import argparse
import csv
import re
import subprocess
import sys
from pathlib import Path

RE_TEST = re.compile(r"Running test (\w+)")
RE_PASS = re.compile(r"\*\*\* TEST PASSED \*\*\*")
RE_FAIL = re.compile(r"\*\*\* TEST FAILED \*\*\*")
RE_SB = re.compile(r"\[SB\] writes=(\d+) reads=(\d+) match=(\d+)")
RE_COV = re.compile(r"\[COV\] cp_level=.*?total=([\d.]+)%")
RE_UVM = re.compile(r"^UVM_(ERROR|FATAL)\s+\S+\s+@\s+(\d+):\s+\S+\s+\[(\w+)\]", re.M)
RE_SVA = re.compile(r"\(time (\d+ \w+)\) Assertion \S*?(\w+) has failed")
RE_COMPILE = re.compile(r"^(?:xmvlog|xmelab): \*[EF],", re.M)

FIELDS = ["file", "test", "verdict", "writes", "reads", "match",
          "uvm_errors", "uvm_fatals", "sva_fails", "first_fail",
          "caught_by", "func_cov_total"]


def classify(path, bug_mode):
    text = Path(path).read_text(errors="replace")
    row = dict.fromkeys(FIELDS, "")
    row["file"] = Path(path).name

    m = RE_TEST.search(text)
    row["test"] = m.group(1) if m else "?"
    m = RE_SB.search(text)
    if m:
        row["writes"], row["reads"], row["match"] = m.groups()
    m = RE_COV.search(text)
    if m:
        row["func_cov_total"] = m.group(1)

    uvm = [(m.start(), m.group(1), m.group(2), m.group(3)) for m in RE_UVM.finditer(text)]
    sva = [(m.start(), m.group(2), m.group(1)) for m in RE_SVA.finditer(text)]
    row["uvm_errors"] = sum(1 for u in uvm if u[1] == "ERROR")
    row["uvm_fatals"] = sum(1 for u in uvm if u[1] == "FATAL")
    row["sva_fails"] = len(sva)

    # which kinds of check fired, and which fired first (by position in the log)
    caught = set()
    events = []
    for pos, sev, t, ident in uvm:
        kind = ("watchdog" if ident == "PH_TIMEOUT"
                else "scoreboard" if ident.startswith("SB_") else "other")
        caught.add(kind)
        events.append((pos, f"{ident} @{t}ps"))
    for pos, name, t in sva:
        caught.add("sva")
        events.append((pos, f"{name} @{t}"))
    row["caught_by"] = "+".join(sorted(caught))
    if events:
        row["first_fail"] = min(events)[1]

    passed = bool(RE_PASS.search(text))
    if not RE_TEST.search(text):
        base = "COMPILE_ERROR" if RE_COMPILE.search(text) else "NO_RUN"
    elif events or RE_FAIL.search(text):
        base = "FAIL"
    elif passed:
        base = "PASS"
    else:
        base = "INCOMPLETE"          # no result line and no error: truncated log

    if bug_mode and base in ("PASS", "FAIL"):
        row["verdict"] = "ESCAPED" if base == "PASS" else "DETECTED"
    else:
        row["verdict"] = base
    return row


def print_table(rows):
    widths = {f: max(len(f), *(len(str(r[f])) for r in rows)) for f in FIELDS}
    line = "  ".join(f.ljust(widths[f]) for f in FIELDS)
    print(line)
    print("-" * len(line))
    for r in rows:
        print("  ".join(str(r[f]).ljust(widths[f]) for f in FIELDS))


def summarize(rows, bug_mode, csv_path):
    print_table(rows)
    counts = {}
    for r in rows:
        counts[r["verdict"]] = counts.get(r["verdict"], 0) + 1
    print("\nSummary:", ", ".join(f"{k}={v}" for k, v in sorted(counts.items())))
    if csv_path:
        Path(csv_path).parent.mkdir(parents=True, exist_ok=True)
        with open(csv_path, "w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=FIELDS)
            w.writeheader()
            w.writerows(rows)
        print(f"CSV written to {csv_path}")
    bad = "ESCAPED" if bug_mode else None
    ok = ("PASS", "DETECTED") if bug_mode else ("PASS",)
    failed = [r for r in rows if r["verdict"] not in ok or r["verdict"] == bad]
    for r in failed:
        if not bug_mode:
            print(f"  reproduce: {r['file']}  first_fail={r['first_fail']}")
    return 1 if failed else 0


def cmd_parse(args):
    files = []
    for pat in args.logs:
        if Path(pat).is_file():
            files.append(Path(pat))
        elif not Path(pat).is_absolute():
            files.extend(sorted(Path().glob(pat)))
    if not files:
        sys.exit("no log files found")
    rows = [classify(p, args.bug) for p in files]
    return summarize(rows, args.bug, args.csv)


def cmd_run(args):
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    rows = []
    for test in args.tests:
        for seed in range(1, args.seeds + 1):
            cmd = args.cmd.format(test=test, seed=seed)
            log = out / f"{test}_s{seed}.log"
            print(f"[run] {test} seed={seed}")
            with open(log, "w") as f:
                subprocess.run(cmd, shell=True, stdout=f,
                               stderr=subprocess.STDOUT, timeout=args.timeout)
            rows.append(classify(log, args.bug))
    return summarize(rows, args.bug, args.csv)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="mode", required=True)

    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--bug", action="store_true",
                        help="logs come from bug-injected builds: DETECTED / ESCAPED")
    common.add_argument("--csv", default="results/summary.csv")

    p = sub.add_parser("parse", parents=[common], help="classify existing logs")
    p.add_argument("logs", nargs="+", help="log files or glob patterns")
    p.set_defaults(func=cmd_parse)

    r = sub.add_parser("run", parents=[common], help="run a local simulator")
    r.add_argument("--tests", nargs="+", required=True)
    r.add_argument("--seeds", type=int, default=3)
    r.add_argument("--out", default="results/logs")
    r.add_argument("--timeout", type=int, default=600)
    r.add_argument("--cmd", required=True,
                   help='command template using {test} and {seed}, e.g. '
                        '"xrun -f sim/files.f +UVM_TESTNAME={test} -svseed {seed}"')
    r.set_defaults(func=cmd_run)

    args = ap.parse_args()
    sys.exit(args.func(args))


if __name__ == "__main__":
    main()