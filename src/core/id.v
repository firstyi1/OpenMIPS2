`include "defines.v"

/**
    译码阶段
    MIPS指令分类：
    1. I型指令(立即数指令)
        | op(6位) | rs(5位) | rt(5位) | immediate(16位)

    2. R型指令(inst[31:26]为0, 一般是两个寄存器数之间的操作)
        | op(6位) | rs(5位) | rt(5位) | rd(5位) | shamt(5位) | funct(6位) | 
        op 操作码为 0
        shamt 偏移量
        funct 功能码

    3. J型指令(跳转指令)
        | op(6位) | immediate(26位)
*/
module id(
    input   wire                        rst         ,
    // 译码阶段的指令对应的地址
    input   wire    [`InstAddrBus]      pc_i        ,
    // 译码阶段的指令
    input   wire    [`InstBus]          inst_i      ,

    // 读取的Regfile的值
    // 从Regfile输入的第一个读寄存器端口的输入
    input   wire    [`RegBus]           reg1_data_i ,
    // 从Regfile输入的第二个读寄存器端口的输入
    input   wire    [`RegBus]           reg2_data_i ,

    // 处于 EXE 阶段的指令的运算结果
    // ex阶段 是否有要写入的目的寄存器
    input   wire                        ex_wreg_i   ,
    // ex阶段 要写入寄存器的数据
    input   wire    [`RegBus]           ex_wdata_i  ,
    // ex阶段 要写入的目的寄存器的地址
    input   wire    [`RegAddrBus]       ex_wd_i     ,

    
    // 处于 MEM 阶段的指令的运算结果
    // MEM阶段 是否有要写入的目的寄存器
    input   wire                        mem_wreg_i  ,
    // MEM阶段 要写入寄存器的数据
    input   wire    [`RegBus]           mem_wdata_i ,
    // MEM阶段 要写入的目的寄存器的地址
    input   wire    [`RegAddrBus]       mem_wd_i    ,


    // 输出到Regfile的信息
    // Regfile 模块的第一个读寄存器端口的读使能信号
    output  reg                         reg1_read_o ,
    // Regfile 模块的第二个读寄存器端口的读使能信号
    output  reg                         reg2_read_o ,
    // Regfile 模块的第一个读寄存器端口的读地址信号
    output  reg     [`RegAddrBus]       reg1_addr_o ,
    // Regfile 模块的第二个读寄存器端口的读地址信号
    output  reg     [`RegAddrBus]       reg2_addr_o ,

    // 译码阶段的指令要进行的运算的子类型
    output  reg     [`AluOpBus]         aluop_o     ,
    // 译码阶段的指令要进行的运算的类型
    output  reg     [`AluSelBus]        alusel_o    ,
    // 译码阶段的指令要进行的运算的源操作数1
    output  reg     [`RegBus]           reg1_o ,
    // 译码阶段的指令要进行的运算的源操作数2
    output  reg     [`RegBus]           reg2_o ,
    // 译码阶段的指令要写入的目的寄存器地址
    output  reg     [`RegAddrBus]       wd_o ,
    // 译码阶段的指令是否有要写入的目的寄存器
    output  reg                         wreg_o

);

    // 取得指令的指令码，功能码
    // 对于ori指令只需要判断26-31bit的值
    wire [5:0] op = inst_i[31:26];
    wire [4:0] op2 = inst_i[10:6];
    wire [5:0] op3 = inst_i[5:0];
    wire [4:0] op4 = inst_i[20:16];

    // 保存指令执行需要的立即数
    reg  [`RegBus]  imm;

    // 指示指令是否有效
    reg  instvalid;

    /**
        1. 对指令进行译码
    */
    always @(*) begin
        // 复位时
        if(rst == `RstEnable) begin
            // 指令进行运算的类型
            aluop_o     <=  `EXE_NOP_OP;
            alusel_o    <=  `EXE_RES_NOP;
            // 指令要写入的目的寄存器地址
            wd_o        <=  `NOPRegAddr;
            // 指令是否有要写入的目的寄存器
            wreg_o      <=  `WriteDisable;
            // 指令有效？
            instvalid   <=  `InstValid;
            // Regfile 模块的读寄存器端口的读使能信号
            reg1_read_o <=  1'b0;
            reg2_read_o <=  1'b0;
            // Regfile 模块的读寄存器端口的读地址信号
            reg1_addr_o <=  `NOPRegAddr;
            reg2_addr_o <=  `NOPRegAddr;
            // 指令执行需要的立即数
            imm         <=  32'h0;
        end
        else begin
            // 指令进行运算的类型
            aluop_o     <=  `EXE_NOP_OP;
            alusel_o    <=  `EXE_RES_NOP;
            // 指令要写入的目的寄存器地址
            wd_o        <=  inst_i[15:11];
            // 指令是否有要写入的目的寄存器
            wreg_o      <=  `WriteDisable;
            // 指令有效？
            instvalid   <=  `InstInvalid;
            // Regfile 模块的读寄存器端口的读使能信号
            reg1_read_o <=  1'b0;
            reg2_read_o <=  1'b0;
            // Regfile 模块的读寄存器端口的读地址信号
            // 默认通过Regfile读端口读取的寄存器地址
            reg1_addr_o <=  inst_i[25:21];
            reg2_addr_o <=  inst_i[20:16];
            // 指令执行需要的立即数
            imm         <=  `ZeroWord;

            case (op)
                // 指令码是SPECIAL
                // R类型指令
                `EXE_SPECIAL_INST: begin
                    case (op2)
                        5'b00000: begin
                            case (op3) // 依据功能码判断是哪种指令
                                // and R型指令
                                `EXE_AND: begin
                                    wreg_o      <= `WriteEnable;
                                    aluop_o     <= `EXE_AND_OP;
                                    alusel_o    <= `EXE_RES_LOGIC;
                                    reg1_read_o <= 1'b1;
                                    reg2_read_o <= 1'b1;
                                    instvalid   <= `InstValid;
                                end
                                // OR R型指令
                                `EXE_OR: begin
                                    wreg_o      <= `WriteEnable;
                                    aluop_o     <= `EXE_OR_OP;
                                    alusel_o    <= `EXE_RES_LOGIC;
                                    reg1_read_o <= 1'b1;
                                    reg2_read_o <= 1'b1;
                                    instvalid   <= `InstValid;
                                end
                                // XOR R型指令
                                `EXE_XOR: begin
                                    wreg_o      <= `WriteEnable;
                                    aluop_o     <= `EXE_XOR_OP;
                                    alusel_o    <= `EXE_RES_LOGIC;
                                    reg1_read_o <= 1'b1;
                                    reg2_read_o <= 1'b1;
                                    instvalid   <= `InstValid;
                                end
                                // NOR R型指令
                                `EXE_NOR: begin
                                    wreg_o      <= `WriteEnable;
                                    aluop_o     <= `EXE_NOR_OP;
                                    alusel_o    <= `EXE_RES_LOGIC;
                                    reg1_read_o <= 1'b1;
                                    reg2_read_o <= 1'b1;
                                    instvalid   <= `InstValid;
                                end
                                // R型指令
                                // 逻辑左移
                                // $rd <= $rt << $rs[4:0]
                                `EXE_SLLV: begin
                                    wreg_o      <= `WriteEnable;
                                    aluop_o     <= `EXE_SLL_OP;
                                    alusel_o    <= `EXE_RES_SHIFT;
                                    reg1_read_o <= 1'b1;
                                    reg2_read_o <= 1'b1;
                                    instvalid   <= `InstValid;
                                end
                                // R型指令
                                // 逻辑右移
                                // $rd <= $rt >> $rs[4:0]
                                `EXE_SRLV: begin
                                    wreg_o      <= `WriteEnable;
                                    aluop_o     <= `EXE_SRL_OP;
                                    alusel_o    <= `EXE_RES_SHIFT;
                                    reg1_read_o <= 1'b1;
                                    reg2_read_o <= 1'b1;
                                    instvalid   <= `InstValid;
                                end
                                // R型指令
                                // 算数右移
                                `EXE_SRAV: begin
                                    wreg_o      <= `WriteEnable;
                                    aluop_o     <= `EXE_SRA_OP;
                                    alusel_o    <= `EXE_RES_SHIFT;
                                    reg1_read_o <= 1'b1;
                                    reg2_read_o <= 1'b1;
                                    instvalid   <= `InstValid;
                                end
                                // sync指令 用于保证加载 存储操作的顺序
                                // 由于目前processer严格按照指令顺序进行，因此sync指令被当作nop指令执行
                                `EXE_SYNC: begin
                                    wreg_o      <= `WriteEnable;
                                    aluop_o     <= `EXE_OR_OP;
                                    alusel_o    <= `EXE_RES_NOP;
                                    reg1_read_o <= 1'b0;
                                    reg2_read_o <= 1'b0;
                                    instvalid   <= `InstValid;
                                end
                                // MOVN指令 当rt不为0时 将rs的值移入rd中
                                `EXE_MOVN: begin
                                    // 运算子类型
                                    aluop_o     <= `EXE_MOVN_OP;
                                    // 运算类型
                                    alusel_o    <= `EXE_RES_MOVE;
                                    // 读取寄存器1
                                    reg1_read_o <= 1'b1;
                                    // 读取寄存器2
                                    reg2_read_o <= 1'b1;
                                    instvalid   <= `InstValid;
                                    // 是否有要写入的目的寄存器
                                    if (reg2_o != `ZeroWord) begin
                                        wreg_o <= `WriteEnable;
                                    end
                                    else begin
                                        wreg_o <= `WriteDisable;
                                    end                                    
                                end

                                default: begin
                                end                                                                                                   
                            endcase // op3
                        end // 5'b00000
                        default: begin
                        end    
                    endcase // op2
                end // EXE_SPECIAL_INST

                // I型指令 ORI
                `EXE_ORI: begin // 根据op的值判断是否是ori指令
                    // ori指令需要将结果写入目的寄存器，所以wreg_o为WriteEnable
                    wreg_o   <= `WriteEnable;
                    
                    // 运算的子类型是逻辑“或”运算
                    aluop_o  <= `EXE_OR_OP;

                    // 运算类型是逻辑运算
                    alusel_o <= `EXE_RES_LOGIC;

                    // 需要通过regfile 的读端口1 读取寄存器
                    reg1_read_o <=  1'b1;

                    // 不需要通过regfile 的读端口2 读取寄存器
                    reg2_read_o <=  1'b0;

                    // 指令执行需要的立即数 将16位操作数扩展到32位
                    // 立即数扩展
                    imm         <=  {16'h0, inst_i[15:0]};

                    // 指令执行要写的目的寄存器地址
                    wd_o        <=  inst_i[20:16];

                    // ori 指令是有效指令
                    instvalid   <= `InstValid;
                end // EXE_ORI
                
                // I型指令 ANDI
                `EXE_ANDI: begin
                    wreg_o      <= `WriteEnable;
                    aluop_o     <= `EXE_AND_OP;
                    alusel_o    <= `EXE_RES_LOGIC;
                    reg1_read_o <= 1'b1;
                    reg2_read_o <= 1'b0;
                    imm         <= {16'h0, inst_i[15:0]};
                    wd_o        <= inst_i[20:16];
                    instvalid   <= `InstValid;
                end // EXE_ANDI

                // I型指令 XORI
                `EXE_XORI: begin
                    wreg_o      <= `WriteEnable;
                    aluop_o     <= `EXE_XOR_OP;
                    alusel_o    <= `EXE_RES_LOGIC;
                    reg1_read_o <= 1'b1;
                    reg2_read_o <= 1'b0;
                    imm         <= {16'h0, inst_i[15:0]};
                    wd_o        <= inst_i[20:16];
                    instvalid   <= `InstValid;
                end // EXE_XORI

                // 将16位立即数加载到寄存器的高16位
                `EXE_LUI: begin
                    wreg_o      <= `WriteEnable;
                    aluop_o     <= `EXE_OR_OP;
                    alusel_o    <= `EXE_RES_LOGIC;
                    reg1_read_o <= 1'b1;
                    reg2_read_o <= 1'b0;
                    imm         <= {inst_i[15:0], 16'h0};
                    wd_o        <= inst_i[20:16];
                    instvalid   <= `InstValid;
                end // EXE_LUI

                // 缓存预取
                // 因为当前processor未实现缓存，因此当成空指令
                `EXE_PREF: begin
                    wreg_o      <= `WriteEnable;
                    aluop_o     <= `EXE_NOP_OP;
                    alusel_o    <= `EXE_RES_NOP;
                    reg1_read_o <= 1'b0;
                    reg2_read_o <= 1'b0;
                    instvalid   <= `InstValid;
                end // EXE_PREF

                default: begin
                end

            endcase // op

            if (inst_i[31:21] == 11'b00000000000) begin
                // $rd <= $rt << sa
                if (op3 == `EXE_SLL) begin
                    wreg_o      <= `WriteEnable;
                    aluop_o     <= `EXE_SLL_OP;
                    alusel_o    <= `EXE_RES_SHIFT;
                    reg1_read_o <= 1'b0;
                    reg2_read_o <= 1'b1;
                    imm[4:0]    <= inst_i[10:6];
                    wd_o        <= inst_i[15:11];
                    instvalid   <= `InstValid;
                end

                // $rd <= $rt >> sa
                else if (op3 == `EXE_SRL) begin
                    wreg_o      <= `WriteEnable;
                    aluop_o     <= `EXE_SRL_OP;
                    alusel_o    <= `EXE_RES_SHIFT;
                    reg1_read_o <= 1'b0;
                    reg2_read_o <= 1'b1;
                    imm[4:0]    <= inst_i[10:6];
                    wd_o        <= inst_i[15:11];
                    instvalid   <= `InstValid;
                end

                // 算数右移sa位
                else if (op3 == `EXE_SRA) begin
                    wreg_o      <= `WriteEnable;
                    aluop_o     <= `EXE_SRA_OP;
                    alusel_o    <= `EXE_RES_SHIFT;
                    reg1_read_o <= 1'b0;
                    reg2_read_o <= 1'b1;
                    imm[4:0]    <= inst_i[10:6];
                    wd_o        <= inst_i[15:11];
                    instvalid   <= `InstValid;
                end
            end
            
        end // else 
    end // end of always

    /**
        2. 确定进行运算的源操作数1
    */
    always @(*) begin
        if (rst == `RstEnable) begin
            reg1_o <= `ZeroWord;    
        end
        // 当前需要读reg1 
        // ex阶段又要写入的目的寄存器 
        // ex阶段要写入的目的寄存器和id阶段要读的reg1的地址相同
        else if (reg1_read_o == 1'b1 && ex_wreg_i == 1'b1 && ex_wd_i == reg1_addr_o) begin
            reg1_o <= ex_wdata_i;     // Regfile读端口1的输出值 直接等于 当前ex阶段的输出值
        end
        // 当前需要读reg1 
        // mem阶段又要写入的目的寄存器 
        // mem阶段要写入的目的寄存器和id阶段要读的reg1的地址相同
        else if (reg1_read_o == 1'b1 && mem_wreg_i == 1'b1 && mem_wd_i == reg1_addr_o) begin
            reg1_o <= mem_wdata_i;    // Regfile读端口1的输出值 直接等于 当前mem阶段的输出值      
        end
        // 当前需要读reg1
        else if (reg1_read_o == 1'b1) begin
            reg1_o <= reg1_data_i;
        end
        // 不需要读reg1
        else if (reg1_read_o == 1'b0) begin
            reg1_o <= imm;
        end
        else begin
            reg1_o <= `ZeroWord;
        end
    end

    /**
        3. 确定进行运算的源操作数2
    */
    always @(*) begin
        if (rst == `RstEnable) begin
            reg2_o <= `ZeroWord;    
        end
       // 当前需要读reg2
        // ex阶段又要写入的目的寄存器 
        // ex阶段要写入的目的寄存器和id阶段要读的reg2的地址相同
        else if (reg2_read_o == 1'b1 && ex_wreg_i == 1'b1 && ex_wd_i == reg2_addr_o) begin
            reg2_o <= ex_wdata_i;     // Regfile读端口1的输出值 直接等于 当前ex阶段的输出值
        end
        // 当前需要读reg2 
        // mem阶段又要写入的目的寄存器 
        // mem阶段要写入的目的寄存器和id阶段要读的reg2的地址相同
        else if (reg2_read_o == 1'b1 && mem_wreg_i == 1'b1 && mem_wd_i == reg2_addr_o) begin
            reg2_o <= mem_wdata_i;    // Regfile读端口1的输出值 直接等于 当前mem阶段的输出值          // 立即数
        end
        // 当前需要读reg2
        else if (reg2_read_o == 1'b1) begin
            reg2_o <= reg2_data_i;
        end
        // 不需要读reg2
        else if (reg2_read_o == 1'b0) begin
            reg2_o <= imm;
        end
        else begin
            reg2_o <= `ZeroWord;
        end
    end


endmodule