`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.04.2026 13:47:47
// Design Name: 
// Module Name: Channel_Mux
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

module Channel_Mux #(
    parameter int MAX_CH = 8    
)(

    input  logic        dw_mode,              
    input  logic [2:0]  channel_sel,          

    input  logic signed [7:0]  std_kernel [0:8],     
    input  logic signed [31:0] std_bias,             

    input  logic signed [7:0]  dw_kernels [0:MAX_CH-1][0:8],
    input  logic signed [31:0] dw_biases  [0:MAX_CH-1],

    output logic signed [7:0]  active_kernel [0:8], 
    output logic signed [31:0] active_bias           
);

    always_comb begin
        if (dw_mode) begin
            active_kernel = dw_kernels[channel_sel];
            active_bias   = dw_biases[channel_sel];
        end else begin
            active_kernel = std_kernel;
            active_bias   = std_bias;
        end
    end

endmodule
