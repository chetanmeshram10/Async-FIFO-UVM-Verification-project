# Asynchronous FIFO: RTL Design and UVM Verification

A parameterized **asynchronous (dual-clock) FIFO** in SystemVerilog, verified with a **UVM 1.2** environment: constrained-random dual agents, a reference-model scoreboard, **SystemVerilog Assertions** bound to the DUT, functional coverage, and a Python log classifier. The testbench itself is validated by **injecting four RTL bugs** and recording which check catches each one.

**Run it yourself:** [EDA Playground](https://edaplayground.com/x/iRt2) (Cadence Xcelium 25.03, UVM 1.2). Settings are in [How to run](#how-to-run).

## Results at a glance

| | |
|---|---|
| Clean design | 4 of 4 tests pass at default clocks (200, 48, 16 and 10 transfers, all matched) |
| Injected bugs | 4 injected, all detected by at least one check |
| Bugs missed by the scoreboard | 2 of 4 (`BUG_1`, `BUG_2`), both caught by SVA |
| Bug that escaped a test | `BUG_4` escaped `random_test` at default clocks; caught by two other runs |
| Testbench bug found and fixed | Driver dropped the first item of some bursts (found by checking transfer counts) |
| Functional coverage | Measured per run, **not closed** (46.6% to 73.3% per run) |

Every run used the simulator's default seed. No multi-seed regression was run. See [Limitations](#limitations).

## Design overview

Cummings-style architecture:

```
        WRITE DOMAIN (wclk)                          READ DOMAIN (rclk)
   +---------------------------+              +---------------------------+
   |  wptr_full                |   wptr(gray) |  sync_w2r (2-FF)          |
   |  - binary + gray pointer  |------------->|                           |
   |  - full flag              |              +-------------+-------------+
   +-------------+-------------+                            |
                 | waddr                                    v
                 v                              +---------------------------+
          +-------------+          raddr        |  rptr_empty               |
 wdata -->|   fifomem   |<----------------------|  - binary + gray pointer  |--> rempty
          | (dual-port) |--> rdata              |  - empty flag             |
          +-------------+                       +-------------+-------------+
                 ^                                            |
   +-------------+-------------+              +---------------+-----------+
   |  sync_r2w (2-FF)          |<-------------|        rptr(gray)         |
   +---------------------------+              +---------------------------+
```

| Feature | Detail |
|---|---|
| Parameters | `DATA_WIDTH` (default 8), `ADDR_WIDTH` (default 4, so depth = 16) |
| Pointers | `ADDR_WIDTH + 1` bits; the extra MSB tells full from empty |
| Clock domain crossing | Gray-coded pointers through 2-flop synchronizers |
| Full | Next write Gray pointer equals the synced read Gray pointer with the top 2 bits inverted |
| Empty | Next read Gray pointer equals the synced write Gray pointer |
| Flags | Conservative: they may lag, but never report the unsafe state |
| Reset | Asynchronous assert, synchronous release, per domain |

Full specification: [`docs/spec.md`](docs/spec.md)

## Verification environment

```
tb_top (two independent clocks, plusarg-configurable periods)
 └── test (base_test, sanity, random, fill_drain, overflow, underflow, clk_ratio)
      └── env
           ├── wr_agent  (sequencer, driver, monitor)
           ├── rd_agent  (sequencer, driver, monitor)
           ├── scoreboard   (queue reference model)
           └── coverage     (covergroups)
 + fifo_assertions (SVA), attached to the DUT with bind
 + virtual sequence coordinating write and read traffic
 + 2 ms watchdog, so a hung test ends with a UVM_FATAL
```

**Scoreboard checks:** data value and order, underflow (read with an empty model), overflow (write with a full model), leftover entries at the end of the test, and "no traffic observed" so that a dead testbench cannot pass. It prints `*** TEST PASSED ***` or `*** TEST FAILED ***`.

**Driver knobs:** `respect_full` and `respect_empty` let the driver deliberately write to a full FIFO or read from an empty one, which is how the overflow and underflow tests work.

| Test | Purpose |
|---|---|
| `sanity_test` | 20 writes and 20 reads |
| `random_test` | 200 constrained-random transfers per side, independent delays |
| `fill_drain_test` | Three rounds of 16 back-to-back writes, then 16 reads |
| `overflow_test` | Fill to 16, then write 8 more with `respect_full=0`, then drain |
| `underflow_test` | Read an empty FIFO 8 times with `respect_empty=0`, then write 10 and read 10 |
| `clk_ratio_test` | 500 random transfers per side; clock ratio set from the command line |

Clock periods are set with `+WCLK_PS=<ps> +RCLK_PS=<ps>`. Defaults are 10 ns (write) and 27 ns (read).

### Assertions (`sva/fifo_assertions.sv`)

| Assertion | Checks |
|---|---|
| `a_wptr_gray`, `a_rptr_gray` | Each Gray pointer changes by at most one bit per clock |
| `a_no_wr_when_full` | The write pointer is stable on the cycle after a write attempt while full |
| `a_no_rd_when_empty` | The read pointer is stable on the cycle after a read attempt while empty |
| `a_wfull_low_after_reset` | `wfull` is low right after reset is released |
| `a_wr_reset`, `a_rd_reset` | Reset values of flags and pointers |

Four `cover property` statements count full events, empty events, writes while full and reads while empty. They show whether an assertion was exercised at all, which matters for `BUG_4` below.

I left out an assertion that `wfull` and `rempty` are never high together. It is unsound: when a full FIFO is drained, `rempty` rises while `wfull` is still high for a few write-clock cycles, because the read pointer is still crossing the synchronizer.

### Functional coverage (`tb/env/fifo_coverage.sv`)

Coverpoints for fill level (empty, low, mid, almost full, full), level transitions (0↔1, 15↔16), operation, and clock ratio, plus a level × operation cross and a ratio × level cross. Illegal combinations (write at full, read at empty) are excluded from the cross.

Per-run results, default clocks (10 ns / 27 ns):

| Test | `cp_level` | `cp_trans` | `x_level_op` | `cp_ratio` | total |
|---|---|---|---|---|---|
| `random_test` | 100% | 75% | 100% | 20% | 69.2% |
| `fill_drain_test` | 100% | 100% | 100% | 20% | 73.3% |
| `overflow_test` | 100% | 75% | 100% | 20% | 69.2% |
| `underflow_test` | 60% | 25% | 62.5% | 20% | 46.6% |

`cp_ratio` is 20% in every run by construction: one run exercises one of five clock-ratio bins. Closing it needs several runs merged, which this flow does not do.

## Results

### Clean design

| Test | Clocks (W / R) | Transfers matched | Verdict |
|---|---|---|---|
| `random_test` | 10 / 27 ns | 200 / 200 | PASS |
| `fill_drain_test` | 10 / 27 ns | 48 / 48 | PASS |
| `overflow_test` | 10 / 27 ns | 16 / 16 | PASS |
| `underflow_test` | 10 / 27 ns | 10 / 10 | PASS |

Other ratios, scoreboard-only build (before the assertions and coverage were added): the same four tests also passed at 4 ns / 40 ns, and `clk_ratio_test` passed with 500 / 500 at both 40 / 4 ns and 4 / 40 ns. All of these runs predate the final driver fix described below and were not repeated.

### Bug-detection matrix

| Bug | Description | Scoreboard | SVA |
|---|---|---|---|
| `BUG_1` | Binary pointer crosses the clock domain instead of Gray | **Escaped** (`random_test` passes 200/200 at both 10/27 ns and 40/4 ns) | **Caught**: `a_wptr_gray` @ 85 ns, `a_rptr_gray` @ 283.5 ns |
| `BUG_2` | Full compare missing the MSB inversion | No `SB_*` error; only the 2 ms watchdog fires | **Caught**: `a_wfull_low_after_reset` @ 55 ns |
| `BUG_3` | Write accepted while full | **Caught**: `SB_OVERFLOW` @ 525 ns (`overflow_test`) | **Caught**: `a_no_wr_when_full` @ 525 ns |
| `BUG_4` | Read pointer advances while empty | **Caught** by `underflow_test` (`SB_UNDERFLOW` @ 202.5 ns) and by `clk_ratio_test` with a fast reader (@ 194 ns); **escaped `random_test`** at 10 / 27 ns | **Caught** by `underflow_test` (@ 202.5 ns); escaped `random_test` |

Logs for every row are in [`results/logs/`](results/logs/README.md).

### What the matrix shows

1. **`BUG_1` cannot be seen by a scoreboard in RTL simulation.** All bits of a binary pointer change in the same delta cycle, so the data path looks correct. Only the one-bit-change assertion detects it.
2. **`BUG_2` is caught at 55 ns by SVA instead of at 2 ms by the watchdog.** With the MSB inversion missing, `wfull` goes high right after reset and no write is ever accepted, so the scoreboard has nothing to compare.
3. **For `BUG_3` and `BUG_4` the assertion and the scoreboard fire at the same timestamp.** SVA does not detect these earlier. It names the violated rule directly.
4. **An assertion is only as good as the stimulus.** `BUG_4` escaped `random_test` because that test, at the default clocks, never presents a read to an empty FIFO. The cover counter `rd_while_empty=0` in that run is the evidence. Only a directed test or a fast reader exercises it.

### A bug in the testbench

The first clean runs of `fill_drain_test`, `overflow_test` and `underflow_test` came out one transfer short: 46 / 45 instead of 48 / 48, 16 / 15 instead of 16 / 16, and 9 / 9 instead of 10 / 10. The driver counted the first item of a burst as "accepted" when that item arrived between clock edges, so the request never reached the DUT. The scoreboard reported `SB_LEFTOVER` in two of the runs, but `underflow_test` passed with 9 / 9. It was found by comparing the `[SB]` transfer counts with the expected counts, not by the pass/fail line. The fix, in both drivers, is to align to the next clock edge before driving a new item. After the fix the four tests matched 200, 48, 16 and 10.

## How to run

### EDA Playground

Left panel: **Testbench + Design** = SystemVerilog/Verilog, **UVM / OVM** = UVM 1.2, **Tools & Simulators** = Cadence Xcelium 25.03. Riviera-PRO (EDU edition) compiles the UVM code but refuses to run it with a licence error, so use Xcelium.

EDA Playground has no folders, so each file is a tab with the same name. `design.sv` holds all RTL, and `testbench.sv` contains only:

```systemverilog
`include "wr_if.sv"
`include "rd_if.sv"
`include "fifo_assertions.sv"
`include "fifo_bind.sv"
`include "fifo_pkg.sv"
`include "tb_top.sv"
```

The combined files used for the runs are in [`eda_playground/`](eda_playground/).

**Compile Options**

```
-timescale 1ps/1ps +access+r -coverage functional
-timescale 1ps/1ps +access+r -coverage functional +define+BUG_3
```

Use `+define+BUG_1` to `+define+BUG_4` for the bug builds, one at a time.

**Run Options** (keep a space between each plusarg)

```
+UVM_TESTNAME=random_test +UVM_VERBOSITY=UVM_LOW +UVM_MAX_QUIT_COUNT=5,0
+UVM_TESTNAME=clk_ratio_test +WCLK_PS=40000 +RCLK_PS=4000 +UVM_VERBOSITY=UVM_LOW +UVM_MAX_QUIT_COUNT=5,0
```

A valid run prints `Running test <name>...` and an `[ENV]` line. An `INVTST` or `BDTYP` message means the Run Options string is wrong.

### Classifying logs

`scripts/run_regress.py` classifies simulator logs. It does not rely on the simulator exit code, because a `UVM_ERROR` leaves the code at 0 on this setup. A run passes only if the scoreboard printed `*** TEST PASSED ***` and there is no `UVM_ERROR`, no `UVM_FATAL` and no failed assertion.

```bash
python scripts/run_regress.py parse "results/logs/clean/*.log"
python scripts/run_regress.py parse --bug "results/logs/bug/*.log"
```

With `--bug`, verdicts read `DETECTED` or `ESCAPED`, with a `caught_by` column (`scoreboard`, `sva`, `watchdog`). Output goes to the terminal and `results/summary.csv`.

`parse` mode was tested on the logs in this repo. A `run` mode, which launches a local simulator for tests × seeds, is included but **has not been run**, because I had no local simulator.

## Repository structure

```
.
├── docs/            spec.md, images/
├── rtl/             fifomem, sync_r2w, sync_w2r, wptr_full, rptr_empty, async_fifo
├── sim/             directed_tb.sv (self-checking, non-UVM sanity testbench)
├── tb/
│   ├── if/          wr_if, rd_if (clocking blocks)
│   ├── pkg/         fifo_pkg
│   ├── agents/      wr_agent, rd_agent
│   ├── env/         fifo_scoreboard, fifo_coverage, fifo_env
│   ├── seq/         wr_seqs, rd_seqs, fifo_vseq
│   ├── tests/       base_test and the six tests above
│   └── top/         tb_top
├── sva/             fifo_assertions, fifo_bind
├── scripts/         run_regress.py
├── eda_playground/  combined design.sv and testbench.sv
└── results/logs/    simulation logs and a manifest
```

## Limitations

- **One seed.** Every run used the simulator's default seed. No multi-seed regression was executed, so none of the random-test results say anything about other seeds.
- **Coverage is not closed.** Functional coverage is reported per run (46.6% to 73.3%). Runs were not merged, so the clock-ratio bins are not closed. **Code coverage (line, branch, toggle) was not measured.**
- **Four bugs, not more.** A single-flop synchronizer bug was planned and not injected. It cannot be seen in RTL simulation, and I did not run CDC lint.
- **RTL simulation only.** There is no metastability, and no gate-level or timing simulation. Gray-code behaviour is checked by assertion, not by a physical CDC analysis.
- **`BUG_4` is not caught by `random_test`** at the default clocks. Detection depends on directed tests or a clock ratio with a fast reader.
- **The `run` mode of `run_regress.py` is untested.**
- **`results/logs/bug/bug1_random_test.log` is trimmed.** The repeated failure lines were cut, so its assertion count is not the real count.
- **The logs were rebuilt from pasted text**, not exported from the simulator. See `results/logs/README.md`.

## Tools

SystemVerilog, UVM 1.2 (Cadence CDNS-1.2), SVA, Python 3, Cadence Xcelium 25.03 on EDA Playground, Git

## Author

**Chetan Meshram**
GitHub: [@chetanmeshram10](https://github.com/chetanmeshram10)