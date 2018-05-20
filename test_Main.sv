`timescale 1ns / 1ps

module test_Main();
    
    parameter WIDTH = 16; //Largo de digitos
    parameter nos = 4;            //Numero de estados
    parameter noo = 2;            //Numero de salidas
    parameter noi = 2;            //Numero de entradas
    parameter intDigits = 5;
    
    logic clk;
    logic clk_en;
    logic reset;
    logic [WIDTH-1:0] U [0:noi-1];
    logic [WIDTH-1:0] Y [0:noi-1];
    logic [WIDTH-1:0] State [0:nos-1];
    
    main#()M(
        .clk(clk),
        .clk_en(clk_en),
        .reset(reset),
        .U(U),
        .Y(Y),
        .State(State)
        );
    
    always #2  clk = ~clk;
    initial begin
        clk=0;
        clk_en=1;
        reset = 1;
        U[0] = 'd4; U[1] = 'd2; Y[0] = 'd5; Y[1] = 'd2;
        #20 reset = 0; 
    end
endmodule
