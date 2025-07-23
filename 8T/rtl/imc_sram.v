`include "imc_defs.vh"

module imc_sram (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire [`ADDR_WIDTH-1:0] row_addr,
    input  wire [`N_COLS-1:0] write_data,
    input  wire [`N_COLS-1:0] input_vector,
    output wire done,
    output wire [`ACC_WIDTH-1:0] accum_out
);

    // Control Signals
    wire write_en, read_en, accum_en, accum_clear;
    wire col_cnt_en, col_cnt_clear, col_cnt_max;

    // Column Counter and Select
    reg [`COL_WIDTH-1:0] col_counter;
    wire [`N_COLS-1:0] col_sel;

    // Data Path Signals
    wire [`N_ROWS-1:0] wl_write, wl_read;
    wire [`POPCOUNT_WIDTH-1:0] popcount;

    wire [`N_COLS-1:0] sram_read_data;
    reg  [`N_COLS-1:0] sram_read_data_reg;

    control_fsm fsm (
        .clk(clk),
        .rst(rst),
        .start(start),
        .col_cnt_max(col_cnt_max),
        .done_clear(start), 
        .write_en(write_en),
        .read_en(read_en),
        .accum_en(accum_en),
        .accum_clear(accum_clear),
        .col_cnt_en(col_cnt_en),
        .col_cnt_clear(col_cnt_clear),
        .done(done)
    );

    row_decoder row_dec_write (
        .addr(row_addr),
        .one_hot(wl_write)
    );

    row_decoder row_dec_read (
        .addr(row_addr),
        .one_hot(wl_read)
    );

    column_decoder col_dec (
        .col_addr(col_counter),
        .col_sel(col_sel),
        .col_cnt_max(col_cnt_max)
    );


    always @(posedge clk or posedge rst) begin
        if (rst || col_cnt_clear)
            col_counter <= 0;
        else if (col_cnt_en)
            col_counter <= col_counter + 1;
    end

    sram_array sram (
        .clk(clk),
        .rst(rst),
        .write_en(write_en),
        .read_en(read_en),
        .wl_write(wl_write),
        .wl_read(wl_read),
        .write_data(write_data),
        .read_data(sram_read_data)  
    );

   always @(posedge clk or posedge rst) begin
    if (rst)
        sram_read_data_reg <= {`N_COLS{1'b0}};
    else if (read_en)
        sram_read_data_reg <= sram_read_data;
end


    xnor_compute compute (
        .sram_read_data(sram_read_data_reg),
        .imc_input_vector(input_vector),
        .col_sel(col_sel),
        .popcount(popcount)
    );

    accumulator accum (
        .clk(clk),
        .rst(rst),
        .popcount(popcount),
        .accum_en(accum_en),
        .clear(accum_clear),
        .accum_out(accum_out)
    );

endmodule