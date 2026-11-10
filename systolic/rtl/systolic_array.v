// ============================================================================
// File: systolic_array.v
// Module: systolic_array
// Project: Do an Kien truc May tinh (MI4344) - Nhom 15
// Tac gia: Nguyen Dinh Huy (P4 - Truong nhom)
// Mo ta: Mang Systolic 2D kich thuoc 8x8 gom 64 Processing Elements (PEs).
//        Kien truc Weight-Stationary (WS):
//        - Trong so B nap truoc vao cac PE va giu co dinh.
//        - Activation A truyen tu trai sang phai (ngang).
//        - Partial sum psum truyen tu tren xuong duoi (doc).
//        - Hang 0 nhan psum_in = 0.
//        - Hang 7 xuat ket qua cuoi cung C ra c_out.
// ============================================================================

`timescale 1ns / 1ps

module systolic_array #(
    parameter DATA_WIDTH = 16,
    parameter ACC_WIDTH  = 32,
    parameter ARRAY_SIZE = 8
)(
    input  wire                                               clk,
    input  wire                                               rst_n,
    input  wire                                               load_w,
    input  wire [ARRAY_SIZE*ARRAY_SIZE*DATA_WIDTH-1:0]        w_in,
    input  wire [ARRAY_SIZE*DATA_WIDTH-1:0]                   a_in,
    output wire [ARRAY_SIZE*ACC_WIDTH-1:0]                    c_out
);

    // Day noi mang ngang cho Activation (A):
    // Hang r: a_wire[r][0] la dau vao mang, a_wire[r][c] la day giua cot c-1 va cot c
    wire signed [DATA_WIDTH-1:0] a_wire [0:ARRAY_SIZE-1][0:ARRAY_SIZE];

    // Day noi mang doc cho Partial Sum (psum):
    // Cot c: psum_wire[0][c] la 0 (dau vao dinh mang),
    // psum_wire[r][c] la day giua hang r-1 va hang r
    wire signed [ACC_WIDTH-1:0] psum_wire [0:ARRAY_SIZE][0:ARRAY_SIZE-1];

    genvar r, c;
    generate
        // Ket noi dau vao bien trai (Activation a_in)
        for (r = 0; r < ARRAY_SIZE; r = r + 1) begin : gen_a_in
            assign a_wire[r][0] = a_in[r*DATA_WIDTH +: DATA_WIDTH];
        end

        // Ket noi dau vao bien tren (Partial Sum = 0)
        for (c = 0; c < ARRAY_SIZE; c = c + 1) begin : gen_psum_top
            assign psum_wire[0][c] = {ACC_WIDTH{1'b0}};
        end

        // Luoi 2D 8x8 PEs
        for (r = 0; r < ARRAY_SIZE; r = r + 1) begin : gen_row
            for (c = 0; c < ARRAY_SIZE; c = c + 1) begin : gen_col
                // Tinh chi so trong so tuong ung cho PE(r, c)
                wire signed [DATA_WIDTH-1:0] pe_w = w_in[(r*ARRAY_SIZE + c)*DATA_WIDTH +: DATA_WIDTH];

                pe #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .ACC_WIDTH(ACC_WIDTH)
                ) u_pe (
                    .clk     (clk),
                    .rst_n   (rst_n),
                    .load_w  (load_w),
                    .w_in    (pe_w),
                    .a_in    (a_wire[r][c]),
                    .psum_in (psum_wire[r][c]),
                    .a_out   (a_wire[r][c+1]),
                    .psum_out(psum_wire[r+1][c])
                );
            end
        end

        // Ket noi dau ra day mang (Hang cuoi r = ARRAY_SIZE)
        for (c = 0; c < ARRAY_SIZE; c = c + 1) begin : gen_c_out
            assign c_out[c*ACC_WIDTH +: ACC_WIDTH] = psum_wire[ARRAY_SIZE][c];
        end
    endgenerate

endmodule
