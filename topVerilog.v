`timescale 1ns / 1ps

module topVerilog(
    input clk,
    input clk_en,
    input reset,
    input [15:0] U0,
    input [15:0] U1,
    input [15:0] Y0,
    input [15:0] Y1,
    output [15:0] State0,
    output [15:0] State1,
    output [15:0] State2,
    output [15:0] State3
    );
    
    VtoSV SV(
        .clk(clk),
        .clk_en(clk_en),
        .reset(reset),
        .U0(U0),
        .U1(U1),
        .Y0(Y0),
        .Y1(Y1),
        .State0(State0),
        .State1(State1),
        .State2(State2),
        .State3(State3)
        );
endmodule
