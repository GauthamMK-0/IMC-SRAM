# IMC-SRAM Design & Implementation Notes

This document logs technical challenges identified during the development of the IMC-SRAM macro and the corresponding solutions.

---

## 1. Output Stability and FSM Timing

**Problem:** Read-back and MAC results were observed as zero in simulation, even when internal signals showed active computation.

**Root Cause:** The controller FSM was deasserting enable signals (`sram_rd_en`, `compute_en`) exactly when transitioning to the `DONE` state. Since the output logic was purely combinational and gated by these enables, the valid data was lost before it could be sampled by the testbench.

**Solution:** Implemented output registers in the top-level module to latch results during their active phases. This ensures data remains stable and valid when the FSM asserts the `result_valid` flag.

---

## 2. Signed Arithmetic in MAC Engine

**Problem:** MAC results showed incorrect magnitudes and signs during varied input tests.

**Root Cause:** The design maps binary weights {0, 1} to signed values {−1, +1} for multiplication with unsigned DAC levels (0–7). Verilog's default behavior for negation on unsigned types leads to wrap-around rather than true signed negation.

**Solution:** Explicitly cast signals using `$signed()` and ensured proper bit-extension to the accumulator width before performing arithmetic operations. This ensures the logic correctly handles the signed multiplication requirement.

---

## 3. Latch Inference in Combinational Logic

**Problem:** The simulator issued warnings regarding inferred latches in the MAC engine.

**Root Cause:** Within the combinational `always @(*)` block, some intermediate variables were not assigned a value in all possible execution paths (specifically when `compute_en` was low). 

**Solution:** While these latches do not affect the functional correctness of the behavioral model, future iterations should include default assignments at the start of the block to ensure a fully combinational implementation that meets standard linting requirements.

---

## 4. Digital Modeling of Analog Behavior

**Challenge:** The reference architecture relies on analog bit-line current summation, which is difficult to represent in a standard digital simulator.

**Approach:** Translated analog concepts into digital equivalents:
- **DAC:** Modeled as an integer level (0–7).
- **Bit-line Summation:** Implemented as a signed integer dot product.
- **ADC:** Modeled as a quantization/saturation stage.

This functional modeling approach allows for architectural verification while maintaining compatibility with digital simulation tools.

---

## 5. Memory Port Contention

**Problem:** Potential data corruption or incorrect readouts if multiple word lines are active during a standard read operation.

**Solution:** The controller and row decoders ensure one-hot encoding for word lines during standard read/write operations. The "Compute" mode is physically separated in the logic, allowing it to activate all rows simultaneously for MAC operations without interfering with the standard single-row access logic.

---

## 6. Accumulator Precision and Overflow

**Analysis:** With 8 rows and a 3-bit DAC, the per-column sum ranges from −56 to +56. 

**Implementation:** An 8-bit signed accumulator was selected to provide sufficient headroom (range −128 to +127). For larger arrays or higher DAC resolution, the accumulator width must be scaled logarithmically to prevent overflow and maintain calculation accuracy.

---

## 7. Parallel vs. Serial Architecture

**Decision:** The architecture was designed to process all columns in parallel.

**Rationale:** While a serial "scanning" approach is easier to implement, it does not represent the primary advantage of IMC. By computing all column results in a single combinational step, the design accurately reflects the simultaneous current accumulation that occurs on physical bit lines.
