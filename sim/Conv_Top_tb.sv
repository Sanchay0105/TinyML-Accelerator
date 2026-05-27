`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.04.2026 20:30:38
// Design Name: 
// Module Name: Conv_Top_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module Conv_Top_tb;

    localparam int OH = 6;
    localparam int OW = 6;

    logic        clk;
    logic        reset;
    logic        start;
    logic [5:0]  rd_addr;
    logic signed [7:0]  rd_data;
    logic               done;
    logic signed [7:0]  ref_mem [0:OH*OW-1];

    Conv_Top #(
        .H(8), .W(8), .KH(3), .KW(3),
        .OH(6), .OW(6), .MAX_CH(8), .SCALE_SHIFT(4)
    ) dut (
        .clk    (clk),
        .reset  (reset),
        .start  (start),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .done   (done),
        .ref_mem(ref_mem)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    int pass_count, fail_count;
    int row, col, addr;

    initial begin
        pass_count = 0;
        fail_count = 0;

        reset   = 1;
        start   = 0;
        rd_addr = 6'd0;
        repeat(3) @(posedge clk);
        reset = 0;
        @(posedge clk);

        start = 1;
        @(posedge clk);
        start = 0;

        fork
            begin
                wait(done);
                $display("INFO | done asserted after computation");
            end
            begin
                repeat(500) @(posedge clk);
                $display("TIMEOUT | done never asserted - FSM stuck");
                $finish;
            end
        join_any

        @(posedge clk); #1;
     
        $display("Output vs Golden Reference comparison:");
 

        for (row = 0; row < OH; row++) begin
            for (col = 0; col < OW; col++) begin
                addr    = row * OW + col;
                rd_addr = 6'(addr);
                #1; 

                if (rd_data === ref_mem[addr]) begin
                    $display("PASS [%0d][%0d] addr=%0d | got=%0d ref=%0d",
                             row, col, addr, rd_data, ref_mem[addr]);
                    pass_count++;
                end else begin
                    $display("FAIL [%0d][%0d] addr=%0d | got=%0d ref=%0d",
                             row, col, addr, rd_data, ref_mem[addr]);
                    fail_count++;
                end
            end
        end

        $display("Results: %0d PASS  %0d FAIL  out of %0d",
                 pass_count, fail_count, OH*OW);

        if (fail_count == 0)
            $display("ALL PIXELS MATCH GOLDEN REFERENCE ");
        else
            $display("MISMATCHES FOUND - check waveform mac_array_top_tb.vcd");

        $finish;
    end

    initial begin
        $dumpfile("Conv_Top_tb.vcd");
        $dumpvars(0, Conv_Top_tb);
    end

endmodule
