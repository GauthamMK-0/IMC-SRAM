`include "imc_pkg.vh"

// ============================================================================
// IMC Controller — Operation FSM
// ============================================================================
//
// Manages three modes of operation:
//
//   IDLE    → Waiting for command
//   WRITE   → Write one row of weights into the SRAM array
//   COMPUTE → Activate all DACs, compute MAC, latch ADC results
//   READ    → Normal SRAM read of one row
//   DONE    → Operation complete, result valid
//
// Interface protocol:
//   1. Set mode + inputs → pulse 'start'
//   2. Wait for 'valid' to go high
//   3. Read outputs
// ============================================================================

module imc_controller (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,          // Pulse to begin operation
    input  wire [1:0]  op_mode,        // 2'b01=WRITE, 2'b10=COMPUTE, 2'b11=READ
    output reg         sram_wr_en,     // SRAM write enable
    output reg         sram_rd_en,     // SRAM read word line enable
    output reg         dac_en,         // DAC enable
    output reg         compute_en,     // MAC engine enable
    output reg         adc_en,         // ADC enable
    output reg         result_valid,   // Output data valid
    output reg         busy            // Operation in progress
);

    // Operation codes
    localparam [1:0] OP_IDLE    = 2'b00;
    localparam [1:0] OP_WRITE   = 2'b01;
    localparam [1:0] OP_COMPUTE = 2'b10;
    localparam [1:0] OP_READ    = 2'b11;

    // FSM states
    localparam [2:0] S_IDLE     = 3'd0;
    localparam [2:0] S_WRITE    = 3'd1;
    localparam [2:0] S_COMPUTE  = 3'd2;
    localparam [2:0] S_ADC      = 3'd3;
    localparam [2:0] S_READ     = 3'd4;
    localparam [2:0] S_DONE     = 3'd5;

    reg [2:0] state, next_state;

    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    // Next-state logic
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: begin
                if (start) begin
                    case (op_mode)
                        OP_WRITE:   next_state = S_WRITE;
                        OP_COMPUTE: next_state = S_COMPUTE;
                        OP_READ:    next_state = S_READ;
                        default:    next_state = S_IDLE;
                    endcase
                end
            end
            S_WRITE:    next_state = S_DONE;
            S_READ:     next_state = S_DONE;
            S_COMPUTE:  next_state = S_ADC;
            S_ADC:      next_state = S_DONE;
            S_DONE:     next_state = S_IDLE;
            default:    next_state = S_IDLE;
        endcase
    end

    // Output logic
    always @(*) begin
        sram_wr_en   = 1'b0;
        sram_rd_en   = 1'b0;
        dac_en       = 1'b0;
        compute_en   = 1'b0;
        adc_en       = 1'b0;
        result_valid  = 1'b0;
        busy         = 1'b1;

        case (state)
            S_IDLE: begin
                busy = 1'b0;
            end
            S_WRITE: begin
                sram_wr_en = 1'b1;
            end
            S_READ: begin
                sram_rd_en = 1'b1;
            end
            S_COMPUTE: begin
                dac_en     = 1'b1;
                compute_en = 1'b1;
            end
            S_ADC: begin
                dac_en     = 1'b1;
                compute_en = 1'b1;
                adc_en     = 1'b1;
            end
            S_DONE: begin
                result_valid = 1'b1;
            end
        endcase
    end

endmodule
