`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.04.2026 13:41:22
// Design Name: 
// Module Name: ReLU
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

module Relu (
    input  logic        clk,
    input  logic        reset,
    input  logic        valid_in,             
    input  logic signed [7:0] data_in,        
    input  logic        relu6_mode,           
    output logic signed [7:0] data_out,      
    output logic valid_out      
);

    logic signed [7:0] activated;

    always_comb begin
        if (data_in < 8'sd0)
            activated = 8'sd0;          
        else if (relu6_mode && data_in > 8'sd6)
            activated = 8'sd6;        
        else
            activated = data_in;         
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            data_out  <= 8'sd0;
            valid_out <= 1'b0;
        end else if (valid_in) begin
            data_out  <= activated;
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

endmodule
