
`timescale 1 ns / 1 ns
module syncdff #(
parameter                           DATA_SIZE = 4,
parameter                           SYNC_NUM  = 3,
parameter                           U_DLY     = 1
)
(
input                               rst_n,
input                               clk,
input           [DATA_SIZE-1:0]     data_in,    // data from another clock domain, different from 'clk'
output wire     [DATA_SIZE-1:0]     data_sync   // data synchronized to 'clk' clock domain
);
// Parameter Define 
localparam                          DFF_SIZE = DATA_SIZE*SYNC_NUM;
// Register Define 
reg             [DFF_SIZE-1:0]      dff_metastable /* synthesis syn_keep=1 */;

// Wire Define 

always @ (posedge clk or negedge rst_n)
begin
    if (rst_n==1'b0)     
        dff_metastable <=#U_DLY {DFF_SIZE{1'b0}};
    else
        dff_metastable <=#U_DLY {dff_metastable[DFF_SIZE-DATA_SIZE-1:0], data_in};
end

assign data_sync = dff_metastable[DFF_SIZE-1:DFF_SIZE-DATA_SIZE];

endmodule

