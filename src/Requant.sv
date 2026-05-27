`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.04.2026 13:37:03
// Design Name: 
// Module Name: Requant
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

module Requant (
    input  logic        clk,
    input  logic        reset,
    input  logic        valid_in,               
    input  logic signed [31:0] acc_in,          
    input  logic        [4:0]  scale_shift,
    output logic signed [7:0]  data_out,        
    output logic               valid_out       
);

    logic signed [31:0] shifted;
    assign shifted = acc_in >>> scale_shift;

    logic signed [7:0] saturated;

    always_comb begin
        if (shifted > 32'sd127)
            saturated = 8'sd127;
        else if (shifted < -32'sd128)
            saturated = -8'sd128;
        else
            saturated = shifted[7:0];
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            data_out  <= 8'sd0;
            valid_out <= 1'b0;
        end else if (valid_in) begin
            data_out  <= saturated;
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

endmodule
