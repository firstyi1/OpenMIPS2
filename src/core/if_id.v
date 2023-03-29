`include "defines.v"
/**
    暂存IF阶段取得的指令 及 对应的指令地址，并在下一个阶段传到ID阶段
*/
module  if_id(
    input                   clk                 ,
    input                   rst                 ,

    // 来自取值阶段的信号
    // 取指阶段取得的指令对应的地址
    input   wire [`InstAddrBus]      if_pc      ,
    // 取指阶段取得的指令
    input   wire [`InstBus]          if_inst    ,

    // 对应的译码阶段信号
    // 译码阶段的指令对应的地址
    output  reg [`InstAddrBus]      id_pc       ,
    // 译码阶段的指令
    output  reg [`InstBus]          id_inst
);

    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            id_pc <= `ZeroWord;      // 复位的时候pc为0
            id_inst <= `ZeroWord;    // 复位的时候指令也为0，实际就是空指令
        end
        else begin
            id_pc <= if_pc;         // 其余时刻向下传递 取指阶段 的值
            id_inst <= if_inst;
        end
    end


endmodule