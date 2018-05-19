`timescale 1ns / 1ps

module test_Matrix_Inversor_2x2(
    );
    localparam WIDTH = 16;
    localparam ints = 16;
    logic clk, startInv;
    logic [WIDTH-1:0] Fdnk [0:1][0:1];
    logic [WIDTH-1:0] c [0:1][0:1];
    logic endInv;
    
     Matrix_Inversor_2x2#(
            WIDTH,
            ints //number of outputs
        ) MI(
        //Inputs
        .clk(clk),
        .startInv(startInv),
        .A(Fdnk),
        .Res(c),
        .endInv(endInv)
        );
    always #2  clk = ~clk;
    
    initial begin
        clk=0;
        startInv = 0;
        Fdnk[0][0] = 16'd8; Fdnk[0][1] = 16'd23;
        Fdnk[1][0] = 16'd2; Fdnk[1][1] = 16'd6;
        
        #3 startInv = 1;
        #20 startInv = 0;
    end
endmodule
