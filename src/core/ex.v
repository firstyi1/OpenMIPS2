`include "defines.v"

module ex(

    input   wire                  rst           ,

    // 译码阶段送到执行阶段的信息
    // 运算子类型
    input   wire  [`AluOpBus]     aluop_i       ,
    // 运算类型 
    input   wire  [`AluSelBus]    alusel_i      ,
    // 源操作数1    
    input   wire  [`RegBus]       reg1_i        ,
    // 源操作数2    
    input   wire  [`RegBus]       reg2_i        ,
    // 目的寄存器地址   
    input   wire  [`RegAddrBus]   wd_i          ,
    // 是否有要写入的目的寄存器 
    input   wire                  wreg_i        ,

    // 执行的结果
    // 目的寄存器地址
    output  reg  [`RegAddrBus]   wd_o           ,
    // 是否有要写入的目的寄存器
    output  reg                  wreg_o         ,
    // 要写入目的寄存器的值
    output  reg  [`RegBus]       wdata_o     

);
    // 保存逻辑运算的结果
    reg[`RegBus]    logicout;
    // 保存移位运算的结果
    reg[`RegBus]    shiftres;
    // 保存移动运算的结果
    reg[`RegBus]    moveres;
    
    /**
        1. 根据 aluop_i 的运算子类型进行运算
        1.1 进行逻辑运算
    */
    always @(*) begin
        if (rst == `RstEnable) begin
            logicout <= `ZeroWord;
        end
        else begin
            case (aluop_i)
                // or
                `EXE_OR_OP: begin
                    logicout <= reg1_i | reg2_i;
                end
                // and
                `EXE_AND_OP: begin
                    logicout <= reg1_i & reg2_i;
                end
                // nor
                `EXE_NOR_OP: begin
                    logicout <= ~(reg1_i | reg2_i);
                end
                // xor
                `EXE_XOR_OP: begin
                    logicout <= reg1_i ^ reg2_i;
                end
                default: begin
                    logicout <= `ZeroWord;
                end
            endcase
        end
    end

    /**
        1. 根据 aluop_i 的运算子类型进行运算
        1.2 进行移位运算
    */
    always @(*) begin
        if (rst == `RstEnable) begin
            shiftres <= `ZeroWord;
        end else begin
            case (aluop_i)
                // 逻辑左移
                `EXE_SLL_OP: begin
                    shiftres <= reg2_i << reg1_i[4:0];
                end
                // 逻辑右移
                `EXE_SRL_OP: begin
                    shiftres <= reg2_i >> reg1_i[4:0];
                end
                // 算数右移
                `EXE_SRA_OP: begin
                    // 算数右移
                    // 这里为什么不直接使用 >>> 
                    // 是因为 >>> 进行算术右移的时候，如果操作数不是有符号数，即使最高位是1，使用>>>时仍然会在高位补0，而在verilog中通常使用reg定义的都是无符号数
                    // ({32{reg2_i[31]}} << (6'd32 - {1'b0,reg1_i[4:0]}))
                    shiftres <= ({32{reg2_i[31]}} << (6'd32 - {1'b0,reg1_i[4:0]})) | (reg2_i >> reg1_i[4:0]);
                end
                default: begin
                    shiftres <= `ZeroWord;
                end
            endcase
        end //if
    end //always

    /**
        1. 根据 aluop_i 的运算子类型进行运算
        1.3 进行移动运算
    */
    always @(*) begin
        if (rst == `RstEnable) begin
            moveres <= `ZeroWord;
        end 
        else begin
            case (aluop_i)
                // 逻辑左移
                `EXE_MOVN_OP: begin
                    moveres <= reg1_i;
                end
                default: begin
                    
                end
            endcase
        end //if
    end //always

    /**
        2. 根据 alusel_i 的运算类型，选择一个运算结果作为最终结果
    */
    always @(*) begin
        wd_o    <=  wd_i;
        wreg_o  <=  wreg_i;
        case (alusel_i)
            // 逻辑运算
            `EXE_RES_LOGIC: begin
                wdata_o <= logicout; 
            end
            // 移位运算
            `EXE_RES_SHIFT: begin
                wdata_o <= shiftres;
            end
            // 移动运算
            `EXE_RES_MOVE: begin
                wdata_o <= moveres;
            end
            default: begin
                // 对于未定义的运算类型 和 NOP指令 直接返回空
                wdata_o <= `ZeroWord;
            end
        endcase
    end

endmodule