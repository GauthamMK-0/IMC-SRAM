`include "imc_defs.vh"
module control_fsm (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire col_cnt_max,
    input  wire done_clear,
    output reg write_en,
    output reg read_en,
    output reg accum_en,
    output reg accum_clear,
    output reg col_cnt_en,
    output reg col_cnt_clear,
    output reg done
);

    typedef enum logic [2:0] {
        IDLE, WRITE, READ, 
        COMPUTE, COMPUTE_LOOP, DONE
    } state_t;

    state_t curr_state, next_state;

    always @(posedge clk or posedge rst) begin
        if (rst) curr_state <= IDLE;
        else curr_state <= next_state;
    end

    always @(*) begin
        next_state = curr_state;
        case (curr_state)
            IDLE:     if (start) next_state = WRITE;
            WRITE:    next_state = READ;
            READ:     next_state = COMPUTE;
            COMPUTE:  next_state = COMPUTE_LOOP;
            COMPUTE_LOOP: next_state = col_cnt_max ? DONE : COMPUTE;
            DONE:     if (done_clear) next_state = IDLE;
            default:  next_state = IDLE;
        endcase
    end

    always @(*) begin
        {write_en, read_en, accum_en, accum_clear, 
         col_cnt_en, col_cnt_clear, done} = 0;
         
        case (curr_state)
            IDLE: {accum_clear, col_cnt_clear} = 2'b11;
            WRITE: write_en = 1'b1;
            READ: read_en = 1'b1;
            COMPUTE_LOOP: {accum_en, col_cnt_en} = 2'b11;
            DONE: done = 1'b1;
        endcase
    end
endmodule
