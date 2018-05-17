`timescale 1ns / 1ps
module main(
    input clk,
	input clk_en,
    input reset,
    input [WIDTH-1:0] U,
	input [WIDTH-1:0] Y,
    output [WIDTH-1:0] State
    );

	//Maquina de estados
	localparam STATE0 = 2'd0;		//Toma de datos
    localparam STATE1 = 2'd1;		//Antes de terminar de calcular K(nk)
    localparam STATE2 = 2'd2;		//Despues de calcular K(nk)
    localparam STATE3 = 2'd3;		//Esperando que se envie variable

	logic [1:0] state = STATE0, stateNext;

	//Parametros globales
	localparam nos = 4'd2;			//Numero de estados
	localparam noo = 4'd1;			//Numero de salidas
	localparam noi = 4'd1;			//Numero de entradas
	localparam WIDTH = 5'd16;		//Largo de digitos
	localparam intDigits = 3'd5;	//Numero de digitos enteros

	
	//Matrices de estado
	localparam [WIDTH-1:0] A [0:nos-1][0:nos-1] = ;
	localparam [WIDTH-1:0] B [0:nos-1][0:noi-1] = ;
	localparam [WIDTH-1:0] C [0:noo-1][0:nos-1] = ;
		
	//Covarianzas
	localparam [WIDTH-1:0] Q [0:nos-1][0:nos-1] = ;
	localparam [WIDTH-1:0] R [0:noo-1][0:noo-1] = ;

	//Condiciones iniciales
	localparam [WIDTH-1:0] P0 [0:nos-1][0:nos-1] = ;
	localparam [WIDTH-1:0] X0 [0:nos-1] = ;


	//Constante
	localparam Retardada = 1'd1; //1: ecuacion de estado escritas retardada
								 //0: ecuacion de estado escritas en adelanto

	//Estados
	logic [WIDTH-1:0] X_nkP [0:nos-1];
	logic [WIDTH-1:0] X_nkU [0:nos-1];
	
	
	//Variables de control ecuaciones de estado
	logic State_Prediction; //Activa prediccion de estados
    logic State_Update;		//Activa actualizacion de estados

    logic ready_State_Prediction;	//Termino de prediccion de estados
    logic ready_State_Update;		//Termino de actualizacion de estados


	//Variables de control matriz de covarianza
    logic Covariance_Prediction; 	//Inicia prediccion de covarianza
    logic Covariance_Gain;			//Inicia calculo de ganancia de kalman

    logic end_Prediction,;			//Termino de prediccion de covarianza
    logic end_K_G;					//Termino de ganancia de kalman
	logic end_Update;				//Termino de actualizacion de covarianza

	
	//Variables interconexion
	logic ready_calculation; 		//Finaliza de calcular
	
	
	//Calculo de variables de control
	assign ready_calculation = (Retardada)?(ready_State_Update&&end_Update):(ready_State_Prediction&&end_Prediction);	
	
	assign Covariance_Prediction = (Retardada)?(state == STATE1):(end_Update);
	assign Covariance_Gain = (Retardada)?(end_Prediction):(state == STATE1);

	assign State_Prediction = (Retardada)?(state == STATE1):(ready_State_Update);
	assign State_Update = end_K_G;
	
	assign State = (Retardada)?X_nkP:X_nkU;

    State_equation #(.WIDTH(WIDTH), .nos(nos), .noo(noo), .noi(noi), .intDigits(intDigits)) state_eq(.clk(clk), 
																									.ck_en(clk_en),
																									.reset(reset), 
																									.Start_Prediction(State_Prediction), 
																									.Start_Update(State_Update), 
																									.A(A), 
																									.B(B), 
																									.C(C), 
																									.U(U), 
																									.Y(Y), 
																									.K_nk(K), 
																									.X_0(X0), 
																									.ready_Prediction(ready_State_Prediction), 
																									.ready_Update(ready_State_Update), 
																									.X_nkP(X_nkP),
																									.X_nkU(X_nkU));

	covariance_matrix_generator #(.WIDTH(WIDTH), .nos(nos), .noo(noo), .intDigits(intDigits)) covar_eq(.clk(clk), 
																									.ck_en(clk_en),
																									.reset(reset), 
																									.Start_Prediction(Covariance_Prediction), 
																									.Start_K_G(Covariance_Gain), 
																									.A(A), 
																									.C(C), 
																									.Q(Q), 
																									.R(R), 
																									.P0(P0), 
																									.t2(K), 
																									.end_Prediction(end_Prediction), 
																									.end_K_G(end_K_G), 
																									.end_Update(end_Update));
	
    always_comb 
    begin
		case(state)
			STATE0: stateNext = STATE1;
            STATE1: stateNext = (end_K_G)?STATE2:STATE1;
            STATE2: stateNext = (ready_calculation)?STATE3:STATE2;
            STATE3: stateNext = STATE0;
            default: stateNext = STATE0;
        endcase
	
	end

    always_ff @(posedge clk)
    begin
		state <= (reset)?State0:stateNext;
	end	
	
endmodule
