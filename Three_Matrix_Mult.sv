`timescale 1ns / 1ps
module Three_Matrix_Mult#(
        parameter WIDTH = 16,
        parameter nos = 4,
        parameter intDigits = 16
    )(
        input clk,
        input clk_en,
        input startMult,
        input logic [WIDTH-1:0] A[0:nos-1][0:nos-1],
        input logic [WIDTH-1:0] B[0:nos-1][0:nos-1],
        input logic [WIDTH-1:0] C[0:nos-1][0:nos-1],
        output logic [WIDTH-1:0] Res[0:nos-1][0:nos-1],
        output endMult
    );
    
    localparam IDLE = 2'd0;
    localparam FIRSTMULT = 2'd1;
    localparam SECONDMULT = 2'd2;
    localparam ENDMULT = 2'd3;
    
    logic [WIDTH-1:0] ResNext[0:nos-1][0:nos-1];
    logic [1:0] state = 2'd0, stateNext;
    //logic [1:0] count = 2'd0, countNext;
    
    logic [WIDTH-1:0] firstMatrix[0:nos-1][0:nos-1];
    logic [WIDTH-1:0] secondMatrix[0:nos-1][0:nos-1];
    logic [WIDTH-1:0] multRes[0:nos-1][0:nos-1];
        
    //assign firstMatrix = (state == firstMatrix)?:;
    //assign secondMatrix = ()?:;
    
    assign endMult = (state == ENDMULT);
    
    //assign data = ($signed(firstMatrix[0][subI]) * $signed(secondMatrix[subI][0]));
    logic multON;
    logic endMult2x2;
    assign multON = ((state == FIRSTMULT)||(state == SECONDMULT));
    Two_Matrix_Mult#(
            WIDTH,
            nos,
            intDigits
        ) AxBxC(
            .clk(clk),
            .clk_en(clk_en),
            .multON(multON),
            .A(firstMatrix),
            .B(secondMatrix),
            .Res(multRes),
            .endMult2x2(endMult2x2)
        );
    
    always_comb
    begin
        case(state)
            IDLE: stateNext = (startMult)?FIRSTMULT:IDLE;
            FIRSTMULT: stateNext = (endMult2x2)?SECONDMULT:FIRSTMULT;
            SECONDMULT: stateNext = (endMult2x2)?ENDMULT:SECONDMULT;
            default: stateNext = IDLE;
        endcase
        
        case(state)
            IDLE:
            begin
                firstMatrix = '{default:0};
                secondMatrix = '{default:0};
            end
            FIRSTMULT:
            begin
                firstMatrix = A;
                secondMatrix = B;
            end
            SECONDMULT:
            begin
                firstMatrix = Res;
                secondMatrix = C;
            end
            default:
            begin
                firstMatrix = '{default:0};
                secondMatrix = '{default:0};
            end
        endcase
        
        if(endMult2x2) ResNext = multRes;
        else ResNext = Res;
        
    end
    always_ff@(posedge clk)
    begin
        if(clk_en)
        begin
            state <= stateNext;
            Res <= ResNext;
        end
        else
        begin
            state <= state;
            Res <= Res;
        end
    end
endmodule
