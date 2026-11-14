# Simulation logs

Cadence Xcelium 25.03, UVM 1.2, EDA Playground. One log per run.

**Provenance.** These files were rebuilt from the log text pasted during the project, not
exported from the simulator. Boilerplate was removed (the UVM release-notes banner, the
tool start lines and the compile lines). Everything from `Running test` down is copied
as pasted. If you need the raw originals, re-run the configuration listed below.

The "SVA" runs and the "scoreboard only" runs are different builds: the SVA runs include
`fifo_assertions` and the functional-coverage component; the scoreboard-only runs do not.

## Settings

| Group | Compile Options | Clocks (write / read) |
|---|---|---|
| `clean/` | `-timescale 1ps/1ps +access+r -coverage functional` | 10 ns / 27 ns (defaults) |
| `bug/` | same, plus `+define+BUG_n` | 10 ns / 27 ns (defaults) |
| `bug_scoreboard_only/` | `-timescale 1ps/1ps +access+r +define+BUG_n` | 40 ns / 4 ns |

Run Options for every run: `+UVM_TESTNAME=<test> +UVM_VERBOSITY=UVM_LOW +UVM_MAX_QUIT_COUNT=5,0`
(plus `+WCLK_PS=40000 +RCLK_PS=4000` for `bug_scoreboard_only/`).

The pasted logs for `clean/` and `bug/` do not include the command line, so those settings are
the ones the runs were meant to use. Check them against your own runs.

## Files

| File | Bug | Test | Outcome |
|---|---|---|---|
| `clean/clean_random_test.log` | none | `random_test` | PASS, 200/200 |
| `clean/clean_fill_drain_test.log` | none | `fill_drain_test` | PASS, 48/48 |
| `clean/clean_overflow_test.log` | none | `overflow_test` | PASS, 16/16 |
| `clean/clean_underflow_test.log` | none | `underflow_test` | PASS, 10/10 |
| `bug/bug1_random_test.log` | `BUG_1` | `random_test` | Scoreboard PASS, SVA `a_wptr_gray` fails from 85 ns. **Trimmed**: see below |
| `bug/bug2_random_test.log` | `BUG_2` | `random_test` | SVA `a_wfull_low_after_reset` @ 55 ns, then `PH_TIMEOUT` |
| `bug/bug3_overflow_test.log` | `BUG_3` | `overflow_test` | SVA `a_no_wr_when_full` and `SB_OVERFLOW` @ 525 ns |
| `bug/bug4_underflow_test.log` | `BUG_4` | `underflow_test` | SVA `a_no_rd_when_empty` and `SB_UNDERFLOW` @ 202.5 ns |
| `bug/bug4_random_test.log` | `BUG_4` | `random_test` | **Escaped**: PASS, no SVA failure, `rd_while_empty=0` |
| `bug_scoreboard_only/bug1_random_test_w40000_r4000.log` | `BUG_1` | `random_test` | Escaped (PASS, 200/200) |
| `bug_scoreboard_only/bug2_random_test_w40000_r4000.log` | `BUG_2` | `random_test` | `PH_TIMEOUT` only, no `SB_*` errors |
| `bug_scoreboard_only/bug4_clk_ratio_test_w40000_r4000.log` | `BUG_4` | `clk_ratio_test` | `SB_UNDERFLOW` @ 194 ns |

**`bug1_random_test.log` is trimmed.** The original has a long run of repeated
`a_wptr_gray` / `a_rptr_gray` failures. This file keeps the first 10 and the last 4, with a
marker line where the rest was cut, so the failure count the parser reports is lower than the
real one. Replace it with the full log from your own run if you quote a count.

## Not included

Runs that were superseded or invalid: the pre-fix clean runs that exposed the driver bug, the
`BUG_3` runs from before the driver fix, the runs with a malformed Run Options string, the
clean runs at 4 ns / 40 ns, and the `clk_ratio_test` clean runs. Their findings are in the
project notes, but the raw logs are not saved here.
