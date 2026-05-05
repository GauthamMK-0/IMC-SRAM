`include "imc_pkg.vh"

// ============================================================================
// IMC MAC Engine — Bit-Line Multiply-Accumulate (Core Innovation)
// ============================================================================
//
// THIS MODULE IS THE HEART OF IN-MEMORY COMPUTING.
//
// What happens in real silicon (from the paper, Section II-A):
//   1. Each SRAM cell stores a 1-bit weight w ∈ {0, 1}
//   2. The word line is biased by a DAC to level x ∈ {0, ..., 2^DAC_BITS−1}
//   3. The access transistor leaks current I ∝ x onto the bit line:
//        - If w = 1 (stored): positive current  +I_leak × x
//        - If w = 0 (stored): negative current  −I_leak × x
//   4. ALL cells in a column share one bit line → currents SUM naturally
//
// This performs a parallel MAC across the entire column:
//
//     result[col] = Σ_{row=0}^{ROWS-1} sign(w[row][col]) × x[row]
//
//     where sign(w) maps {0,1} → {−1,+1}
//
// KEY INSIGHT: The MAC happens IN the memory — no data movement needed.
//              All columns compute simultaneously → massive parallelism.
//
// Digital model:
//   We compute the signed dot product combinationally using the
//   weight matrix bits and DAC level codes.
// ============================================================================

module imc_mac_engine (
    input  wire [`WEIGHT_BUS_W-1:0]    weight_matrix,   // Flat weight bits
    input  wire [`INPUT_BUS_W-1:0]     input_levels,    // DAC levels per row
    input  wire                        compute_en,      // Enable computation
    output wire [`MAC_OUT_BUS_W-1:0]   mac_result       // Flat signed results
);

    // Internal signed result per column
    reg signed [`MAC_ACC_W-1:0] col_result [`IMC_COLS-1:0];

    integer r, c;
    reg                    w_bit;
    reg [`DAC_BITS-1:0]    x_level;
    reg signed [`MAC_ACC_W-1:0] product;
    reg signed [`MAC_ACC_W-1:0] acc;

    always @(*) begin
        for (c = 0; c < `IMC_COLS; c = c + 1) begin
            acc = 0;
            if (compute_en) begin
                for (r = 0; r < `IMC_ROWS; r = r + 1) begin
                    // Extract weight bit w[r][c]
                    w_bit   = weight_matrix[r * `IMC_COLS + c];
                    // Extract DAC level x[r]
                    x_level = input_levels[r * `DAC_BITS +: `DAC_BITS];
                    // Signed multiplication: sign(w) × x
                    //   w=1 → +x,  w=0 → −x
                    if (w_bit)
                        product = $signed({{(`MAC_ACC_W - `DAC_BITS){1'b0}}, x_level});
                    else
                        product = -$signed({{(`MAC_ACC_W - `DAC_BITS){1'b0}}, x_level});
                    acc = acc + product;
                end
            end
            col_result[c] = acc;
        end
    end

    // Flatten output: col_result[0] at LSBs, col_result[COLS-1] at MSBs
    genvar gc;
    generate
        for (gc = 0; gc < `IMC_COLS; gc = gc + 1) begin : gen_flat
            assign mac_result[gc * `MAC_ACC_W +: `MAC_ACC_W] = col_result[gc];
        end
    endgenerate

endmodule
