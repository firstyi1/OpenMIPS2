`timescale 1ns/1ps
`include "../core/openmips_min_sopc.v"
`include "../core/defines.v"

module openmips_min_sopc_tb();

    // 100MHz的clk
    reg CLOCK_100;
    reg rst;

    initial CLOCK_100 = 0;
    always #10 CLOCK_100 = ~CLOCK_100;

    initial begin
        rst = `RstEnable;
        #201;
        rst = `RstDisable;
        #1000;
        $finish;
    end

    openmips_min_sopc openmips_min_sopc0(
        .clk(CLOCK_100),
        .rst(rst)
    );

endmodule