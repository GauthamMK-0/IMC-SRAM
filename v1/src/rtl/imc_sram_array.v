`include "imc_pkg.vh"

// ============================================================================
// IMC SRAM Array — Weight Storage Matrix
// ============================================================================
//
// Instantiates an IMC_ROWS × IMC_COLS grid of SRAM bit cells.
// Stores the binary weight matrix W[row][col].
//
// Physical layout (based on the paper, Figure 1):
//
//          BL[0]    BL[1]    ...    BL[C-1]
//            |        |              |
//   WL[0] ─[w00]───[w01]───...───[w0,C-1]
//            |        |              |
//   WL[1] ─[w10]───[w11]───...───[w1,C-1]
//            |        |              |
//          ...      ...            ...
//            |        |              |
//   WL[R-1]─[wR0]──[wR1]──...───[wR,C-1]
//            |        |              |
//          (MAC)    (MAC)          (MAC)
//
// Write operation : Assert wl_wr[row] → write bl_wr_data into that row
// Read  operation : Assert wl_rd[row] → read that row onto rd_data
// Compute         : weight_out exposes entire matrix to MAC engine
// ============================================================================

module imc_sram_array (
    input  wire                        clk,
    input  wire                        rst_n,
    // Write port
    input  wire [`IMC_ROWS-1:0]        wl_wr,          // One-hot write word lines
    input  wire [`IMC_COLS-1:0]        bl_wr_data,     // Write data (one row)
    // Read port
    input  wire [`IMC_ROWS-1:0]        wl_rd,          // One-hot read word lines
    output wire [`IMC_COLS-1:0]        rd_data,        // Read data (one row)
    // Compute port — full matrix exposed for MAC engine
    output wire [`WEIGHT_BUS_W-1:0]    weight_out      // Flat: w[0][0..C-1],...
);

    // Internal: individual cell outputs
    wire cell_q [`IMC_ROWS-1:0][`IMC_COLS-1:0];

    genvar r, c;
    generate
        for (r = 0; r < `IMC_ROWS; r = r + 1) begin : gen_row
            for (c = 0; c < `IMC_COLS; c = c + 1) begin : gen_col
                imc_bitcell u_cell (
                    .clk    (clk),
                    .rst_n  (rst_n),
                    .wr_en  (wl_wr[r]),
                    .bl_in  (bl_wr_data[c]),
                    .q      (cell_q[r][c])
                );
                // Flatten for compute port
                assign weight_out[r * `IMC_COLS + c] = cell_q[r][c];
            end
        end
    endgenerate

    // Read mux — select one row for normal SRAM read
    reg [`IMC_COLS-1:0] rd_mux;
    integer ri, ci;
    always @(*) begin
        rd_mux = {`IMC_COLS{1'b0}};
        for (ri = 0; ri < `IMC_ROWS; ri = ri + 1) begin
            if (wl_rd[ri]) begin
                for (ci = 0; ci < `IMC_COLS; ci = ci + 1)
                    rd_mux[ci] = cell_q[ri][ci];
            end
        end
    end
    assign rd_data = rd_mux;

endmodule
