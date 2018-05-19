`timescale 1ns / 1ps
module Matrix_Inversor_2x2#(
        parameter WIDTH = 16,
        //parameter nos = 2,
        parameter intDigits = 16
    )(
        input clk,
        input startInv,
        input logic [WIDTH-1:0] A[0:1][0:1],
        output logic [WIDTH-1:0] Res[0:1][0:1] = '{default:0},
        output endInv
    );
    
    localparam IDLE = 2'd0;
    localparam INVERSION = 2'd1;
    localparam ENDINV = 2'd2;
    
    logic [WIDTH-1:0] determinant;
    
    logic [1:0] state = 2'd0, stateNext;
    
    logic [WIDTH-1:0] ResNext[0:1][0:1];
    
    assign determinant = (state == INVERSION)?($signed(A[0][0]) * $signed(A[1][1]))-($signed(A[0][1]) * $signed(A[1][0])):'d1;
    assign endInv = (state == ENDINV);
    
    always_comb
    begin
        case(state)
            IDLE: stateNext = (startInv)?INVERSION:IDLE;
            INVERSION: stateNext = ENDINV;
            ENDINV: stateNext = IDLE;
            default: stateNext = IDLE;
        endcase
        case(state)
            INVERSION:
            begin
                ResNext[0][0] = ($signed((A[1][1])))/($signed(determinant));//determinant;
                ResNext[0][1] = ($signed(-(A[0][1])))/($signed(determinant));//determinant;
                ResNext[1][0] = ($signed(-(A[1][0])))/($signed(determinant));//determinant;
                ResNext[1][1] = ($signed((A[0][0])))/($signed(determinant));//determinant;
            end
            default: ResNext = Res;
        endcase
    end
    always_ff@(posedge clk)
    begin
        Res <= ResNext;
        state <= stateNext;
    end
endmodule
