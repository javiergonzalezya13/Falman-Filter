`timescale 1ns / 1ps

module VtoSV(
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
    wire [15:0] U[0:0];
    wire [15:0] Y [0:0];
    wire [15:0] State [0:1];
    
    assign U[0] = U0;
           
    assign Y[0] = Y0;
    //assign Y[1] = Y1;
        
    assign State0 = State[0];
    assign State1 = State[1];
    assign State2 = 'd0;
    assign State3 = 'd0;
    
    main M(
        .clk(clk),
        .clk_en(clk_en),
        .reset(reset),
        .U(U),
        .Y(Y),
        .State(State)
        );
endmodule
