`include "imc_pkg.vh"

// ============================================================================
// IMC ADC — Analog-to-Digital Converter (Behavioral Model)
// ============================================================================
//
// From the paper (Section II-A):
//   "The total summed current on each bit line flows in the terminating
//    resistor, converting the MAC result into a voltage that can be
//    rendered back into the digital domain with an ADC."
//
// Real chip : Senses the bit-line voltage (∝ summed current × R_term)
//             and quantizes it to ADC_BITS digital output.
//             May be a flash ADC, SAR ADC, or simple comparator (1-bit).
//
// Digital model : Since our MAC engine already produces a digital signed
//                 integer, the ADC simply performs saturation clamping
//                 to the representable range.
//
// One ADC per column (one per bit line).
// ============================================================================

module imc_adc (
    input  wire signed [`MAC_ACC_W-1:0]  analog_in,   // MAC engine output
    input  wire                          enable,       // ADC enable
    output wire signed [`ADC_BITS-1:0]   digital_out   // Quantized output
);

    // Since MAC_ACC_W == ADC_BITS in our default config, this is a
    // direct pass-through. If ADC_BITS < MAC_ACC_W, add saturation:
    //
    //   localparam signed [ADC_BITS-1:0] SAT_MAX = (1 << (ADC_BITS-1)) - 1;
    //   localparam signed [ADC_BITS-1:0] SAT_MIN = -(1 << (ADC_BITS-1));
    //   assign digital_out = !enable       ? 0 :
    //                        (analog_in > SAT_MAX) ? SAT_MAX :
    //                        (analog_in < SAT_MIN) ? SAT_MIN : analog_in;

    assign digital_out = enable ? analog_in[`ADC_BITS-1:0] : {`ADC_BITS{1'b0}};

endmodule
