`timescale 1ns / 1ps
module Matrix_mult_2 #(
        parameter WIDTH = 16,
        parameter nos = 4
    )(
        input logic [WIDTH-1:0] A1[0:nos-1][0:nos-1],
        input logic [WIDTH-1:0] B1[0:nos-1][0:nos-1],
        output logic [WIDTH-1:0] Res1[0:nos-1][0:nos-1]
    );
    //input and output ports.
    //The size 32 bits which is 2*2=4 elements,each of which is 8 bits wide.
    //internal variables
    //reg [WIDTH:0] Res1 [0:nos][0:nos]; 
    integer i,j,k;

    always_comb
    begin
        i = 0;
        j = 0;
        k = 0;
        {Res1[0][0],Res1[0][1],Res1[0][2],Res1[0][3]} = {WIDTH{4'd0}}; //initialize to zeros.
        {Res1[1][0],Res1[1][1],Res1[1][2],Res1[1][3]} = {WIDTH{4'd0}};
        {Res1[2][0],Res1[2][1],Res1[2][2],Res1[2][3]} = {WIDTH{4'd0}};
        {Res1[3][0],Res1[3][1],Res1[3][2],Res1[3][3]} = {WIDTH{4'd0}};
        //Matrix multiplication
        for(i=0;i < nos;i=i+1)
            for(j=0;j < nos;j=j+1)
                for(k=0;k < nos;k=k+1)
                    Res1[i][j] = Res1[i][j] + ($signed(A1[i][k]) * $signed(B1[k][j]));        
    end 
endmodule
