`include "imc_pkg.vh"

// ============================================================================
// IMC DAC — Digital-to-Analog Converter (Behavioral Model)
// ============================================================================
//
// From the paper (Section II-A):
//   "The word lines are driven by Digital to Analog Converters (DACs)
//    to values between and including the supply and ground."
//
// Real chip : Converts digital code → analog voltage on word line
//             V_out = (code / (2^N − 1)) × VDD
//             This partially biases the access transistor, controlling
//             leakage current magnitude.
//
// Digital model : Pass-through of the digital code.
//                 The analog multiplication is modeled in imc_mac_engine.
//
// One DAC per row (one per word line).
// ============================================================================

module imc_dac (
    input  wire [`DAC_BITS-1:0] code_in,     // Digital input code
    input  wire                 enable,       // DAC power enable
    output wire [`DAC_BITS-1:0] level_out     // Output level (0 to 2^DAC_BITS−1)
);

    assign level_out = enable ? code_in : {`DAC_BITS{1'b0}};

endmodule
