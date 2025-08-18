module matrix_key #(
    parameter ROW_NUM = 4,
    parameter COL_NUM = 4,
    parameter DEBOUNCE_TIME = 2000,
    parameter DELAY_TIME = 200
) (
    input  wire clk/* synthesis PAP_MARK_DEBUG="true" */,
    input  wire rstn/* synthesis PAP_MARK_DEBUG="true" */,
    output  reg [ROW_NUM-1:0] row/* synthesis PAP_MARK_DEBUG="true" */,
    input  wire [COL_NUM-1:0] col/* synthesis PAP_MARK_DEBUG="true" */,
    output  reg [ROW_NUM*COL_NUM-1:0] key_out/* synthesis PAP_MARK_DEBUG="true" */
);

    localparam ROW_ACTIVE = 1'b0;   // 行有效电平
    localparam ROW_INACTIVE = 1'b1; // 行无效电平
    localparam COL_PRESSED = 1'b0;  // 列按下电平
    localparam COL_RELEASED = 1'b1; // 列释放电平
    
    reg [ROW_NUM-1:0][COL_NUM-1:0] key/* synthesis PAP_MARK_DEBUG="true" */; // 按键状态寄存器

    reg [2:0] cu_st/* synthesis PAP_MARK_DEBUG="true" */, nt_st/* synthesis PAP_MARK_DEBUG="true" */;
    localparam [2:0] ST_IDLE = 3'b001;
    localparam [2:0] ST_SCAN = 3'b010;
    localparam [2:0] ST_DEBOUNCE = 3'b100;

    wire btn_pressed = ((|(~(col ^ {COL_NUM{COL_PRESSED}}))) && (cu_st == ST_IDLE)) || (key_out != 0)/* synthesis PAP_MARK_DEBUG="true" */; // 只要有一个按键按下，btn_pressed为1
    reg [31:0] delay_cnt/* synthesis PAP_MARK_DEBUG="true" */; // 延时计数器
    reg [31:0] debounce_cnt/* synthesis PAP_MARK_DEBUG="true" */; // 消抖计数器
    reg [ROW_NUM-1:0] row_cnt/* synthesis PAP_MARK_DEBUG="true" */; // 行计数器

    always @(posedge clk or negedge rstn) begin
        if(!rstn) delay_cnt <= 0;
        else if(cu_st == ST_SCAN) begin
            if(delay_cnt == DELAY_TIME) delay_cnt <= 0;
            else delay_cnt <= delay_cnt + 1;
        end else delay_cnt <= 0;
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn) row_cnt <= 0;
        else if(cu_st == ST_SCAN) begin
            if(delay_cnt == DELAY_TIME) row_cnt <= row_cnt + 1;
            else row_cnt <= row_cnt;
        end else row_cnt <= 0;
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn) debounce_cnt <= 0;
        else if(cu_st == ST_DEBOUNCE) begin
            if(debounce_cnt == DEBOUNCE_TIME) debounce_cnt <= 0;
            else debounce_cnt <= debounce_cnt + 1;
        end else debounce_cnt <= 0;
    end

    /*
    处理逻辑
    ROW作为输出，COL作为输入
    1. ST_IDLE状态，所有ROW都拉至有效电平
    2. 若没有按键按下，所有COL都为释放电平
    3. 若有按键按下，按下的按键所在的COL会变为按下电平
    4. 进入ST_SCAN状态，启动扫描，ROW全部置为无效电平，并逐次改变为有效电平。（此时，COL会都变成列释放电平）
    5. 如果某一个ROW行有效电平时，COL变成了列按下电平，则说明该ROW和COL交点的按键被按下
    6. 每一行都扫描一遍。
    7. 进入ST_DEBOUNCE状态，所有ROW都拉至行有效电平，在此期间不进行扫描。
    8. DEBOUNCE时间到后，进入IDLE状态。
    */

    always @(posedge clk or negedge rstn) begin
        if(!rstn) cu_st <= ST_IDLE;
        else cu_st <= nt_st;
    end

    always @(*) begin
        if(!rstn) nt_st <= ST_IDLE;
        else case(cu_st)
            ST_IDLE: begin
                if(btn_pressed) nt_st <= ST_SCAN;
                else nt_st <= ST_IDLE;
            end
            ST_SCAN: begin
                if((delay_cnt == DELAY_TIME) && (row_cnt == ROW_NUM-1)) nt_st <= ST_DEBOUNCE;
                else nt_st <= ST_SCAN;
            end
            ST_DEBOUNCE: begin
                if(debounce_cnt == DEBOUNCE_TIME) nt_st <= ST_IDLE;
                else nt_st <= ST_DEBOUNCE;
            end
            default: nt_st <= ST_IDLE;
        endcase
    end

    integer i, j;
    always @(posedge clk or negedge rstn) begin
        if(!rstn) key <= 0;
        else for(i=0; i<ROW_NUM; i=i+1) 
                for(j=0; j<COL_NUM; j=j+1)
                    if((cu_st == ST_SCAN) && (delay_cnt == DELAY_TIME) && (row_cnt == i)) key[i][j] <= (col[j] == COL_PRESSED)?(1'b1):(1'b0);
                    else key[i][j] <= key[i][j]; // 其他情况不变
    end

    always @(*) begin
        for(i=0;i<ROW_NUM;i=i+1) begin
            for(j=0;j<COL_NUM;j=j+1) begin
                key_out[i*COL_NUM+j] <= key[i][j];
            end
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn) row <= {ROW_NUM{ROW_ACTIVE}};
        else if(cu_st == ST_IDLE && nt_st == ST_SCAN) row <= {{(ROW_NUM-1){ROW_INACTIVE}}, ROW_ACTIVE};
        else if(cu_st == ST_SCAN) begin
            if(delay_cnt == DELAY_TIME) row <= {row[ROW_NUM-1:0],ROW_INACTIVE};
            else row <= row;
        end else row <= {ROW_NUM{ROW_ACTIVE}};
    end
endmodule //matrix_key
