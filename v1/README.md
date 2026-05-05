# V1 — Improved IMC SRAM with DAC/MAC/ADC Pipeline

Redesigned from scratch to better reflect how In-Memory Computing
works at the circuit level. Uses a signed MAC model with a
DAC → SRAM → bitline accumulation → ADC signal path.

---

## Changes from V0

| Aspect               | V0                             | V1                                    |
|-----------------------|--------------------------------|---------------------------------------|
| **Compute Model**     | XNOR + Popcount                | Signed MAC: `sign(w) × x`            |
| **Parallelism**       | Serial (column-by-column)      | Fully parallel (all columns at once)  |
| **Signal Path**       | No analog modeling             | DAC → Bitline MAC → ADC              |
| **Weight Mapping**    | Binary {0,1}                   | Signed {−1, +1} from {0, 1}          |
| **Array Size**        | 16×16                          | 8×8 (parameterizable)                |
| **Output Handling**   | Combinational                  | Registered (stable at `result_valid`) |
| **Verification**      | Basic printf                   | Golden model comparison               |

## Architecture

```
┌────────────────────────────────────────────────┐
│                 imc_top                        │
│                                                │
│  input_vector ──► [DAC Bank] ──► WL drives     │
│                       (8× imc_dac)             │
│                        │                       │
│           ┌────────────┼────────────┐          │
│  write ──►│    SRAM Bit Cell Array  │          │
│  addr  ──►│      8 rows × 8 cols   │          │
│           │    (64× imc_bitcell)    │          │
│           └────────────┼────────────┘          │
│                        │ Bit Lines             │
│                  [MAC Engine]                  │
│                        │                       │
│                  [ADC Bank]                    │
│                        │                       │
│                   mac_result / read_data       │
│                                                │
│          [Controller FSM]                      │
└────────────────────────────────────────────────┘
```

## Modules

| File                 | Purpose                                           |
|----------------------|---------------------------------------------------|
| `imc_pkg.vh`         | Parameters and derived widths                      |
| `imc_bitcell.v`      | Single SRAM storage element                        |
| `imc_sram_array.v`   | 8×8 array with write, read, and compute ports      |
| `imc_dac.v`          | DAC: digital code → word-line bias level           |
| `imc_mac_engine.v`   | Signed dot product on bit lines (core module)      |
| `imc_adc.v`          | ADC: quantized readout of MAC result               |
| `imc_controller.v`   | FSM: IDLE → WRITE / COMPUTE / READ → DONE         |
| `imc_top.v`          | Top-level integration + output registers           |

## Build & Run

```bash
cd v1/src/
make          # Build + run
make build    # Build only
make run      # Run only
make wave     # Open GTKWave (if installed)
make clean    # Remove build artifacts
```

### Expected Output

```
  IMC-SRAM Simulation Testbench
  Array: 8 rows × 8 cols | DAC: 3-bit | ACC: 8-bit

  TEST 1: Writing weight matrix into SRAM...    ✓
  TEST 2: Reading back and verifying weights... ✓
  TEST 3: MAC — uniform input                   ✓ PASS
  TEST 4: MAC — varied input                    ✓ PASS
  TEST 5: MAC — max input                       ✓ PASS
  TEST 6: MAC — zero input                      ✓ PASS

  Results: 5 / 5 tests PASSED
```

## Design Challenges

See [issues.md](src/issues.md) for a log of problems encountered
during development, with root causes and solutions.
