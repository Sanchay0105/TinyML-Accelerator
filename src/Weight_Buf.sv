`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.04.2026 20:13:48
// Design Name: 
// Module Name: Weight_Buf
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

module Weight_Buf #(
    parameter int MAX_CH             = 8,
    parameter string STD_KERNEL_FILE = "weights.mem",
    parameter string STD_BIAS_FILE   = "bias.mem",
    parameter string DW_KERNEL_FILE  = "dw_weights.mem",
    parameter string DW_BIAS_FILE    = "dw_bias.mem"
)(
    input  logic        clk,
    input  logic        reset,
    input  logic        load_en,

    output logic signed [7:0]  std_kernel [0:8],
    output logic signed [31:0] std_bias,
    output logic signed [7:0]  dw_kernels [0:MAX_CH-1][0:8],
    output logic signed [31:0] dw_biases  [0:MAX_CH-1],
    output logic               load_done
);

    logic [7:0]  std_kernel_mem [0:8];
    logic [7:0]  dw_kernel_mem  [0:MAX_CH*9-1];

    logic [31:0] std_bias_word  [0:0];
    logic [31:0] dw_bias_words  [0:MAX_CH-1];

    initial begin
        $readmemh(STD_KERNEL_FILE, std_kernel_mem);
        $readmemh(STD_BIAS_FILE,   std_bias_word);
        $readmemh(DW_KERNEL_FILE,  dw_kernel_mem);
        $readmemh(DW_BIAS_FILE,    dw_bias_words);
    end

    integer i, c;

    always_ff @(posedge clk) begin
        if (reset) begin
            load_done <= 1'b0;
            for (i = 0; i < 9; i++)
                std_kernel[i] <= 8'sd0;
            std_bias <= 32'sd0;
            for (c = 0; c < MAX_CH; c++) begin
                for (i = 0; i < 9; i++)
                    dw_kernels[c][i] <= 8'sd0;
                dw_biases[c] <= 32'sd0;
            end

        end else if (load_en) begin
            for (i = 0; i < 9; i++)
                std_kernel[i] <= signed'(std_kernel_mem[i]);

            std_bias <= signed'(std_bias_word[0]);

            // unpack dw kernel bytes
            for (c = 0; c < MAX_CH; c++)
                for (i = 0; i < 9; i++)
                    dw_kernels[c][i] <= signed'(dw_kernel_mem[c*9 + i]);

            for (c = 0; c < MAX_CH; c++)
                dw_biases[c] <= signed'(dw_bias_words[c]);

            load_done <= 1'b1;

        end else begin
            load_done <= 1'b0;
        end
    end

endmodule
