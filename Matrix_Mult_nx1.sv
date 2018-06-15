`timescale 1ns / 1ps
//Modulo multiplicador de dos matrices de resultado Nx1
module Matrix_Mult_nx1#(
        parameter WIDTH = 16,
        parameter nos = 4,
        parameter intDigits = 12
    )(
        input clk, //Reloj
        input clk_en, //Reloj de MATLAB
        input startMult,//Comienzo del calculo de AxB
        input logic [WIDTH-1:0] A[0:nos-1][0:nos-1], //Primera matriz de nos x nos a multiplicar
        input logic [WIDTH-1:0] B[0:nos-1], //Segunda matriz de nos x 1 a multiplicar
        output logic [WIDTH-1:0] Res[0:nos-1] = '{default:0}, //Matriz resultado de AxB
        output endMult //Termino de calcular AxB
    );
    //--------Estados-----------
    localparam IDLE = 2'd0;
    localparam ONMULT = 2'd1;
    localparam ENDMULT = 2'd2;
    
    localparam INTBITS = 2*WIDTH - intDigits - 1; //Bit desde el cual se toma el valor de la multiplicacion
    
    logic [1:0] state = 2'd0, stateNext;
    logic [nos-1:0] subI = 'd0, subINext;
    
    logic [WIDTH-1:0] ResNext[0:nos-1];
    logic [WIDTH-1:0] multW[0:nos-1] = '{default:0}; //Resultado de WIDTH bits de la multiplicacion
    logic [2*WIDTH-1:0] mult2W[0:nos-1] = '{default:0}; //Resultado completo de 2*WIDTH bits de la multiplicacion
            
    integer i,j;
    
    assign endMult = (state == ENDMULT);
    
    always_comb
    begin
        case(state)
            IDLE: stateNext = (startMult)?ONMULT:IDLE;
            ONMULT: stateNext = (subI == nos-1)?ENDMULT:ONMULT;
            ENDMULT: stateNext = IDLE;
            default: stateNext = IDLE;
        endcase
        
        case(state)
            ONMULT: subINext = (subI == nos - 1'd1)?'d0:subI + 'd1;
            default: subINext = 'd0;
        endcase
        
        if((state == IDLE)&&(startMult == 1'd1)) ResNext = '{default:0}; //Inicializa matriz Res en 0
        else if(state == ONMULT)
        begin
        //Multiplicacion de matrices
            for(i=0;i < nos;i=i+1)
            begin
                mult2W[i] = ($signed(A[i][subI]) * $signed(B[subI]));
                multW[i] = {mult2W[i][2*WIDTH -1], mult2W[i][INTBITS - 1 -:WIDTH - 1]};
                ResNext[i] = Res[i] + multW[i];        
            end
        end
        else ResNext = Res;
    end
    always_ff@(posedge clk)
    begin
        if(clk_en)
        begin
            state <= stateNext;
            Res <= ResNext;
            subI <= subINext;
        end
        else
        begin
            state <= state;
            Res <= Res;
            subI <= subI;
        end
    end
endmodule
