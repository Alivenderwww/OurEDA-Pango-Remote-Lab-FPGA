module matrix_key_ctrl #(
    parameter ROW_NUM = 4,
    parameter COL_NUM = 4
)(
    input wire key_ctrl_enable,
    input wire [ROW_NUM*COL_NUM-1:0] key_in,
    input wire [ROW_NUM-1:0] row,
    output reg [COL_NUM-1:0] col
);
    localparam ROW_ACTIVE = 1'b0;   // 行有效电平
    localparam ROW_INACTIVE = 1'b1; // 行无效电平
    localparam COL_PRESSED = 1'b0;  // 列按下电平
    localparam COL_RELEASED = 1'b1; // 列释放电平

    reg [COL_NUM-1:0][ROW_NUM-1:0] key_col;
    integer i, j;
    always @(*) begin
        for(i=0;i<COL_NUM;i=i+1) begin
            for(j=0;j<ROW_NUM;j=j+1) begin
                key_col[i][j] <= key_in[j*COL_NUM+i];
            end
        end
    end
    /*
    处理逻辑
    作为CTRL_FPGA，需要检测ROW的变化调整COL的输出
    如果key_ctrl_enable为0，CTRL_FPGA不控制COL的输出，将其设置为高阻态
    如果key_ctrl_enable为1，CTRL_FPGA控制COL的输出
    */
    integer colomn;
    always @(*) begin
        if(!key_ctrl_enable) col <= {COL_NUM{1'bz}};
        else for(colomn=0;colomn<COL_NUM;colomn=colomn+1)
            col[colomn] <= (|((~(row)^({ROW_NUM{ROW_ACTIVE}})) & key_col[colomn])) ? COL_PRESSED : COL_RELEASED;
    end
endmodule //matrix_key_ctrl