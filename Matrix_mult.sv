`timescale 1ns / 1ps
module Mat_mult(A,B,Res);

    //input and output ports.
    //The size 32 bits which is 2*2=4 elements,each of which is 8 bits wide.    
    input [255:0] A;
    input [255:0] B;
    output [255:0] Res;
    //internal variables    
    reg [255:0] Res;
    reg [15:0] A1 [0:3][0:3];
    reg [15:0] B1 [0:3][0:3];
    reg [15:0] Res1 [0:3][0:3]; 
    integer i,j,k;

    always@ (A or B)
    begin
    //Initialize the matrices-convert 1 D to 3D arrays
        {A1[0][0],A1[0][1],A1[0][2],A1[0][3]} = A[255-:64];
        {A1[1][0],A1[1][1],A1[1][2],A1[1][3]} = A[191-:64];
        {A1[2][0],A1[2][1],A1[2][2],A1[2][3]} = A[127-:64];
        {A1[3][0],A1[3][1],A1[3][2],A1[3][3]} = A[63-:64];

        {B1[0][0],B1[0][1],B1[0][2],B1[0][3]} = B[255-:64];
        {B1[1][0],B1[1][1],B1[1][2],B1[1][3]} = B[191-:64];
        {B1[2][0],B1[2][1],B1[2][2],B1[2][3]} = B[127-:64];
        {B1[3][0],B1[3][1],B1[3][2],B1[3][3]} = B[63-:64];
        
        i = 0;
        j = 0;
        k = 0;
        {Res1[0][0],Res1[0][1],Res1[0][2],Res1[0][3]} = 64'd0; //initialize to zeros.
        {Res1[1][0],Res1[1][1],Res1[1][2],Res1[1][3]} = 64'd0;
        {Res1[2][0],Res1[2][1],Res1[2][2],Res1[2][3]} = 64'd0;
        {Res1[3][0],Res1[3][1],Res1[3][2],Res1[3][3]} = 64'd0;
        //Matrix multiplication
        for(i=0;i < 4;i=i+1)
            for(j=0;j < 4;j=j+1)
                for(k=0;k < 4;k=k+1)
                    Res1[i][j] = Res1[i][j] + ($signed(A1[i][k]) * $signed(B1[k][j]));
        //final output assignment - 3D array to 1D array conversion.            
        Res[0] = {Res1[0][0],Res1[0][1],Res1[0][2],Res1[0][3]};
        Res[1] = {Res1[1][0],Res1[1][1],Res1[1][2],Res1[1][3]};
        Res[2] = {Res1[2][0],Res1[2][1],Res1[2][2],Res1[2][3]};
        Res[3] = {Res1[3][0],Res1[3][1],Res1[3][2],Res1[3][3]};            
    end 

endmodule
