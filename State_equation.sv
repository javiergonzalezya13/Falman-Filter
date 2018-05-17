`timescale 1ns / 1ps

module State_equation#(
        parameter WIDTH = 16,
        parameter nos = 4,
        parameter noo = 2,
        parameter noi = 2
    )(
        input logic clk,
        input logic reset,
        input logic Start_Prediction, 					//Start prediction
        input logic Start_Update, 						//Start update
        input logic [WIDTH-1:0] A[0:nos-1][0:nos-1],
        input logic [WIDTH-1:0] B[0:nos-1][0:noi-1],
        input logic [WIDTH-1:0] C[0:noo-1][0:nos-1],
        input logic [WIDTH-1:0] U[0:noi-1],				//Entrada planta
        input logic [WIDTH-1:0] Y[0:noo-1],				//Salida planta
        input logic [WIDTH-1:0] K_nk[0:nos-1][0:noo-1], //K(nk)
        input logic [WIDTH-1:0] X_0[0:nos-1],			//Estado inicial
        output ready_Prediction,
        output ready_Update,
        output logic [WIDTH-1:0] X_nk[0:nos-1]
    );
	
	
    localparam IDLE = 4'd15;//
	
	//Prediccion
	localparam STATE0 = 4'd0;//Empieza multiplicacion ' B x U '
    localparam STATE1 = 4'd1;//Termina multiplicacion
    localparam STATE2 = 4'd2;//Almacena variable
    localparam STATE3 = 4'd3;//Empieza multiplicacion ' A x X(nk-1/nk-1) '
    localparam STATE4 = 4'd4;//Termina multiplicacion
    localparam STATE5 = 4'd5;//Suma ' A X(nk-1/nk-1) + B U '

	//Actualizacion
    localparam STATE6 = 4'd6;//Empieza multiplicacion ' -C x X(nk/nk-1) '
    localparam STATE7 = 4'd7;//Termina multiplicacion
    localparam STATE8 = 4'd8;//Suma ' y - C X(nk/nk-1) '
    localparam STATE9 = 4'd9;//Empieza multiplicacion ' K(nk) x [y - C X(nk/nk-1)] '
    localparam STATE10 = 4'd10;//Termina multiplicacion
    localparam STATE11 = 4'd11;//Suma ' X(nk/nk-1) + K(nk) [y - C X(nk/nk-1)] '

	
	logic [3:0] state = IDLE, stateNext;
    
	//Variables de control
    logic en0, en1, en2;//Habilita flip flop
    logic [1:0] Sel;//Control de multiplexores
	logic Start_mult, Start_inv;
	logic end_mult, end_inv;

    
	//Matrices intermedias
    logic [WIDTH-1:0] matrix_add[0:nos-1];	//Salida multiplexor 3
    logic [WIDTH-1:0] St_prev[0:nos-1];		//Previo asignacion
    logic [WIDTH-1:0] St_P[0:nos-1];		//\hat_X(nk/nk)
    logic [WIDTH-1:0] St_I[0:nos-1];		//\hat_X(nk/nk-1)

    logic [WIDTH-1:0] St_prev_next[0:nos-1];
    logic [WIDTH-1:0] St_I_next[0:nos-1];
    logic [WIDTH-1:0] St_P_next[0:nos-1];

	//Matrices expandidas
    logic [WIDTH-1:0] B_nosxnos [0:nos-1][0:nos-1];
    logic [WIDTH-1:0] C_nosxnos [0:nos-1][0:nos-1];
    logic [WIDTH-1:0] K_nk_nosxnos [0:nos-1][0:nos-1];
    logic [WIDTH-1:0] U_nosx1 [0:nos-1];
    logic [WIDTH-1:0] Y_nosx1 [0:nos-1];
	
	//Multiplicador
    logic [WIDTH-1:0] matrix_mult_in_1 [0:nos-1][0:nos-1]; 	//Entrada 1
    logic [WIDTH-1:0] matrix_mult_in_2 [0:nos-1];			//Entrada 2
    logic [WIDTH-1:0] matrix_mult_res[0:nos-1];				//Resultado
	

	//Indices de matrices
    integer int_i0, int_i1, int_i2;
    integer int_j1;
    

	//Multiplicacion
    Matrix_mult_3 #(.WIDTH(WIDTH), .nos(nos), .intDigits(16)) AxB(.A1(matrix_mult_in_1), .B1(matrix_mult_in_2), .Res1(matrix_mult_res));
    

    assign en0 = ((state == STATE2)||(state == STATE8));
    assign en1 = (state == STATE5);
    assign en2 = (state == STATE11);

    assign ready_x_nk_P = (state == STATE5);
    assign ready_x_nk_I = (state == STATE11);
    
    always_comb 
    begin
		//**************************************ARREGLAR*************
        ///////////////////////////////State Machine//////////////////////////////////////////
        case(state)
            IDLE: stateNext = (Start_P)?STATE0:(ready_K_G)?STATE1:IDLE;

            STATE0: stateNext = STATE1;
            STATE1: stateNext = (end_mult)?STATE2:STATE1;
            STATE2: stateNext = STATE3;
            STATE3: stateNext = STATE4;
            STATE4: stateNext = (end_mult)?STATE5:STATE4;
            STATE5: stateNext = (ready_K_G)?STATE6:STATE5;
			
            STATE6: stateNext = STATE7;
            STATE7: stateNext = (end_mult)?STATE8:STATE7;
            STATE8: stateNext = STATE9;
            STATE9: stateNext = STATE10;
            STATE10: stateNext = (end_mult)?STATE11:STATE10;
            STATE11 stateNext = (Start_P)?STATE0:STATE11;

            default: stateNext = IDLE;
        endcase
        /////////////////////////////////////////////////////////////////////////
		//***************************************************
        
        /////////////////////////////////Variables de control//////////////////////////////////////////
        case(state)
            IDLE, STATE0, STATE1, STATE2: Sel = 2'd0;
            STATE3, STATE4, STATE5: Sel = 2'd1;
            STATE6, STATE7, STATE8: Sel = 2'd2;
            STATE9, STATE10, STATE11: Sel = 2'd3;
            default: Sel = 2'd0;
        endcase
        /////////////////////////////////////////////////////////////////////////		

        ///////////////////////////////Multiplexores//////////////////////////////////////////
        case(Sel)
            2'd0:
            begin
                matrix_mult_in_1 = B_nosxnos;
                matrix_mult_in_2 = U_nosx1;
				matrix_add = '{default:0};
            end
            2'd1:
            begin
                matrix_mult_in_1 = A;
                matrix_mult_in_2 = St_I;
				matrix_add = St_P;
            end
            2'd2:
            begin
                matrix_mult_in_1 = C_nosxnos;
                matrix_mult_in_2 = St_P;
				matrix_add = Y_nosx1;
            end
            2'd3:
            begin
                matrix_mult_in_1 = K_nk_nosxnos;
                matrix_mult_in_2 = St_I;
				matrix_add = St_P;
            end
        endcase
        /////////////////////////////////////////////////////////////////////////

        ///////////////////////////////Calculo de matrices//////////////////////////////////////////		
        for(int_i0=0; int_i0 < nos; int_i0++)
            St_prev_next[int_i0] = (en0)?matrix_mult_res[int_i0] + matrix_add[int_i0]:St_prev[int_i0];
			St_I_next[int_i0] = (en1)?matrix_mult_res[int_i0] + matrix_add[int_i0]:St_I[int_i0];
			St_P_next[int_i0] = (en2)?matrix_mult_res[int_i0] + matrix_add[int_i0]:St_P[int_i0];
        /////////////////////////////////////////////////////////////////////////

        ///////////////////////////////Reajuste de matrices//////////////////////////////////////////
        for (int_i1=0; int_i1 < nos; int_i1++)
            for(int_j1=0; int_j1 < nos; int_j1++)
            begin
                B_nosxnos[int_i1][int_j1] = (int_j1<noi)?B[int_i1][int_j1]:{WIDTH{1'd0}};
                C_nosxnos[int_i1][int_j1] = (int_i1<noo)?-C[int_i1][int_j1]:{WIDTH{1'd0}};
                K_nk_nosxnos[int_i1][int_j1] = (int_j1<noo)?K_nk[int_i1][int_j1]:{WIDTH{1'd0}};
            end

		for (int_i2=0; int_i2 < nos; int_i2++)
		begin
			U_nosx1[int_i2] = (int_i2<noi)?U[int_i2]:{WIDTH{1'd0}};
			Y_nosx1[int_i2] = (int_i2<noo)?Y[int_i2]:{WIDTH{1'd0}};
		end
        /////////////////////////////////////////////////////////////////////////
        
    end
    
    always_ff @(posedge clk)
    begin
        state <= (reset)?IDLE:stateNext;
        St_prev <= St_prev_next;
        St_I <= (state == IDLE)?X_0:St_I_next;
        St_P <= (state == IDLE)?X_0:St_P_next;
        X_nk <= (state == IDLE)?X_0:(state == STATE5)?St_P:X_nk;
    end
endmodule
