module t8_cell (
    input  wire clk,
    input  wire rst,
    input  wire bit_in,
    input  wire write_en,
    input  wire read_en,
    input  wire wl_write,
    input  wire wl_read,
    output wire bit_out
);

    reg bt;

    always @(posedge clk or posedge rst) begin
        if (rst)
            bt <= 1'b0;
        else if (write_en && wl_write)
            bt <= bit_in;
    end

    assign bit_out = (read_en && wl_read) ? bt : 1'b0;

endmodule
