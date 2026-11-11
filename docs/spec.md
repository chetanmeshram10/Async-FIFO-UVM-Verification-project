# Asynchronous FIFO Specification

## Parameters
| Name | Default | Description |
|---|---|---|
| DATA_WIDTH | 8 | Width of data word |
| ADDR_WIDTH | 4 | log2(depth). Depth = 2^ADDR_WIDTH = 16. Must be >= 2 |

## Ports
| Port | Dir | Clock | Description |
|---|---|---|---|
| wclk, wrst_n | in | - | Write clock, async active-low reset |
| winc | in | wclk | Write request. Accepted when winc && !wfull |
| wdata | in | wclk | Write data |
| wfull | out | wclk | FIFO full (conservative) |
| rclk, rrst_n | in | - | Read clock, async active-low reset |
| rinc | in | rclk | Read request. Accepted when rinc && !rempty |
| rdata | out | rclk | Read data. Combinational from memory at read address |
| rempty | out | rclk | FIFO empty (conservative) |

## Architecture
Cummings-style: dual-port memory, (ADDR_WIDTH+1)-bit pointers, Gray-coded
pointers crossed through 2-FF synchronizers. Extra MSB distinguishes full from empty.

## Behavior
- Reset: pointers = 0, wfull = 0, rempty = 1. Assert asynchronously, release synchronously per domain.
- Write when full is ignored. Read when empty is ignored.
- Data is read in the same order it was written (FIFO).
- Flags are pessimistic: wfull may stay high a few wclk cycles after a read,
  rempty may stay high a few rclk cycles after a write. Never optimistic.
- Supported clock ratio: any ratio, tested 1:10 to 10:1.

## Out of scope
Almost-full/empty flags, ECC, first-word-fall-through.