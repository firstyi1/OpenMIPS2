`include "defines.v"

module inst_rom(
    // 使能信号
    input   wire                ce      ,
    // 要读取的指令地址 
    input   wire [`InstAddrBus] addr    ,

    // 读出的指令
    output  reg  [`InstBus]     inst
);

    // 指令宽度为 InstBus, 大小为 InstMemNum
    reg[`InstBus] inst_mem[0: `InstMemNum - 1];

    // 使用文件inst_rom.data 对inst_mem 进行初始化
    initial $readmemh("../data/inst_rom.data", inst_mem);

    always @(*) begin
        if (ce == `ChipDisable) begin
            inst <= `ZeroWord;
        end
        else begin
            // 指令存储器的每个地址是 一个32bit的字，所以要将指令地址除以 4再使用
            // 例如指令地址 及其 对应的inst_mem地址
            // 0x0 0
            // 0x4 1
            // 0x8 2
            // 0xC 3
            inst <= inst_mem[addr[`InstMemNumLog2+1 : 2]];
        end
    end


endmodule