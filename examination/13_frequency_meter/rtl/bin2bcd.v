module bin2bcd
#( 
	parameter	W = 8	//输入位宽可变
)  					
( 
	input		[W-1 :0] 		bin,	
	output reg	[W+(W-4)/3:0]	bcd   
); 					

integer i,j;	//循环参数

always @(*) begin
	for(i = 0; i <= W+(W-4)/3; i = i+1) 
		bcd[i] = 0;     	//用全0初始化
	bcd[W-1:0] = bin; 		//低位用输入替换
	
	for(i = 0; i <= W-4; i = i+1)                       	
		for(j = 0; j <= i/3; j = j+1)                     	
            if (bcd[W-i+4*j -: 4] > 4)	//如果大于4
				bcd[W-i+4*j -: 4] = bcd[W-i+4*j -: 4] + 4'd3; //+3
end

endmodule
