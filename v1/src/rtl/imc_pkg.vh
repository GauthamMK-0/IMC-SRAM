// ============================================================================
// IMC-SRAM Global Parameters
// ============================================================================
//
// Reference: "SystemVerilog Real Models for an In-Memory Compute Design"
//            Daniel Cross, Cadence Design Systems (DVCon 2022)
//
// This parameter file defines the geometry and precision for a digital
// behavioral model of an In-Memory Computing SRAM macro.
//
// Key idea: An SRAM array stores binary weights. Word lines are driven by
// DACs (representing multi-bit input activations). The leakage current
// through each bit cell is proportional to (stored_weight × DAC_level).
// Currents sum on shared bit lines → natural MAC operation.
// ============================================================================

`ifndef IMC_PKG_VH
`define IMC_PKG_VH

// --- Array Geometry ---
`define IMC_ROWS        8       // Word lines  (weight matrix rows)
`define IMC_COLS        8       // Bit lines   (weight matrix columns)
`define ROW_ADDR_W      3       // ceil(log2(IMC_ROWS))

// --- Precision ---
`define DAC_BITS        3       // Input activation width (8 levels: 0–7)
`define ADC_BITS        8       // ADC output width (signed)

// --- Derived Computation Widths ---
// Per-column MAC sum range:
//   Max = +ROWS × (2^DAC_BITS − 1) = +8 × 7 = +56
//   Min = −ROWS × (2^DAC_BITS − 1) = −56
//   Need 7 magnitude bits + 1 sign bit = 8 bits
`define MAC_ACC_W       8

// --- Bus Widths ---
`define INPUT_BUS_W     (`IMC_ROWS * `DAC_BITS)   // 24 bits
`define MAC_OUT_BUS_W   (`IMC_COLS * `MAC_ACC_W)  // 64 bits
`define WEIGHT_BUS_W    (`IMC_ROWS * `IMC_COLS)   // 64 bits

`endif
