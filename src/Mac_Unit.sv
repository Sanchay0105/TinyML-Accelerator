`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.04.2026 13:11:10
// Design Name: 
// Module Name: Mac_Unit
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

module Mac_Unit (
    //input  logic        clk,
    //input  logic        reset,      
    //input  logic        enable,     
    input  logic signed [7:0]  a,   
    input  logic signed [7:0]  b,   
    output logic signed [31:0] acc  
);

    //logic signed [15:0] product;

    //assign product = a * b;

    /*always_ff @(posedge clk) begin
        if (reset)
            acc <= 32'sd0;
        else if (enable)
            acc <= acc +{{16{product[15]}}, product};
    end */
    assign acc =32'(a * b);
endmodule
