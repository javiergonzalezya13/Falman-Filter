`timescale 1ns / 1ps
//Modulo para pasar de Verilog a System Verilog
module VtoSV(
    input clk, //Reloj 
    input clk_en, //Reloj de MATLAB
    input reset, //Reset
    input [15:0] U0, //Entrada 1
    input [15:0] U1, //Entrada 2
    input [15:0] Y0, //Salida 1
    input [15:0] Y1, //Salida 2
    output [15:0] State0, //Estado 1
    output [15:0] State1, //Estado 2
    output [15:0] State2, //Estado 3
    output [15:0] State3 //Estado 4
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
