`timescale 1ns / 1ps
//Modulo multiplicador de tres matrices NxN
module Three_Matrix_Mult#(
        parameter WIDTH = 16, //
        parameter nos = 4, //
        parameter intDigits = 16 //
    )(
        input clk, //Reloj
        input clk_en, //Reloj de MATLAB
        input startMult, //Comienzo del calculo de la multiplicacion de AxBxC
        input logic [WIDTH-1:0] A[0:nos-1][0:nos-1], //Primera matriz a multiplicar
        input logic [WIDTH-1:0] B[0:nos-1][0:nos-1], //Segunda matriz a multiplicar
        input logic [WIDTH-1:0] C[0:nos-1][0:nos-1], //Tercera matriz a multiplicar
        output logic [WIDTH-1:0] Res[0:nos-1][0:nos-1], //Resultado de AxBxC
        output endMult //Termino de calcular AxBxC
    );
    
    localparam IDLE = 2'd0;
    localparam FIRSTMULT = 2'd1;
    localparam SECONDMULT = 2'd2;
    localparam ENDMULT = 2'd3;
    
    logic [WIDTH-1:0] ResNext[0:nos-1][0:nos-1];
    logic [1:0] state = 2'd0, stateNext;
    
    logic [WIDTH-1:0] firstMatrix[0:nos-1][0:nos-1];
    logic [WIDTH-1:0] secondMatrix[0:nos-1][0:nos-1];
    logic [WIDTH-1:0] multRes[0:nos-1][0:nos-1];
        
    
    assign endMult = (state == ENDMULT);
    
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
