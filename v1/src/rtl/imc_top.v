`include "imc_pkg.vh"

// ============================================================================
// IMC-SRAM Top Module — In-Memory Computing SRAM Macro
// ============================================================================
//
// Architecture (based on the Cadence paper, Figure 1):
//
//   ┌──────────────────────────────────────────────────────┐
//   │                   IMC-SRAM Macro                     │
//   │                                                      │
//   │  input_vector ──► [DAC] ──► Word Lines               │
//   │                              │                       │
//   │                    ┌─────────┼─────────┐             │
//   │  write_data ──►    │  SRAM Bit Cell    │             │
//   │  row_addr   ──►    │    Array          │             │
//   │                    │  (Weights W)      │             │
//   │                    └─────────┼─────────┘             │
//   │                              │ Bit Lines             │
//   │                              ▼ (current sum)         │
//   │                       [MAC Engine]                   │
//   │                              │                       │
//   │                              ▼                       │
//   │                          [ADC]                       │
//   │                              │                       │
//   │                              ▼                       │
//   │                        mac_result                    │
//   │                        read_data                     │
//   └──────────────────────────────────────────────────────┘
//
// Supported operations:
//   OP_WRITE   (01) : Write write_data into SRAM row at row_addr
//   OP_COMPUTE (10) : MAC: result[c] = Σ_r sign(W[r][c]) × input[r]
//   OP_READ    (11) : Read SRAM row at row_addr → read_data
// ============================================================================

module imc_top (
    input  wire                        clk,
    input  wire                        rst_n,

    // Control
    input  wire                        start,       // Pulse to begin
    input  wire [1:0]                  op_mode,     // Operation select
    output wire                        result_valid,
    output wire                        busy,

    // Write / Read address
    input  wire [`ROW_ADDR_W-1:0]      row_addr,

    // Write data
    input  wire [`IMC_COLS-1:0]        write_data,

    // Compute input — one DAC_BITS value per row
    input  wire [`INPUT_BUS_W-1:0]     input_vector,

    // Outputs
    output reg  [`IMC_COLS-1:0]        read_data,      // Normal SRAM read
    output reg  [`MAC_OUT_BUS_W-1:0]   mac_result       // MAC compute result
);

    // --- Internal signals ---
    wire sram_wr_en, sram_rd_en;
    wire dac_en, compute_en, adc_en;

    // Row decoder: one-hot from address
    wire [`IMC_ROWS-1:0] wl_wr_onehot;
    wire [`IMC_ROWS-1:0] wl_rd_onehot;
    assign wl_wr_onehot = sram_wr_en ? ({{(`IMC_ROWS-1){1'b0}}, 1'b1} << row_addr)
                                     : {`IMC_ROWS{1'b0}};
    assign wl_rd_onehot = sram_rd_en ? ({{(`IMC_ROWS-1){1'b0}}, 1'b1} << row_addr)
                                     : {`IMC_ROWS{1'b0}};

    // Weight matrix bus (all cells → MAC engine)
    wire [`WEIGHT_BUS_W-1:0] weight_matrix;

    // DAC output bus
    wire [`INPUT_BUS_W-1:0] dac_levels;

    // MAC engine raw output & ADC output (combinational)
    wire [`MAC_OUT_BUS_W-1:0] mac_raw;
    wire [`MAC_OUT_BUS_W-1:0] adc_out;
    wire [`IMC_COLS-1:0]      sram_rd_data;

    // =========================================================================
    // Controller
    // =========================================================================
    imc_controller u_ctrl (
        .clk          (clk),
        .rst_n        (rst_n),
        .start        (start),
        .op_mode      (op_mode),
        .sram_wr_en   (sram_wr_en),
        .sram_rd_en   (sram_rd_en),
        .dac_en       (dac_en),
        .compute_en   (compute_en),
        .adc_en       (adc_en),
        .result_valid (result_valid),
        .busy         (busy)
    );

    // =========================================================================
    // SRAM Array
    // =========================================================================
    imc_sram_array u_sram (
        .clk         (clk),
        .rst_n       (rst_n),
        .wl_wr       (wl_wr_onehot),
        .bl_wr_data  (write_data),
        .wl_rd       (wl_rd_onehot),
        .rd_data     (sram_rd_data),
        .weight_out  (weight_matrix)
    );

    // =========================================================================
    // DAC Bank — one per row
    // =========================================================================
    genvar gi;
    generate
        for (gi = 0; gi < `IMC_ROWS; gi = gi + 1) begin : gen_dac
            imc_dac u_dac (
                .code_in   (input_vector[gi * `DAC_BITS +: `DAC_BITS]),
                .enable    (dac_en),
                .level_out (dac_levels[gi * `DAC_BITS +: `DAC_BITS])
            );
        end
    endgenerate

    // =========================================================================
    // MAC Engine — models analog bit-line current summation
    // =========================================================================
    imc_mac_engine u_mac (
        .weight_matrix (weight_matrix),
        .input_levels  (dac_levels),
        .compute_en    (compute_en),
        .mac_result    (mac_raw)
    );

    // =========================================================================
    // ADC Bank — one per column
    // =========================================================================
    generate
        for (gi = 0; gi < `IMC_COLS; gi = gi + 1) begin : gen_adc
            imc_adc u_adc (
                .analog_in   (mac_raw[gi * `MAC_ACC_W +: `MAC_ACC_W]),
                .enable      (adc_en),
                .digital_out (adc_out[gi * `ADC_BITS +: `ADC_BITS])
            );
        end
    endgenerate

    // =========================================================================
    // Output Registers — latch results so they're stable at result_valid
    // =========================================================================
    //
    // Design issue solved here: The FSM deasserts enable signals when moving
    // to DONE state, but outputs need to remain valid. We register them.
    //
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_data  <= {`IMC_COLS{1'b0}};
            mac_result <= {`MAC_OUT_BUS_W{1'b0}};
        end else begin
            if (sram_rd_en)
                read_data <= sram_rd_data;
            if (adc_en)
                mac_result <= adc_out;
        end
    end

endmodule
