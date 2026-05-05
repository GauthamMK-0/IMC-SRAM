`include "imc_defs.vh"

module accumulator (
    input  wire clk,
    input  wire rst,
    input  wire [`POPCOUNT_WIDTH-1:0] popcount, 
    input  wire accum_en,    
    input  wire clear,       
    output reg [`ACC_WIDTH-1:0] accum_out  
);

    always @(posedge clk or posedge rst) begin
        if (rst || clear) begin
            accum_out <= {`ACC_WIDTH{1'b0}};  
        end else if (accum_en) begin
            if (&accum_out)
                accum_out <= {`ACC_WIDTH{1'b1}};
            else
                accum_out <= accum_out + {{(`ACC_WIDTH-`POPCOUNT_WIDTH){1'b0}}, popcount};
        end
    end

endmodule