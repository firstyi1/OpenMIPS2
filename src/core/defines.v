/**
    宏定义文件
*/

// 全局宏定义
`define RstEnable       1'b1                // 复位信号有效
`define RstDisable      1'b0                // 复位信号无效

`define ZeroWord        32'h00000000        // 32位的数値0
`define WriteEnable     1'b1                // 写使能
`define WriteDisable    1'b0                // 禁止写
`define ReadEnable      1'b1                // 读使能
`define ReadDisable     1'b0                // 禁止读
`define AluOpBus        7:0                 // 译码阶段的输出 aluop_o 的宽度 
`define AluSelBus       2:0                 // 译码阶段的输出 alusel_o 的宽度 
`define InstValid       1'b0                // 指令有效
`define InstInvalid     1'b1                // 指令无效
`define True_v          1'b1                // 逻辑真
`define False_v         1'b0                // 逻辑假    
`define ChipEnable      1'b1                // 芯片使能 
`define ChipDisable     1'b0                // 芯片禁止

// 与具体指令相关 指令的功能码
`define EXE_NOP         6'b000000  
`define EXE_ORI         6'b001101           // ori指令的功能码 
`define EXE_AND         6'b100100           // and指令的功能码
`define EXE_OR          6'b100101           // or指令的功能码
`define EXE_XOR         6'b100110           // xor指令的功能码
`define EXE_NOR         6'b100111           // nor指令的功能码
`define EXE_ANDI        6'b001100           // andi指令的功能码
`define EXE_XORI        6'b001110           // xori指令的功能码
`define EXE_LUI         6'b001111           // lui指令的功能码

`define EXE_SLL         6'b000000           // sll指令的功能码
`define EXE_SLLV        6'b000100           // sllv指令的功能码
`define EXE_SRL         6'b000010           // srl指令的功能码
`define EXE_SRLV        6'b000110           // srlv指令的功能码
`define EXE_SRA         6'b000011           // sra指令的功能码
`define EXE_SRAV        6'b000111           // srav指令的功能码

`define EXE_SYNC        6'b001111           // sync指令的功能码
`define EXE_PREF        6'b110011           // pref指令的功能码

`define EXE_MOVZ        6'b001010           // movz指令的功能码
`define EXE_MOVN        6'b001011           // movn指令的功能码
`define EXE_MTHI        6'b010001           
`define EXE_MTLO        6'b010011           
`define EXE_MFHI        6'b010000           
`define EXE_MFLO        6'b010010           

`define EXE_SPECIAL_INST    6'b000000       // sync指令码


//AluOp
`define EXE_NOP_OP      8'b00000000

`define EXE_OR_OP       8'b00100101         // 运算的子类型是 或 运算
`define EXE_AND_OP      8'b00100100
`define EXE_NOR_OP      8'b00100011
`define EXE_XOR_OP      8'b00100010

`define EXE_SLL_OP      8'b00101101
`define EXE_SRL_OP      8'b00101011
`define EXE_SRA_OP      8'b00100010

`define EXE_MTHI_OP     8'b01000010
`define EXE_MTLO_OP     8'b01000011
`define EXE_MOVZ_OP     8'b01000100
`define EXE_MOVN_OP     8'b01000101



//AluSel
`define EXE_RES_NOP     3'b000
`define EXE_RES_LOGIC   3'b001              // 运算类型是逻辑运算
`define EXE_RES_SHIFT   3'b010              // 运算类型是移位运算
`define EXE_RES_MOVE    3'b011


// 指令寄存器 ROM相关
`define InstAddrBus     31:0                // ROM地址总线宽度
`define InstBus         31:0                // ROM数据总线宽度

`define InstMemNum      131071              // ROM实际大小128KB     128*1024
`define InstMemNumLog2  17                  // ROM实际使用的地址线宽度  2^17 = 128*1024


// 通用寄存器相关
`define RegAddrBus      4:0                 // Regfile模块的地址线宽度
`define RegBus          31:0                // Regfile模块的数据线宽度
`define Regwidth        32                  // 通用寄存器的宽度
`define DoubleRegWidth  64                  // 两倍的通用寄存器的宽度
`define DoubleRegBus    63:0                // 两倍的通用寄存器的数据线宽度
`define RegNum          32                  // 通用寄存器数量
`define ReqNumLog2      5                   //  寻址通用寄存器使用的地址位数
`define NOPRegAddr      5'b00000
