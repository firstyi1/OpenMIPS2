`include "defines.v"

module ex(

    input   wire                  rst           ,

    // HILO 模块给出的HI,LO寄存器的信息
    input   wire  [`RegBUs]       hi_i          ,
    input   wire  [`RegBUs]       lo_i          ,

    // WB阶段 指令是否要写HI,LO 用于检测HI，LO带来的数据相关
    input   wire  [`RegBUs]       wb_hi_i       ,
    input   wire  [`RegBUs]       wb_lo_i       ,
    input   wire                  wb_whilo_i    ,

    // MEM阶段 指令是否要写HI,LO 用于检测HI，LO带来的数据相关
    input   wire  [`RegBUs]       mem_hi_i       ,
    input   wire  [`RegBUs]       mem_lo_i       ,
    input   wire                  mem_whilo_i    ,

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
    output  reg  [`RegAddrBus]    wd_o          ,
    // 是否有要写入的目的寄存器
    output  reg                   wreg_o        ,
    // 要写入目的寄存器的值
    output  reg  [`RegBus]        wdata_o       ,

    // EXE阶段的指令对HI,LO寄存器的write operation
    input   wire  [`RegBUs]       hi_o          ,
    input   wire  [`RegBUs]       lo_o          ,
    input   wire                  whilo_o       

);
    // 保存逻辑运算的结果
    reg[`RegBus]    logicout;
    // 保存移位运算的结果
    reg[`RegBus]    shiftres;
    // 保存移动运算的结果
    reg[`RegBus]    moveres;
    // 保存HI LO寄存器的最新值
    reg[`RegBus]    HI;
    reg[`RegBus]    LO;

    /**
        1. get the latest values of HI and LO register
        resolve data hazard (RAW)
    */
    always @(*) begin
        if (rst == `RstEnable) begin
            {HI, LO} <= {`ZeroWord, `ZeroWord};
        end
        // the inst in MEM need to write HILO
        else if (mem_whilo_i == `WriteEnable) begin
            {HI, LO} <= {mem_hi_i, mem_lo_i}; 
        end
        // the inst in WB need to write HILO
        else if (wb_whilo_i == `WriteEnable) begin
            {HI, LO} <= {wb_hi_i, wb_lo_i}; 
        end
        else begin
            {HI, LO} <= {hi_i, lo_i}; 
        end
    end
    // ps: 这里用if else可以看出来mux是具有优先级的

    /**
        1. 根据 aluop_i 的运算子类型进行运算
    */
    /**
        1.1 logic operation
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
        1.2 shift operation
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
        1.3 move operation
    */
    always @(*) begin
        if (rst == `RstEnable) begin
            moveres <= `ZeroWord;
        end 
        else begin
            moveres <= `ZeroWord;
            case (aluop_i)
                // MOVE from HI
                `EXE_MFHI_OP: begin
                    moveres <= HI;
                end
                // MOVE from LO
                `EXE_MFLO_OP: begin
                    moveres <= LO;
                end
                // MOVE rs to rd
                `EXE_MOVZ_OP: begin
                    moveres <= reg1_i;
                end
                // MOVE rs to rd
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

    /**
        3. MTHI MTLO inst
    */
    always @(*) begin
        if (rst == `RstEnable) begin
            whilo_o <= `WriteDisable;
            hi_o    <= `ZeroWord;
            lo_o    <= `ZeroWord;
        end
        else if (aluop_i == `EXE_MTHI_OP) begin
            whilo_o <= `WriteEnable;
            hi_o    <= reg1_i;
            // LO remains unchanged
            lo_o    <= LO;
        end
        else if (aluop_i == `EXE_MTLO_OP) begin
            whilo_o <= `WriteEnable;
            // HI remains unchanged
            hi_o    <= HI;
            lo_o    <= reg1_i;
        end
        else begin
            whilo_o <= `WriteDisable;
            hi_o    <= `ZeroWord;
            lo_o    <= `ZeroWord;
        end
    end

endmodule