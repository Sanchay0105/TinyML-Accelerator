`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.04.2026 20:20:06
// Design Name: 
// Module Name: Conv_Top
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

module Conv_Top #(
    parameter int H           = 8,
    parameter int W           = 8,
    parameter int KH          = 3,
    parameter int KW          = 3,
    parameter int OH          = 6,
    parameter int OW          = 6,
    parameter int MAX_CH      = 8,
    parameter int SCALE_SHIFT = 4
)(
    input  logic        clk,
    input  logic        reset,
    input  logic        start,
    input  logic [5:0]  rd_addr,

    output logic signed [7:0]  rd_data,
    output logic               done,
    output logic signed [7:0]  ref_mem [0:OH*OW-1]
);

    logic        wt_load_en, act_load_en;
    logic        mac_en;
    logic        dw_mode;
    logic [2:0]  channel_sel;
    logic [2:0]  row_idx, col_idx;
    logic        out_wr_en;
    logic [5:0]  out_wr_addr;

    logic signed [7:0]  std_kernel  [0:8];
    logic signed [31:0] std_bias;
    logic signed [7:0]  dw_kernels  [0:MAX_CH-1][0:8];
    logic signed [31:0] dw_biases   [0:MAX_CH-1];
    logic        wt_load_done, act_load_done;

    logic signed [7:0]  active_kernel [0:8];
    logic signed [31:0] active_bias;

    logic signed [7:0]  patch [0:8];

    logic signed [31:0] mac_acc;
    logic               mac_valid;

    logic signed [31:0] bias_acc;
    logic               bias_valid;

    logic signed [7:0]  requant_data;
    logic               requant_valid;

    logic signed [7:0]  relu_data;
    logic               relu_valid;

    // FSM instantiation
    FSM #(.OH(OH), .OW(OW)) u_fsm (
        .clk          (clk),
        .reset        (reset),
        .start        (start),
        .wt_load_done (wt_load_done),
        .act_load_done(act_load_done),
        .relu_valid   (relu_valid),
        .wt_load_en   (wt_load_en),
        .act_load_en  (act_load_en),
        .mac_en       (mac_en),
        .dw_mode      (dw_mode),
        .channel_sel  (channel_sel),
        .row_idx      (row_idx),
        .col_idx      (col_idx),
        .out_wr_en    (out_wr_en),
        .out_wr_addr  (out_wr_addr),
        .done         (done)
    );

    //  Weight buffer 
        Weight_Buf #(.MAX_CH(MAX_CH)) u_wt_buf (
        .clk       (clk),
        .reset     (reset),
        .load_en   (wt_load_en),
        .std_kernel(std_kernel),
        .std_bias  (std_bias),
        .dw_kernels(dw_kernels),
        .dw_biases (dw_biases),
        .load_done (wt_load_done)
    );

    //  Input buffer 
    Input_Buf #(.H(H), .W(W), .KH(KH), .KW(KW)) u_in_buf (
        .clk      (clk),
        .reset    (reset),
        .load_en  (act_load_en),
        .row_idx  (row_idx),
        .col_idx  (col_idx),
        .patch    (patch),
        .load_done(act_load_done)
    );

    //  Channel mux 
        Channel_Mux #(.MAX_CH(MAX_CH)) u_ch_mux (
        .dw_mode      (dw_mode),
        .channel_sel  (channel_sel),
        .std_kernel   (std_kernel),
        .std_bias     (std_bias),
        .dw_kernels   (dw_kernels),
        .dw_biases    (dw_biases),
        .active_kernel(active_kernel),
        .active_bias  (active_bias)
    );

    //  MAC array 
    Mac_Array u_mac_array (
        .clk    (clk),
        .reset  (reset),
        .enable (mac_en),
        .act    (patch),
        .wt     (active_kernel),
        .acc_out(mac_acc),
        .valid  (mac_valid)
    );

    //  Bias add 
    Bias_Add u_bias_add (
        .clk      (clk),
        .reset    (reset),
        .valid_in (mac_valid),
        .acc_in   (mac_acc),
        .bias     (active_bias),
        .acc_out  (bias_acc),
        .valid_out(bias_valid)
    );

    //  Requantize 
    Requant u_requant (
        .clk        (clk),
        .reset      (reset),
        .valid_in   (bias_valid),
        .acc_in     (bias_acc),
        .scale_shift(5'(SCALE_SHIFT)),
        .data_out   (requant_data),
        .valid_out  (requant_valid)
    );

    //  ReLU 
    Relu u_relu (
        .clk       (clk),
        .reset     (reset),
        .valid_in  (requant_valid),
        .data_in   (requant_data),
        .relu6_mode(1'b0),
        .data_out  (relu_data),
        .valid_out (relu_valid)
    );

    // Output buffer 
    Output_Buf #(.OH(OH), .OW(OW)) u_out_buf (
        .clk     (clk),
        .reset   (reset),
        .wr_en   (out_wr_en),
        .wr_addr (out_wr_addr),
        .wr_data (relu_data),
        .rd_addr (rd_addr),
        .rd_data (rd_data),
        .ref_mem (ref_mem),
        .done    ()
    );

endmodule