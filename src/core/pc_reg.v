`include "defines.v"

module pc_reg(
    input                           clk     ,
    input                           rst     ,

    // 要读取的指令地址
    output  reg [`InstAddrBus]      pc      ,
    // 指令存储器使能信号
    output  reg                     ce

);
    /**
        ce 信号控制
        由复位控制
        高电平同步复位
    */
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            ce <= `ChipDisable;         // 复位的时候指令寄存器禁用
        end
        else begin
            ce <= `ChipEnable;
        end
    end


    always @(posedge clk) begin
        if (~ce <= `ChipDisable) begin
            pc <= 32'h00000000;     // 指令存储器禁用时 pc为0
        end
        else begin
            pc <= pc + 4'h4;        // 指令存储器使能时，pc的值每cycle + 4
        end 
    end

endmodule