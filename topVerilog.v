`timescale 1ns / 1ps
//Modulo wrapper en Verilog
module topVerilog(
    input clk, //Reloj
    input clk_en, //Reloj de MATLAB
    input reset, //RESET
    input [15:0] U0, //Entrada 1
    input [15:0] U1, //Entrada 2
    input [15:0] Y0, //Salida 1
    input [15:0] Y1, //Salida 2
    output [15:0] State0, //Estado 1
    output [15:0] State1,//Estado 2
    output [15:0] State2,//Estado 3
    output [15:0] State3//Estado 4
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
