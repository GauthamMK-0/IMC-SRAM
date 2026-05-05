# IMC-SRAM — In-Memory Computing with SRAM

A digital simulation of In-Memory Computing (IMC) for AI/ML inference.
This project explores how MAC (Multiply-Accumulate) operations can be
performed directly inside SRAM to reduce data-movement overhead.

---

## Background

In conventional AI/ML hardware, a significant portion of energy is spent
moving data between memory and compute units. IMC addresses this by
performing computation inside the memory itself.

```
  Traditional:    Memory ──(data bus)──► MAC Unit ──► Result

  In-Memory:      Memory+Compute ──► Result
                  (MAC happens inside SRAM)
```

## Project Structure

```
IMC-SRAM/
├── v0/                     ← Initial prototype
│   ├── rtl/                   9 Verilog modules (16×16, XNOR-based)
│   ├── sim/                   Verilator C++ testbench
│   └── README.md
│
├── v1/                     ← Improved design
│   ├── src/
│   │   ├── rtl/               8 Verilog modules (8×8, signed MAC)
│   │   ├── tb/                Verilator C++ testbench with golden model
│   │   ├── issues.md          Design challenges log
│   │   └── Makefile
│   └── README.md
│
└── README.md               ← You are here
```

## Version Comparison

| Feature              | V0                         | V1                                 |
|----------------------|----------------------------|------------------------------------|
| **Compute Style**    | XNOR + Popcount            | Signed MAC: `sign(w) × x`         |
| **Parallelism**      | Serial column scan         | All columns simultaneous           |
| **Signal Path**      | Pure digital logic         | DAC → SRAM → MAC → ADC pipeline   |
| **Weight Encoding**  | Binary {0, 1}              | Signed {−1, +1}                    |
| **Verification**     | Basic check                | Golden model comparison            |

## Quick Start

```bash
# Run v1 (improved design)
cd v1/src/
make

# Run v0 (initial prototype)
cd v0/
verilator --cc --exe --trace --build \
  -Wall -Wno-fatal -Irtl --top-module imc_sram \
  rtl/imc_sram.v rtl/accumulator.v rtl/column_decoder.v \
  rtl/control_fsm.v rtl/row_decoder.v rtl/xnor_compute.v \
  rtl/sram_array.v rtl/t8_cell.v sim/imc_tb.cpp
./obj_dir/Vimc_sram
```

### Requirements

- [Verilator](https://verilator.org/) ≥ 5.0
- GCC/G++ with C++14 support
- (Optional) [GTKWave](http://gtkwave.sourceforge.net/) for waveform viewing

## How IMC Works

```
        BL[0]     BL[1]     ...    BL[C-1]       ← Bit Lines (columns)
          |         |                |
   DAC→WL[0] ──[w00]────[w01]──...──[w0,C-1]     ← Input x[0]
          |         |                |
   DAC→WL[1] ──[w10]────[w11]──...──[w1,C-1]     ← Input x[1]
          |         |                |
        ...       ...              ...
          |         |                |
   DAC→WL[R-1]─[wR0]───[wR1]──...──[wR,C-1]     ← Input x[R-1]
          |         |                |
          ▼         ▼                ▼
        [ADC]     [ADC]            [ADC]          ← MAC result
```

1. **Weights** (1-bit) are stored in SRAM cells
2. **Inputs** (multi-bit) drive the word lines via DACs
3. Each cell contributes current ∝ `weight × input_level`
4. Currents sum on shared bit lines (accumulation)
5. ADCs convert the result back to digital

**Per-column result:** `y[c] = Σ_r sign(W[r][c]) × x[r]`

## Design Challenges

See [v1/src/issues.md](v1/src/issues.md) for a log of design challenges
encountered during development, including root causes and solutions.
