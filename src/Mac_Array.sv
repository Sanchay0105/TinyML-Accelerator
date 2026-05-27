`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.04.2026 13:17:10
// Design Name: 
// Module Name: Mac_Array
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

module Mac_Array (
    input  logic        clk,
    input  logic        reset,
    input  logic        enable,
    input  logic signed [7:0]  act [0:8],
    input  logic signed [7:0]  wt  [0:8],
    output logic signed [31:0] acc_out,
    output logic               valid
);

    logic signed [31:0] partial [0:8];

    genvar i;
    generate
        for (i = 0; i < 9; i++) begin : gen_mac
            Mac_Unit u_mac (
                //.clk    (clk),
               // .reset  (reset),
               // .enable (enable),
                .a      (act[i]),
                .b      (wt[i]),
                .acc    (partial[i])
            );
        end
    endgenerate

    logic signed [31:0] lvl1 [0:4];
    logic signed [31:0] lvl2 [0:2];
    logic signed [31:0] lvl3 [0:1];
    logic signed [31:0] lvl4;

    always_comb begin
        lvl1[0] = partial[0] + partial[1];
        lvl1[1] = partial[2] + partial[3];
        lvl1[2] = partial[4] + partial[5];
        lvl1[3] = partial[6] + partial[7];
        lvl1[4] = partial[8];

        lvl2[0] = lvl1[0] + lvl1[1];
        lvl2[1] = lvl1[2] + lvl1[3];
        lvl2[2] = lvl1[4];

        lvl3[0] = lvl2[0] + lvl2[1];
        lvl3[1] = lvl2[2];

        lvl4 = lvl3[0] + lvl3[1];
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            acc_out <= 32'sd0;
            valid   <= 1'b0;
        end else begin
            acc_out <= lvl4;
            valid   <= enable;
        end
    end

endmodule
