`include "imc_defs.vh"

module column_decoder (
    input  wire [`COL_WIDTH-1:0] col_addr,       
    output wire [`N_COLS-1:0] col_sel,       
    output wire col_cnt_max     
);

    assign col_sel = (1 << col_addr);
    assign col_cnt_max = (col_addr == (`N_COLS - 1));

endmodule
