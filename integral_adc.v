module integral_adc (
    output reg charge,      //由-ref控制进行充电
    output reg discharge,   //由+ref控制进行放电
    output reg input_charge,//未知电压充电控制
    output reg discharge_end,//结束放电控制



    input wire clock, //时钟输入 同步信号 上升沿同步

	input wire spi_cs,  // spi_interface片选和触发
	input wire spi_sck, // spi_interface时钟
	input wire spi_sda // spi_interface数据
    
);
    reg high_voltage = 1'b1 ;//输出高电平
    reg low_voltago  = 1'b0 ;//输出低电平

    reg main_counter_clr;        //main_cunter使能端 高电平失能计数器 低电平使能计数器 同时清零
    reg dealy_counter_clr;       //dealy_cunter使能端 高电平失能计数器 低电平使能计数器 同时清零

    reg[23 : 0] spi_data_reg;  //spi接口得到的24bit命令

    reg[15 : 0] main_counter;  //  16bit主寄存器输出值
    reg[15 : 0] delay_counter; // 15bit辅助延时寄存器

/*********command register*************/
    reg[  7 : 0 ] start_counter_point;  // 开始积分过程延时
    reg[ 15 : 0 ] charge_end_point;     // 结束积分充电标志 开始放电标志位
    reg[ 15 : 0 ] discharge_end_point;  // 结束放电标志位 开始进入保持状态等待读取残余电荷
    reg[ 15 : 0 ] end_delay_ctrl;       // 延时时间控制 标记结束点位 结束保持后开始放电过程
    reg[ 9  : 0 ] end_discharge_ctrl;   // 放电时间控制 //由于使用完全短接放电 时间可以很短 后续可以更改
    reg[ 2  : 0 ] charge_channel_choose;// 充电通道选择 一共五种可能
    reg        discharge_channel_choose;// 放电通道选择 一共两种可能
    reg        integral_flag;           // 积分运行信号 需要外部添加 置1开始积分  积分完成后自动置零 等待下一次置1



//例化主程序计数器 时钟 输出 清零
counter_main u1(
	.clock(clock),
	.q(main_counter),
	.sclr(main_counter_clr)
);

//例化延时计数器 时钟 输出 清零
counter_delay u2(
	.clock(clock),
	.q(delay_counter),
	.sclr(delay_counter_clr)
);

//例化spi接口
spi_interface u3(
	.cs(spi_cs),
	.sck(spi_sck),
	.sda(spi_sda),
	
	.data_reg(spi_data_reg)
);


always @(posedge clock) begin

    if(integral_flag == 1'b0)               begin
    /*判断integral_flag是否清除 如果清除 使能mian_counter 进入积分流程*/
        main_counter_clr <= 1'b0;//停止清零 使能main_counter 进入积分
    end


    if(main_counter == start_counter_point) begin
        /*置位 integral_flag  停止下次转换 等待外部清除   避免时序冲突*/
        integral_flag <= 1'b1 ;//置位 integral_flag 
        /*写一个三八译码器 使用五种可能
        充电启动过程 需要分析charge_channel_choose 选相应的充电通道*/
        case (charge_channel_choose[ 2 : 0 ])
            //由未知信号充电
            3'h1: input_charge <= 1'b0 ;            
            //由+ref充电 
            3'h2: charge       <= 1'b0 ;
            //由-ref充电 
            3'h3: discharge    <= 1'b0 ;
            //由未知信号和正ref一起充电
            3'h4: begin
                input_charge   <= 1'b0 ;
                charge         <= 1'b0 ;
                end
            //由未知信号和-ref一起充电
            3'h5: begin
                input_charge   <= 1'b0 ;
                discharge      <= 1'b0 ;                                
                end

            default: begin
            /* 将全部充放电通道关闭 */
                input_charge  <= 1'b1 ;
                charge        <= 1'b1 ;
                discharge     <= 1'b1 ;
                discharge_end <= 1'b1 ;
                end
        endcase

    end


    if(main_counter == charge_end_point )    begin
        /*复制三八译码器 确定充电通道 关闭通道*/
        case (charge_channel_choose[ 2 : 0 ])
            //关闭未知信号充电
            3'h1: input_charge <= 1'b1 ;            
            //关闭+ref充电 
            3'h2: charge       <= 1'b1 ; 
            //关闭-ref充电 
            3'h3: discharge    <= 1'b1 ; 
            //关闭未知信号和正ref
            3'h4: begin
                input_charge   <= 1'b1 ; 
                charge         <= 1'b1 ; 
                end
            //关闭未知信号和-ref
            3'h5: begin
                input_charge   <= 1'b1 ; 
                discharge      <= 1'b1 ;                               
                end

            default: begin
                    //嘛都不干
                end
        endcase

        /*放电通道需要一个二选一数据选择器 解码discharge_channel_choose获得*/
        case (discharge_channel_choose)
            1'b0: discharge   <= 1'b0 ;//使用+ref进行放电
            1'b1: charge      <= 1'b0 ;//使用-ref进行放电

            default: begin
                    //嘛都不干
            end
        endcase
    end

    if(main_counter  == discharge_end_point ) begin
    /*放电结束 将全部充放电通道关闭 */
        input_charge  <= 1'b1 ;
        charge        <= 1'b1 ;
        discharge     <= 1'b1 ;
        discharge_end <= 1'b1 ;
    /*使能delay_counter*/
        delay_counter_clr <= 1'b0 ;
    end


    if(delay_counter == end_delay_ctrl) begin
        //保持转换延时 结束 开始进入结束放电延时
        discharge_end = 1'b0 ;//开始放电
    end


    if(delay_counter == end_discharge_ctrl) begin
        //放电延时结束 失能 delay_counter
        discharge_end = 1'b1 ;//结束放电
        delay_counter_clr = 1'b1 ;//失能delay_counter
    end
end

/************************************************

                register table
    01h start_counter_point  [  7 : 0 ] 
    02h charge_end_point;    [ 15 : 0 ]
    03h discharge_end_point; [ 15 : 0 ]
    04h end_delay_ctrl;      [ 15 : 0 ]
    05h end_discharge_ctrl;  [ 9  : 0 ]
    06h charge_channel_choose; [ 2  : 0 ]
    07h discharge_channel_choose;  &  integral_flag;  

***********************************************/

always @(posedge spi_cs) begin
    //从spi_data_reg取数据 前八位为寄存器地址  后16位为数据
    case (spi_data_reg[ 18 : 16 ])//取16到18位 为指令地址
        3'h1: start_counter_point [7 : 0] <= spi_data_reg [7 : 0 ];
        3'h2: charge_end_point    [15: 0] <= spi_data_reg [15: 0 ];
        3'h3: discharge_end_point [15: 0] <= spi_data_reg [15: 0 ];
        3'h4: end_delay_ctrl      [15: 0] <= spi_data_reg [15: 0 ];
        3'h5:end_discharge_ctrl   [9 : 0] <= spi_data_reg [ 9: 0 ];
        3'h6: begin
            charge_channel_choose[2 : 0] = spi_data_reg [2 : 0];
            discharge_channel_choose     = spi_data_reg [3];
            integral_flag                = spi_data_reg [4];
        end
        
        default: begin
            //
        end
    endcase
end
endmodule
