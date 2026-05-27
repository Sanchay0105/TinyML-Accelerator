`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.04.2026 20:17:46
// Design Name: 
// Module Name: FSM
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

module FSM #(
    parameter int OH = 6,
    parameter int OW = 6
)(
    input  logic       clk,
    input  logic       reset,
    input  logic       start,

    input  logic       wt_load_done,
    input  logic       act_load_done,
    input  logic       relu_valid,      

    output logic       wt_load_en,
    output logic       act_load_en,
    output logic       mac_en,
    output logic       dw_mode,
    output logic [2:0] channel_sel,
    output logic [2:0] row_idx,
    output logic [2:0] col_idx,
    output logic       out_wr_en,
    output logic [5:0] out_wr_addr,
    output logic       done
);

    typedef enum logic [2:0] {
        IDLE      = 3'd0,
        LOAD_W    = 3'd1,
        LOAD_ACT  = 3'd2,
        COMPUTE   = 3'd3,
        WAIT_PIPE = 3'd4,  
        POST      = 3'd5,
        DONE_ST   = 3'd6
    } state_t;

    state_t state, next_state;


    logic [2:0] row_cnt, col_cnt;
    logic [5:0] out_addr;

    always_ff @(posedge clk) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    always_comb begin
        next_state = state;
        case (state)
            IDLE:
                if (start)
                    next_state = LOAD_W;

            LOAD_W:
                if (wt_load_done)
                    next_state = LOAD_ACT;

            LOAD_ACT:
                if (act_load_done)
                    next_state = COMPUTE;

            COMPUTE:

                next_state = WAIT_PIPE;

            WAIT_PIPE:

                if (relu_valid)
                    next_state = POST;

            POST:

                if (out_addr == OH*OW - 1)
                    next_state = DONE_ST;
                else
                    next_state = COMPUTE;

            DONE_ST:
                next_state = IDLE;

            default:
                next_state = IDLE;
        endcase
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            row_cnt  <= 3'd0;
            col_cnt  <= 3'd0;
            out_addr <= 6'd0;
        end else if (state == POST) begin
            if (out_addr < OH*OW - 1) begin
                out_addr <= out_addr + 1;
                if (col_cnt == OW - 1) begin
                    col_cnt <= 3'd0;
                    row_cnt <= row_cnt + 1;
                end else begin
                    col_cnt <= col_cnt + 1;
                end
            end
        end else if (state == DONE_ST) begin
            row_cnt  <= 3'd0;
            col_cnt  <= 3'd0;
            out_addr <= 6'd0;
        end
    end

    always_comb begin
        wt_load_en  = 1'b0;
        act_load_en = 1'b0;
        mac_en      = 1'b0;
        out_wr_en   = 1'b0;
        done        = 1'b0;
        dw_mode     = 1'b0;
        channel_sel = 3'd0;

        case (state)
            LOAD_W:   wt_load_en  = 1'b1;
            LOAD_ACT: act_load_en = 1'b1;
            COMPUTE:  mac_en      = 1'b1;
            POST:     out_wr_en   = 1'b1;
            DONE_ST:  done        = 1'b1;
            default:  ;
        endcase
    end

    assign row_idx     = row_cnt;
    assign col_idx     = col_cnt;
    assign out_wr_addr = out_addr;

endmodule