`timescale 1ns / 1ps
module test_covariance_etc();

    localparam WIDTH = 16;
    localparam nos = 4;
    localparam noo = 2;
    logic clk, reset, Start_K_G;
    logic [WIDTH-1:0] Fdnk [0:nos-1][0:nos-1]; // 4x4
    logic [WIDTH-1:0] H [0:noo-1][0:nos-1]; // 2x4
    logic [WIDTH-1:0] Q [0:nos-1][0:nos-1]; //
    logic [WIDTH-1:0] R [0:noo-1][0:noo-1]; //
    logic [WIDTH-1:0] P [0:nos-1][0:nos-1];
    logic [WIDTH-1:0] g [0:nos-1][0:nos-1]; // 4x4 P(nk/nk-1)
    logic [WIDTH-1:0] c [0:nos-1][0:nos-1]; // 4x4 P(nk-1/nk-1)
    logic [WIDTH-1:0] t2 [0:nos-1][0:noo-1]; // 4x2 K(nk)
    logic end_K_G;
    
    covariance_matrix_generator #(
            WIDTH,
            nos,//number of states
            noo //number of outputs
        ) cov(
        //Inputs
        .clk(clk),
        .reset(reset),
        .Start_K_G(Start_K_G),
        .Fdnk(Fdnk), // 4x4
        .H(H), // 2x4
        .Q(Q), //
        .R(R), //
        .P0(P),
        //Outputs
        .g(g), // 4x4 P(nk/nk-1)
        .c(c),// 4x4 P(nk-1/nk-1)
        .t2(t2), // 4x2 K(nk)
        .end_K_G(end_K_G)
        );
    always #2  clk = ~clk;
    
    initial begin
        clk=0;
        reset=1;
        Start_K_G = 0;
        Fdnk[0][0] = 16'd7; Fdnk[0][1] = 16'd3; Fdnk[0][2] = 16'd9; Fdnk[0][3] = 16'd6;
        Fdnk[1][0] = 16'd1; Fdnk[1][1] = 16'd6; Fdnk[1][2] = 16'd5; Fdnk[1][3] = 16'd2;
        Fdnk[2][0] = 16'd2; Fdnk[2][1] = 16'd4; Fdnk[2][2] = 16'd3; Fdnk[2][3] = 16'd3;
        Fdnk[3][0] = 16'd3; Fdnk[3][1] = 16'd5; Fdnk[3][2] = 16'd5; Fdnk[3][3] = 16'd7;
        
        H[0][0] = 16'd6; H[0][1] = 16'd5; H[0][2] = 16'd2; H[0][3] = 16'd1;
        H[1][0] = 16'd7; H[1][1] = 16'd6; H[1][2] = 16'd8; H[1][3] = 16'd3;
 
        Q[0][0] = 16'd3; Q[0][1] = 16'd8; Q[0][2] = 16'd3; Q[0][3] = 16'd3;
        Q[1][0] = 16'd5; Q[1][1] = 16'd5; Q[1][2] = 16'd7; Q[1][3] = 16'd5;
        Q[2][0] = 16'd7; Q[2][1] = 16'd1; Q[2][2] = 16'd3; Q[2][3] = 16'd7;
        Q[3][0] = 16'd5; Q[3][1] = 16'd3; Q[3][2] = 16'd8; Q[3][3] = 16'd3;
        
        R[0][0] = 16'd7; R[0][1] = 16'd7;
        R[1][0] = 16'd1; R[1][1] = 16'd3;
        
        P[0][0] = 16'd7; P[0][1] = 16'd3; P[0][2] = 16'd4; P[0][3] = 16'd8;
        P[1][0] = 16'd4; P[1][1] = 16'd5; P[1][2] = 16'd1; P[1][3] = 16'd7;
        P[2][0] = 16'd8; P[2][1] = 16'd8; P[2][2] = 16'd7; P[2][3] = 16'd2;
        P[3][0] = 16'd5; P[3][1] = 16'd9; P[3][2] = 16'd8; P[3][3] = 16'd9;
        #3 reset = 0; Start_K_G = 1;
        #20 Start_K_G = 0;
    end
endmodule
