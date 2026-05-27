`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.04.2026 20:16:17
// Design Name: 
// Module Name: Output_Buf
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

module Output_Buf #(
    parameter int OH        = 6,      
    parameter int OW        = 6,      
    parameter string REF_FILE = "output_ref.mem"
)(
    input  logic        clk,
    input  logic        reset,

    input  logic        wr_en,
    input  logic [5:0]  wr_addr,             
    input  logic signed [7:0] wr_data,       

    input  logic [5:0]  rd_addr,
    output logic signed [7:0] rd_data,

    output logic signed [7:0] ref_mem [0:OH*OW-1],

    output logic        done                
);

    logic signed [7:0] buf_mem [0:OH*OW-1];

    initial begin
        $readmemh(REF_FILE, ref_mem);
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            done <= 1'b0;
        end else if (wr_en) begin
            buf_mem[wr_addr] <= wr_data;
            if (wr_addr == OH*OW-1)
                done <= 1'b1;
        end
    end

    assign rd_data = buf_mem[rd_addr];

endmodule
