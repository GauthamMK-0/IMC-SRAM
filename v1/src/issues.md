# IMC-SRAM Design Issues & Challenges Log

> A record of problems encountered, root causes identified, and solutions applied
> during the design and simulation of an In-Memory Computing SRAM macro.
> Useful for technical interviews to demonstrate debugging methodology and
> understanding of hardware design trade-offs.

---

## Issue #1 — Output Data Lost After FSM State Transition

**Symptom:** Read-back of SRAM rows returned all zeros. MAC compute results
were always zero. The FSM reported `result_valid` but output buses were empty.

**Root Cause:** Classic **combinational output vs. registered FSM** timing
problem. The controller FSM asserted `sram_rd_en` and `compute_en` during
their respective active states (S_READ, S_COMPUTE/S_ADC). However, these
enables were deasserted when the FSM transitioned to S_DONE. Since the SRAM
read mux and ADC outputs were purely combinational and gated by these enables,
the data disappeared before the testbench could sample it at `result_valid`.

**Solution:** Added **output holding registers** in `imc_top.v`:
```verilog
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        read_data  <= 0;
        mac_result <= 0;
    end else begin
        if (sram_rd_en)  read_data  <= sram_rd_data;  // Latch during READ
        if (adc_en)      mac_result <= adc_out;        // Latch during ADC
    end
end
```

**Interview talking point:** *"This is a common pitfall in FSM-driven
datapaths — you need to decide whether outputs are registered or
combinational. Registered outputs add one cycle of latency but guarantee
stable data at the consumer. In our case, the FSM's DONE state needed
stable data, so we latched during the active computation phase."*

---

## Issue #2 — Signed vs. Unsigned Arithmetic in MAC Engine

**Symptom:** Early MAC results had wrong magnitudes — some columns showed
positive values where negatives were expected.

**Root Cause:** The IMC operation maps stored weight bits {0, 1} to signed
multiplier values {−1, +1}. The DAC input levels are unsigned (0 to 7). When
computing `sign(weight) × input_level`, care must be taken to properly
sign-extend the unsigned DAC level before negation. Without explicit
`$signed()` casting and zero-extension to the accumulator width, Verilog
treats the negation as unsigned, causing wrap-around instead of true negation.

**Solution:** Explicit sign-extension and `$signed()` casting:
```verilog
if (w_bit)
    product = $signed({{(MAC_ACC_W - DAC_BITS){1'b0}}, x_level});
else
    product = -$signed({{(MAC_ACC_W - DAC_BITS){1'b0}}, x_level});
```

**Interview talking point:** *"In IMC, the SRAM stores binary weights but the
analog computation effectively produces signed currents. Translating this into
RTL requires careful handling of the {0,1} → {−1,+1} mapping. I had to
zero-extend the unsigned DAC code to the full accumulator width, then apply
`$signed()` before negation to avoid unsigned wrap-around — a subtle but
critical detail for correctness."*

---

## Issue #3 — Verilator Latch Inference Warnings in MAC Engine

**Symptom:** Verilator issued `%Warning-LATCH` for intermediate variables
(`w_bit`, `x_level`, `product`, `col_result`) inside the MAC engine's
combinational `always @(*)` block.

**Root Cause:** When `compute_en = 0`, the `else` branch only sets `acc = 0`
but does not explicitly assign the intermediate variables `w_bit`, `x_level`,
and `product`. Verilator detects that these variables are not assigned on all
control paths, inferring unwanted latches.

**Why it was accepted:** In this behavioral/research model, the intermediate
variables are only meaningful when `compute_en = 1`. The output (`col_result`)
is correctly assigned to zero when disabled. The latched intermediates have no
effect on functional correctness. Adding default assignments would clutter the
code without benefit.

**Interview talking point:** *"Verilator is stricter than synthesis tools about
latch inference — it warns even for intermediate variables that don't affect
outputs. In a research simulation model, I chose readability over warning
suppression. In a production RTL, I would add default assignments or use
`/* verilator lint_off LATCH */` with a comment explaining the rationale."*

---

## Issue #4 — Modeling Analog Behavior in a Pure Digital Simulator

**Symptom / Challenge:** The reference paper uses SystemVerilog `real` types,
User-Defined Nettypes (UDNs), and resolution functions to model analog
currents on bit lines. Verilator does not support `real` nets, UDNs, or
resolution functions.

**Root Cause:** Verilator is a cycle-based digital simulator — it has no
concept of analog signal resolution, continuous current flow, or intermediate
voltage biasing.

