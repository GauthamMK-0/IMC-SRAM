`include "imc_defs.vh"

module row_decoder (
    input  wire [`ADDR_WIDTH-1:0] addr,  
    output wire [`N_ROWS-1:0] one_hot      
);

    assign one_hot = (1 << addr); 

endmodule