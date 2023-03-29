`include "defines.v"

module id_ex(
    input wire                  clk         ,
    input wire                  rst         ,

    // 从译码ID阶段传来的信息
    // 运算子类型
    input wire  [`AluOpBus]     id_aluop    ,
    // 运算类型
    input wire  [`AluSelBus]    id_alusel   ,
    // 源操作数1
    input wire  [`RegBus]       id_reg1     ,
    // 源操作数2
    input wire  [`RegBus]       id_reg2     ,
    // 目的寄存器地址
    input wire  [`RegAddrBus]   id_wd       ,
    // 是否有要写入的目的寄存器
    input wire                  id_wreg     ,

    // 传递到执行阶段的信息
    // 运算子类型
    output reg  [`AluOpBus]     ex_aluop    ,
    // 运算类型
    output reg  [`AluSelBus]    ex_alusel   ,
    output reg  [`RegBus]       ex_reg1     ,
    output reg  [`RegBus]       ex_reg2     ,
    output reg  [`RegAddrBus]   ex_wd       ,
    output reg                  ex_wreg

);

    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            ex_aluop    <= `EXE_NOP_OP;
            ex_alusel   <= `EXE_RES_NOP;
            ex_reg1     <= `ZeroWord;
            ex_reg2     <= `ZeroWord;
            ex_wd       <= `NOPRegAddr;
            ex_wreg     <= `WriteDisable;
        end 
        else begin
            ex_aluop    <=  id_aluop;
            ex_alusel   <=  id_alusel;
            ex_reg1     <=  id_reg1; 
            ex_reg2     <=  id_reg2; 
            ex_wd       <=  id_wd; 
            ex_wreg     <=  id_wreg;
        end
    end

endmodule