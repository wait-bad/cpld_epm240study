/***�?�?***/
//通过类似spi协�??控制内部寄存�?
//三个io引脚  sck sda cs
/******程序设�??*******/
//cs片�? 低电平有�?
//sck时钟 上升沿有�? 将sda数据采集到内�?
//cs上升�? 将寄存器移位到实际寄存器

module spi_interface (
    input wire sck,
    input wire sda,
    input wire cs,

    output reg[ 23 : 0 ] data_,
	 output reg[23 : 0] data_reg
);



    /*reg command1[ 7 : 0] = 8'h01;
    reg command2[ 7 : 0] = 8'h02;
    reg command3[ 7 : 0] = 8'h03;
    reg command4[ 7 : 0] = 8'h04;
    reg command5[ 7 : 0] = 8'h05;*/


always @(posedge sck) begin

    if(cs == 1'b0) begin
            data_reg[ 23 : 1 ] = data_reg[ 22 : 0 ];
            data_reg[0]   = sda;
    end
	 
	 if(cs == 1'b1) begin
		data_[ 23 : 0] <= data_reg [ 23 : 0 ];	 
	 end
end

endmodule
