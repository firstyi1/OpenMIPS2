`include "defines.v"

/**
    包含32个32位通用整数寄存器，可以同时进行2个寄存器的读操作和一个寄存器的写操作
    根据MIPS32架构规定 $0 地址 值只能为 0
    写操作是时序逻辑
    读操作是组合逻辑，一旦读地址发生变化 可以立即给出新地址的值 保证在译码阶段取得寄存器的值 
*/
module regfile(
    input   wire                    clk     ,
    input   wire                    rst     ,

    // 写端口
    input   wire                    we      ,
    input   wire  [`RegAddrBus]     waddr   ,
    input   wire  [`RegBus]         wdata   ,  

    // 读端口1  
    input   wire                    re1     ,
    input   wire  [`RegAddrBus]     raddr1  ,
    output  reg   [`RegBus]         rdata1  ,

    // 读端口2  
    input   wire                    re2     ,
    input   wire  [`RegAddrBus]     raddr2  ,
    output  reg   [`RegBus]         rdata2  

);

    /**
        定义32个32为寄存器
    */
    reg [`RegBus]   regs[0: `RegNum - 1];

    /**
        写操作
    */
    always @(posedge clk) begin
        // 复位信号无效
        if (rst == `RstDisable) begin
            // 写使能 并且 写地址不为0
            if ((we == `WriteEnable) && (waddr != `ReqNumLog2'h0)) begin
                regs[waddr] <= wdata;
            end
        end
    end

    /**
        读端口1的操作
    */
    always @(*) begin
        // 复位信号有效
        if (rst == `RstEnable) begin
            rdata1 <= `ZeroWord;
        end
        // 如果读地址是0 直接返回0
        else if (raddr1 == `ReqNumLog2'h0) begin
            rdata1 <= `ZeroWord;
        end
        // 同时读写一个地址时，直接将写入数据传给读数据
        else if ((raddr1 == waddr) && (we == `WriteEnable) && (re1 == `ReadEnable)) begin
            rdata1 <= wdata;
        end
        // 读使能
        else if(re1 == `ReadEnable) begin
            rdata1 <= regs[raddr1];
        end
        // 禁止读
        else begin
            rdata1 <= `ZeroWord;
        end
    end

    /**
        读端口2的操作
    */
    always @(*) begin
        // 复位信号有效
        if (rst == `RstEnable) begin
            rdata2 <= `ZeroWord;
        end
        // 如果读地址是0 直接返回0
        else if (raddr1 == `ReqNumLog2'h0) begin
            rdata2 <= `ZeroWord;
        end
        // 同时读写一个地址时，直接将写入数据传给读数据
        else if ((raddr1 == waddr) && (we == `WriteEnable) && (re1 == `ReadEnable)) begin
            rdata2 <= wdata;
        end
        // 读使能
        else if(re1 == `ReadEnable) begin
            rdata2 <= regs[raddr1];
        end
        // 禁止读
        else begin
            rdata2 <= `ZeroWord;
        end
    end

endmodule