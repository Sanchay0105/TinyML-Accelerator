`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.04.2026 20:14:55
// Design Name: 
// Module Name: Input_Buf
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

module Input_Buf #(
    parameter int H          = 8,      
    parameter int W          = 8,      
    parameter int KH         = 3,      
    parameter int KW         = 3,      
    parameter string MEM_FILE = "input.mem"
)(
    input  logic        clk,
    input  logic        reset,

    input  logic        load_en,       
    input  logic [2:0]  row_idx,       
    input  logic [2:0]  col_idx,      

    output logic signed [7:0] patch [0:8],   
    output logic              load_done      
);

    logic signed [7:0] mem [0:H*W-1];

    initial begin
        $readmemh(MEM_FILE, mem);
    end

    always_ff @(posedge clk) begin
        if (reset)
            load_done <= 1'b0;
        else if (load_en)
            load_done <= 1'b1;
        else
            load_done <= 1'b0;
    end

    genvar r, c;
    generate
        for (r = 0; r < KH; r++) begin : gen_row
            for (c = 0; c < KW; c++) begin : gen_col
                assign patch[r*KW + c] =
                    mem[(row_idx + r) * W + (col_idx + c)];
            end
        end
    endgenerate

endmodule
