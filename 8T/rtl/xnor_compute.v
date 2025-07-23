`include "imc_defs.vh"
module xnor_compute (
    input  wire [`N_COLS-1:0] sram_read_data,
    input  wire [`N_COLS-1:0] imc_input_vector,
    input  wire [`N_COLS-1:0] col_sel,
    output wire [`POPCOUNT_WIDTH-1:0] popcount
);

    wire [`N_COLS-1:0] xnor_result = ~(sram_read_data ^ imc_input_vector);
    wire [`N_COLS-1:0] masked_result = xnor_result & col_sel;

    // Popcount calculation
    integer i;
    reg [`POPCOUNT_WIDTH-1:0] count;
    
    always @(*) begin
        count = 0;
        for (i = 0; i < `N_COLS; i = i + 1)
            count = count + {{(`POPCOUNT_WIDTH-1){1'b0}}, masked_result[i]};
    end
    
    assign popcount = count;
endmodule