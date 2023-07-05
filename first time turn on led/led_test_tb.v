`timescale  1ns/1ps

module led_test_tb;
//激励信号定义 对应到待测试模块输入端口
	reg signal_a;
	reg signal_b;
	reg signal_c;
//检测信号定义 对应到待测是输出端口

	wire led;
//例化待测模块
	led_test led_test0(
	.a(signal_a),
	.b(signal_b),
	.sw(signal_c),
	.led_out(led)
	);
//产生激励
	initial begin 
		signal_a=0;signal_b=0;signal_c=0;
		#100;
		signal_a=0;signal_b=0;signal_c=1;
		#100;
		signal_a=0;signal_b=1;signal_c=0;
		#100;
		signal_a=0;signal_b=1;signal_c=1;
		#100;
		signal_a=1;signal_b=0;signal_c=0;
		#100;
		signal_a=1;signal_b=0;signal_c=1;
		#100;
		signal_a=1;signal_b=1;signal_c=0;
		#100;
		signal_a=1;signal_b=1;signal_c=1;
		#200;	
		$stop;
	end

endmodule