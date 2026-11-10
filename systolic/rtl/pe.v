// ============================================================================
// File: pe.v
// Module: pe (Processing Element)
// Project: Do an Kien truc May tinh (MI4344) - Nhom 15
// Tac gia: Nguyen Dinh Huy (P4 - Truong nhom)
// Mo ta: Mot don vi tinh toan co ban trong mang Systolic Array theo kien truc
//        Weight-Stationary (WS).
//        - Kieu du lieu dau vao: signed int16 (w_in, a_in)
//        - Kieu du lieu bo tich luy: signed int32 (psum_in, psum_out)
//        - Tich hop thanh ghi luu trong so, thanh ghi truyen dong a va psum.
// ============================================================================

`timescale 1ns / 1ps

module pe #(
    parameter DATA_WIDTH = 16,
    parameter ACC_WIDTH  = 32
)(
    input  wire                          clk,
    input  wire                          rst_n,
    input  wire                          load_w,
    input  wire signed [DATA_WIDTH-1:0]  w_in,
    input  wire signed [DATA_WIDTH-1:0]  a_in,
    input  wire signed [ACC_WIDTH-1:0]   psum_in,
    output reg  signed [DATA_WIDTH-1:0]  a_out,
    output reg  signed [ACC_WIDTH-1:0]   psum_out
);

    // Thanh ghi noi bo luu giu trong so B[r][c]
    reg signed [DATA_WIDTH-1:0] weight;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            weight   <= {DATA_WIDTH{1'b0}};
            a_out    <= {DATA_WIDTH{1'b0}};
            psum_out <= {ACC_WIDTH{1'b0}};
        end else begin
            // Nap trong so khi load_w duoc kich hoat
            if (load_w) begin
                weight <= w_in;
            end
            
            // Truyen gia tri activation sang PE ke ben phai
            a_out <= a_in;

            // Thuc hien phep MAC: psum_out = psum_in + (a_in * weight)
            // Dau vao la signed int16, phep nhan cho ket qua signed int32,
            // sau do cong voi psum_in (signed int32) va ghi vao thanh ghi dau ra.
            psum_out <= psum_in + (a_in * weight);
        end
    end

endmodule
