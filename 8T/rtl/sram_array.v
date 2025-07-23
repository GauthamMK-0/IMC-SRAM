`include "imc_defs.vh"

module sram_array (
    input  wire clk,
    input  wire rst,
    input  wire write_en,
    input  wire read_en,
    input  wire [`N_ROWS-1:0] wl_write,
    input  wire [`N_ROWS-1:0] wl_read,
    input  wire [`N_COLS-1:0] write_data,
    output wire [`N_COLS-1:0] read_data
);

    genvar row, col;
    generate
        for (row = 0; row < `N_ROWS; row = row + 1) begin : row_gen
            for (col = 0; col < `N_COLS; col = col + 1) begin : col_gen
                t8_cell bit_cell (
                    .clk(clk),
                    .rst(rst),
                    .bit_in(write_data[col]),
                    .write_en(write_en),
                    .read_en(read_en),
                    .wl_write(wl_write[row]),
                    .wl_read(wl_read[row]),
                    .bit_out(read_data[col])
                );
            end
        end
    endgenerate
endmodule