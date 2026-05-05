# IMC-SRAM: In-Memory Computing SRAM — Digital Behavioral Model

A digital simulation of In-Memory Computing using SRAM, based on the
principles from the Cadence DVCon 2022 paper on IMC modeling.

---

## What is In-Memory Computing?

In conventional systems, data must be moved from memory to a separate
compute unit for processing. IMC avoids this by performing
Multiply-Accumulate (MAC) operations directly inside the memory.

### How it works

```
    BL[0]     BL[1]     ...    BL[C-1]
      |         |                |
 DAC→WL[0] ─[w00]────[w01]──...─[w0,C-1]     ← Input x[0]
      |         |                |
 DAC→WL[1] ─[w10]────[w11]──...─[w1,C-1]     ← Input x[1]
      |         |                |
    ...       ...              ...
      |         |                |
 DAC→WL[R-1]─[wR0]───[wR1]──...─[wR,C-1]     ← Input x[R-1]
      |         |                |
      ▼         ▼                ▼
    [ADC]     [ADC]            [ADC]           ← MAC result per column
```

1. **Weights** (binary) are stored in SRAM cells
2. **Inputs** drive the word lines via DACs
3. Each cell contributes current ∝ `weight × input_level`
4. Currents sum on shared bit lines (accumulation)
5. ADCs convert the result back to digital

**Per-column result:** `y[c] = Σ_r sign(W[r][c]) × x[r]`

---

## Architecture

```
┌────────────────────────────────────────────────┐
│                 imc_top                        │
│                                                │
│  input_vector ──► [DAC Bank] ──► Word Lines    │
│                                   │            │
│                    ┌──────────────┼──────┐     │
│  write_data ──►    │   SRAM Array        │     │
│  row_addr   ──►    │   (8×8 bitcells)    │     │
│                    └──────────────┼──────┘     │
│                                   │ Bit Lines  │
│                            [MAC Engine]        │
│                                   │            │
│                            [ADC Bank]          │
│                                   │            │
│                             mac_result         │
│                             read_data          │
└────────────────────────────────────────────────┘
```

| Module             | Purpose                                    |
|--------------------|--------------------------------------------|
| `imc_bitcell.v`    | Single SRAM storage element                |
| `imc_sram_array.v` | 8×8 array with write, read, compute ports  |
| `imc_dac.v`        | DAC model (digital code → WL bias level)   |
| `imc_mac_engine.v` | Models bit-line current summation           |
| `imc_adc.v`        | ADC model (analog sum → digital output)    |
| `imc_controller.v` | FSM for WRITE / COMPUTE / READ operations  |
| `imc_top.v`        | Top-level integration                      |

---

## Quick Start

```bash
make          # Build and run
make wave     # Open waveform viewer (requires GTKWave)
make clean    # Remove build artifacts
```

## Parameters (imc_pkg.vh)

| Parameter    | Default | Description                         |
|-------------|---------|-------------------------------------|
| `IMC_ROWS`  | 8       | Number of word lines                |
| `IMC_COLS`  | 8       | Number of bit lines                 |
| `DAC_BITS`  | 3       | Input precision (0–7)               |
| `MAC_ACC_W` | 8       | Signed accumulator width            |
| `ADC_BITS`  | 8       | ADC output precision                |