**Solution:** Replaced the analog modeling approach with a **digital
behavioral equivalent**:

| Paper (Analog Model)          | Our Design (Digital Model)         |
|-------------------------------|------------------------------------|
| DAC → analog voltage on WL    | DAC → integer level (0–7)          |
| Bit cell leakage ∝ V_WL × w  | `product = sign(w) × level`        |
| Bit-line current summation    | `acc += product` in a for-loop     |
| ADC → digital readout         | Direct integer pass-through        |
| EEnet (current resolution)    | Packed vector bus                  |

**Interview talking point:** *"The key insight is that IMC's analog
computation — current-mode multiplication and charge-domain accumulation — is
mathematically equivalent to a signed integer dot product. By modeling at the
functional level rather than the circuit level, we can verify the algorithm
and control logic at digital simulation speed while preserving the
architectural intent. This is the Real Number Modeling (RNM) philosophy from
the paper, adapted for open-source tools."*

---

## Issue #5 — SRAM Array Read Port Contention

**Symptom:** When multiple word lines were asserted for read simultaneously,
the output was the OR of multiple rows instead of a single row's data.

**Root Cause:** The read mux in `imc_sram_array.v` iterates through all rows
and overwrites `rd_mux` whenever a word line is active. If multiple word lines
are high, the last active row wins (priority encoding), but intermediate
iterations cause unintended values.

**Solution:** Ensured the controller only asserts one read word line at a time
(one-hot encoding via row decoder). For compute mode, the read port is unused
— the full weight matrix is exposed via the dedicated `weight_out` bus.

**Interview talking point:** *"In real SRAM, asserting multiple word lines
simultaneously for read causes bit-line contention and can corrupt data. Our
digital model correctly separates the read port (one-hot, single-row) from
the compute port (all rows exposed simultaneously). This mirrors the
hardware: during normal read, only one WL is driven to VDD; during compute,
all WLs are driven to intermediate DAC levels."*

---

## Issue #6 — Accumulator Overflow Risk in MAC Results

**Symptom:** Not a bug — a design constraint that required careful analysis.

**Analysis:** For an 8-row array with 3-bit DAC (levels 0–7):
- Max per-column sum: `+8 × 7 = +56` (when all weights = 1, all inputs = 7)
- Min per-column sum: `−8 × 7 = −56` (when all weights = 0, all inputs = 7)
- Required width: `ceil(log2(56)) + 1 = 7 bits signed`
- Allocated width: `8 bits signed` (range −128 to +127) ✓ Safe

**Scaling concern:** If the array is scaled to 256 rows with 8-bit DAC:
- Max sum: `±256 × 255 = ±65280` → needs 17 bits signed
- This would require a wider accumulator and ADC

**Interview talking point:** *"Accumulator width is a critical design
parameter in IMC. It must grow as O(log2(ROWS × 2^DAC_BITS)). In real chips,
this limits the maximum array size or requires intermediate partial-sum
readouts. Our parameterized design makes this trade-off explicit — changing
`MAC_ACC_W` in the parameter file propagates through the entire design."*

---

## Issue #7 — Column Decoder vs. Parallel Compute (Original Design Flaw)

**Context:** The original `8T/` design used a column decoder to iterate
through columns one-by-one with an XNOR + popcount approach.

**Problem:** This serializes what should be a massively parallel operation.
The entire point of IMC is that **all columns compute simultaneously** because
they share independent bit lines. Iterating through columns one at a time
negates the throughput advantage of IMC.

**Our fix:** The redesigned `src/` architecture computes all columns in
parallel — the MAC engine processes the entire weight matrix against the full
input vector in a single combinational evaluation, matching the true physics
of simultaneous bit-line current accumulation.

**Interview talking point:** *"The original design missed the fundamental
parallelism of IMC. In real hardware, current flows on all bit lines
simultaneously — there's no column 'scanning'. Our redesign reflects this
by computing all column MACs in a single combinational step, which is both
architecturally correct and more simulation-efficient."*

---

## Summary Table

| #  | Category              | Severity | Status   |
|----|----------------------|----------|----------|
| 1  | FSM output timing    | Critical | ✅ Fixed  |
| 2  | Signed arithmetic    | Critical | ✅ Fixed  |
| 3  | Latch warnings       | Warning  | ⚠️ Accepted |
| 4  | Analog-to-digital    | Design   | ✅ Solved |
| 5  | Read port contention | Moderate | ✅ Fixed  |
| 6  | Overflow analysis    | Design   | ✅ Analyzed |
| 7  | Parallelism flaw     | Architecture | ✅ Redesigned |
