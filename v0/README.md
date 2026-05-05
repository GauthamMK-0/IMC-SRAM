# V0 — Initial XNOR-Based IMC SRAM Prototype

First attempt at modeling In-Memory Computing with an 8T SRAM cell.
This version serves as a baseline to compare against the improved
design in `v1/`.

---

## Architecture

```
                  ┌──────────────────────┐
  row_addr ──►    │  Row Decoder         │──► wl_write / wl_read
                  └──────────────────────┘
                  ┌──────────────────────┐
  write_data ──►  │                      │
                  │   16×16 SRAM Array   │──► read_data
                  │   (8T bit cells)     │
                  └──────────┬───────────┘
                             │
  input_vector ──►  ┌────────▼────────┐
                    │  XNOR Compute   │──► popcount
                    └────────┬────────┘
                  ┌──────────▼────────┐
  col_sel ──►     │  Column Decoder   │──► iterate columns
                  └──────────┬────────┘
                  ┌──────────▼────────┐
                  │   Accumulator     │──► accum_out
                  └───────────────────┘
```

## Modules

| File               | Description                                       |
|--------------------|---------------------------------------------------|
| `imc_defs.vh`      | Parameters: 16×16 array, 4-bit address, 5-bit popcount |
| `t8_cell.v`        | Single 8T SRAM bit cell with read/write word lines |
| `sram_array.v`     | 16×16 array of bit cells                          |
| `xnor_compute.v`   | XNOR between stored weights and input + popcount  |
| `accumulator.v`    | Running sum of popcount values with saturation     |
| `row_decoder.v`    | Address → one-hot word line                        |
| `column_decoder.v` | Column counter → one-hot select + max flag         |
| `control_fsm.v`    | 6-state FSM: IDLE → WRITE → READ → COMPUTE → DONE |
| `imc_sram.v`       | Top-level module                                   |

## Build & Run

```bash
cd v0/
verilator --cc --exe --trace --build \
  -Wall -Wno-fatal -Irtl --top-module imc_sram \
  rtl/imc_sram.v rtl/accumulator.v rtl/column_decoder.v \
  rtl/control_fsm.v rtl/row_decoder.v rtl/xnor_compute.v \
  rtl/sram_array.v rtl/t8_cell.v sim/imc_tb.cpp
./obj_dir/Vimc_sram
```

## Limitations

These issues motivated the `v1/` redesign:

1. **Serial column processing** — Columns are iterated one-by-one,
   losing the parallelism that makes IMC useful.
2. **XNOR compute model** — Does not match the analog current-mode
   multiplication described in IMC literature.
3. **No DAC/ADC modeling** — No representation of the analog signal
   path.
4. **Single-row operation** — The FSM processes one row at a time;
   true IMC activates all rows simultaneously during MAC.
