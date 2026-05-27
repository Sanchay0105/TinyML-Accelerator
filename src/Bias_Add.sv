`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.04.2026 13:34:42
// Design Name: 
// Module Name: Bias_Add
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

module Bias_Add (
    input  logic        clk,
    input  logic        reset,
    input  logic        valid_in,          
    input  logic signed [31:0] acc_in,    
    input  logic signed [31:0] bias,      
    output logic signed [31:0] acc_out,   
    output logic               valid_out
);

    always_ff @(posedge clk) begin
        if (reset) begin
            acc_out   <= 32'sd0;
            valid_out <= 1'b0;
        end else if (valid_in) begin
            acc_out   <= acc_in + bias;
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

endmodule
