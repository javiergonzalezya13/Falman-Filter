`timescale 1ns / 1ps

module State_equation#(
        parameter WIDTH = 16,
        parameter nos = 4,
        parameter noo = 2,
        parameter noi = 2
    )(
        input logic clk,
        input logic reset,
        input logic [WIDTH-1:0] A[0:nos-1][0:nos-1],
        input logic [WIDTH-1:0] B[0:nos-1][0:noi-1],
        input logic [WIDTH-1:0] H[0:noo-1][0:nos-1],
        input logic [WIDTH-1:0] U[0:noi-1],
        input logic [WIDTH-1:0] Y[0:noo-1],
        input logic [WIDTH-1:0] K_nk[0:nos-1][0:noo-1],
        input logic [WIDTH-1:0] X_0[0:nos-1],
        input logic Start_P, //Start prediction
        //input logic Start_I, //Start innovation
        input ready_K_G,
        input logic restartCalculation,
        output ready_x_nk,
        output logic [WIDTH-1:0] X_nk[0:nos-1]
    );
    localparam IDLE = 4'd15;//
    localparam STATE0 = 4'd0;//Multiplicate Fdnk x c x d
    localparam STATE1 = 4'd1;//Finish multiplication
    localparam STATE2 = 4'd2;//Calculate g
    localparam STATE3 = 4'd3;//Multiplicate H x g x j
    localparam STATE4 = 4'd4;//Finish multiplication
    localparam STATE5 = 4'd5;//Inverse to calculate t
    localparam STATE6 = 4'd6;//Finish inversion
    localparam STATE7 = 4'd7;//Rebundant
    localparam STATE8 = 4'd8;//Calculate t2

    logic [3:0] state = IDLE, stateNext;
    
    logic [1:0] Sel;
    
    logic en0, en1;
    
    logic [WIDTH-1:0] matrix_mult_in_1 [0:nos-1][0:nos-1];
    logic [WIDTH-1:0] matrix_mult_in_2 [0:nos-1];
    
    logic [WIDTH-1:0] B_nosxnos [0:nos-1][0:nos-1];
    logic [WIDTH-1:0] H_nosxnos [0:nos-1][0:nos-1];
    logic [WIDTH-1:0] K_nk_nosxnos [0:nos-1][0:nos-1];
    logic [WIDTH-1:0] U_nosx1 [0:nos-1];
    logic [WIDTH-1:0] Y_nosx1 [0:nos-1];
    
    logic [WIDTH-1:0] matrix_mult_res[0:nos-1];
    logic [WIDTH-1:0] matrix_add[0:nos-1];
        
    logic [WIDTH-1:0] St_I[0:nos-1];
    logic [WIDTH-1:0] St_I_next[0:nos-1];
    logic [WIDTH-1:0] St_P[0:nos-1];
    logic [WIDTH-1:0] St_P_next[0:nos-1];
    logic [WIDTH-1:0] St_prev[0:nos-1];
    
    integer int_i1, int_j1;
    integer int_i2;
    integer int_i3;
    
    assign en0 = ((state == STATE2)||(state == STATE4));
    assign en1 = ((state == STATE6)||(state == STATE8));
    
    Matrix_mult_3 #(.WIDTH(WIDTH), .nos(nos), .intDigits(16)) AxB(.A1(matrix_mult_in_1), .B1(matrix_mult_in_2), .Res1(matrix_mult_res));
    
    assign ready_x_nk = (state == STATE8);
    
    always_comb 
    begin
        case(state)
            IDLE: stateNext = (Start_P)?STATE1:IDLE;
            STATE1: stateNext = STATE2;
            STATE2: stateNext = STATE3;
            STATE3: stateNext = STATE4;
            STATE4: stateNext = (ready_K_G)?STATE5:STATE4;
            STATE5: stateNext = STATE6;
            STATE6: stateNext = STATE7;
            STATE7: stateNext = STATE8;
            STATE8: stateNext = (restartCalculation)?STATE1:STATE8;
            default: stateNext = IDLE;
        endcase
        
        case(state)
            IDLE, STATE1, STATE2: Sel = 2'd0;
            STATE3, STATE4: Sel = 2'd1;
            STATE5, STATE6: Sel = 2'd2;
            STATE7, STATE8: Sel = 2'd3;
            default: Sel = 2'd0;
        endcase
        for (int_i1=0; int_i1 < nos; int_i1++)
            for(int_j1=0; int_j1 < nos; int_j1++)
            begin
                B_nosxnos[int_i1][int_j1] = (int_j1<noi)?B[int_i1][int_j1]:{WIDTH{1'd0}};
                H_nosxnos[int_i1][int_j1] = (int_i1<noo)?-H[int_i1][int_j1]:{WIDTH{1'd0}};
                K_nk_nosxnos[int_i1][int_j1] = (int_j1<noo)?K_nk[int_i1][int_j1]:{WIDTH{1'd0}};
            end
        for (int_i2=0; int_i2 < nos; int_i2++)
        begin
            U_nosx1[int_i2] = (int_i2<noi)?U[int_i2]:{WIDTH{1'd0}};
            Y_nosx1[int_i2] = (int_i2<noo)?Y[int_i2]:{WIDTH{1'd0}};
        end
        case(Sel)
            2'd0:
            begin
                matrix_mult_in_1 = B_nosxnos;
                matrix_mult_in_2 = U_nosx1;
            end
            2'd1:
            begin
                matrix_mult_in_1 = A;
                matrix_mult_in_2 = St_I;
            end
            2'd2:
            begin
                matrix_mult_in_1 = H_nosxnos;
                matrix_mult_in_2 = St_P;
            end
            2'd3:
            begin
                matrix_mult_in_1 = K_nk_nosxnos;
                matrix_mult_in_2 = St_I;
            end
        endcase

        for(int_i3=0; int_i3 < nos; int_i3++)
            St_prev[int_i3] = matrix_mult_res[int_i3] + matrix_add[int_i3];
            
        St_I_next = (en0)?St_prev:St_I;
        St_P_next = (en1)?St_prev:St_P;

        
        case(Sel)
            2'd0: matrix_add = '{default:0};
            2'd1: matrix_add = St_P;
            2'd2: matrix_add = Y_nosx1;
            2'd3: matrix_add = St_P;
        endcase
    end
    
    always_ff @(posedge clk)
    begin
        state <= (reset)?IDLE:stateNext;
        St_I <= (state == IDLE)?X_0:St_I_next;
        St_P <= St_P_next;
        X_nk <= (state == IDLE)?X_0:(state == STATE4)?St_P:X_nk;
    end
endmodule
