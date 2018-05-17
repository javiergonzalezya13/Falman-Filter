`timescale 1ns / 1ps

module Matrix_mult_3 #(
        parameter WIDTH = 16,
        parameter nos = 4,
        parameter intDigits = 16
    )(
        input logic [WIDTH-1:0] A1[0:nos-1][0:nos-1],
        input logic [WIDTH-1:0] B1[0:nos-1],
        output logic [WIDTH-1:0] Res1[0:nos-1]
    );
    integer i,j,k;

    always_comb
    begin
        i = 0;
        j = 0;
        k = 0;
        Res1[0] = {WIDTH{1'd0}};
        Res1[1] = {WIDTH{1'd0}};
        Res1[2] = {WIDTH{1'd0}};
        Res1[3] = {WIDTH{1'd0}};
        //Matrix multiplication
        for(i=0;i < nos;i=i+1)
            for(k=0;k < nos;k=k+1)
                Res1[i] = Res1[i] + ($signed(A1[i][k]) * $signed(B1[k]));        
    end 
endmodule
