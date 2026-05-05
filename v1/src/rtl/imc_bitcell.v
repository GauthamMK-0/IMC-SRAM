// ============================================================================
// IMC Bit Cell — Single SRAM Storage Element
// ============================================================================
//
// Models a 6T/8T SRAM bit cell for In-Memory Computing.
//
// Real-chip behavior (from the paper, Figure 2):
//   WRITE : WL driven fully ON → BL data latched into cross-coupled inverters
//   READ  : WL driven fully ON → stored value sensed on BL/BLb
//   COMPUTE: WL biased to intermediate voltage (via DAC) →
//            leakage current ∝ (stored_value × DAC_level) flows on BL
//
// Digital model simplification:
//   We store a single bit and expose it for the MAC engine to read.
//   The analog multiplication is handled externally by imc_mac_engine.
// ============================================================================

module imc_bitcell (
    input  wire clk,
    input  wire rst_n,      // Active-low reset
    input  wire wr_en,      // Write enable (word line active for write)
    input  wire bl_in,      // Bit-line input data
    output wire q           // Stored value output
);

    reg stored_bit;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stored_bit <= 1'b0;
        else if (wr_en)
            stored_bit <= bl_in;
    end

    assign q = stored_bit;

endmodule
