`include "defines.v"

module mem(
    input   wire                rst     ,

    // 来自exe阶段的信息
    input   wire [`RegAddrBus]  wd_i    ,
    input   wire                wreg_i  ,
    input   wire [`RegBus]      wdata_i ,
    input   wire [`RegBus]      hi_i    ,
    input   wire [`RegBus]      lo_i    ,
    input   wire                whilo_i ,

    // mem阶段的结果
    output  reg  [`RegAddrBus]  wd_o    ,
    output  reg                 wreg_o  ,
    output  reg  [`RegBus]      wdata_o ,
    output  reg  [`RegBus]      hi_o    ,
    output  reg  [`RegBus]      lo_o    ,
    output  reg                 whilo_o  

);

    // 目前只实现了 ori 指令，且该指令没有mem阶段，因此当前mem阶段不进行操作
    always @(*) begin
        if (rst == `RstEnable) begin
            wd_o    <= `NOPRegAddr;
            wreg_o  <= `WriteDisable;
            wdata_o <= `ZeroWord;
            hi_o    <= `ZeroWord;
            lo_o    <= `ZeroWord;
            whilo_o <= `WriteDisable;
        end
        else begin
            wd_o    <= wd_i;
            wreg_o  <= wreg_i;
            wdata_o <= wdata_i;
            hi_o    <= hi_i;
            lo_o    <= lo_i;
            whilo_o <= whilo_i;
        end
    end

endmodule