`timescale 1ns / 1ps
//Modulo de calculo de covarianza
module covariance_matrix_generator #(
        parameter WIDTH = 16,
        parameter nos = 4,//number of states
        parameter noo = 2, //number of outputs
		parameter intDigits = 16
    )(
        input logic clk, //Reloj   
        input logic clk_en, //Reloj de MATLAB
        input logic reset, //Reset
        input logic Start_Prediction, //Comenzar prediccion
        input logic Start_K_G, //Comenzar calculo de ganancia de Kalman
        input logic [WIDTH-1:0] A [0:nos-1][0:nos-1], //Matriz A de estado
        input logic [WIDTH-1:0] C [0:noo-1][0:nos-1], //Matriz C de estado
        input logic [WIDTH-1:0] Q [0:nos-1][0:nos-1], // Covarianza ruido de entrada
        input logic [WIDTH-1:0] R [0:noo-1][0:noo-1], // Covarianza ruido de salida
        input logic [WIDTH-1:0] P0 [0:nos-1][0:nos-1],// Covarianza inicial

        output logic [WIDTH-1:0] t2 [0:nos-1][0:noo-1], // K(nk) ganancia de Kalman
        output logic end_Prediction, //Calculo de la prediccion listo
        output logic end_K_G, //Calculo de la ganancia de Kalman listo
        output logic end_Update //Calculo de la actualizacion listo
    );
    
	
    localparam IDLE = 4'd15;//Waiting for starting signal

	// Prediccion (o Time update) de matriz de covarianza
    localparam STATE0 = 4'd0;//Empieza multiplicacion ' A x P(nk-1/nk-1) x A^T '
    localparam STATE1 = 4'd1;//Termina multiplicacion
    localparam STATE2 = 4'd2;//Suma ' A P(nk-1/nk-1) A^T + Q '

	// Ganancia de Kalman
    localparam STATE3 = 4'd3;//Empieza multiplicacion ' C x P(nk/nk-1) x C^T '
    localparam STATE4 = 4'd4;//Termina multiplicacion
    localparam STATE5 = 4'd5;//Suma ' C P(nk/nk-1) C^T + R '
    localparam STATE6 = 4'd6;//Empieza inversion ' (C P(nk/nk-1) C^T + R)^(-1) '
    localparam STATE7 = 4'd7;//Termina inversion
    localparam STATE8 = 4'd8;//Empieza multiplicacion ' P(nk/nk-1) x C^T x (C P(nk/nk-1) C^T + R)^(-1) '
    localparam STATE9 = 4'd9;//Termina multiplicacion
	
	// Actualizacion (o Measurement update)de matriz de covarianza
    localparam STATE10 = 4'd10;//Empieza multiplicacion ' K(nk) x C x P(nk/nk-1) '
    localparam STATE11 = 4'd11;//Termina multiplicacion
    localparam STATE12 = 4'd12;//Suma ' P(nk/nk-1) - K(nk) C P(nk/nk-1) '
    localparam STATE13 = 4'd13;//Suma ' (P(nk/nk) + P(nk/nk)^T)/2 '
	

    logic [3:0] state = IDLE, stateNext;

	//Variables de control
    logic en0, en1, en2, en3, en4;//Habilita flip flop
    logic [1:0] Sel;//Control de multiplexores
	logic Start_mult, Start_inv;
	logic end_mult, end_inv;

	//Matrices intermedias
	logic [WIDTH-1:0] g [0:nos-1][0:nos-1]; // P(nk/nk-1)
    logic [WIDTH-1:0] c [0:nos-1][0:nos-1]; // P(nk-1/nk-1)
    logic [WIDTH-1:0] c_mean [0:nos-1][0:nos-1];        
    logic [WIDTH-1:0] t [0:noo-1][0:noo-1]; // (C P(nk/nk-1) C^T + R)^(-1)
    logic [WIDTH-1:0] matrix_en3 [0:nos-1][0:nos-1]; // P(nk/nk-1) - K(nk) C P(nk/nk-1)
    logic [WIDTH-1:0] j [0:nos-1][0:nos-1]; // C^T
    logic [WIDTH-1:0] d [0:nos-1][0:nos-1]; // A^T
    logic [WIDTH-1:0] matrix_mult_in_1 [0:nos-1][0:nos-1]; // Salida multiplexor 1
    logic [WIDTH-1:0] matrix_mult_in_2 [0:nos-1][0:nos-1]; // Salida multiplexor 2
    logic [WIDTH-1:0] matrix_mult_in_3 [0:nos-1][0:nos-1]; // Salida multiplexor 3
    
    logic [WIDTH-1:0] g_next [0:nos-1][0:nos-1];
    logic [WIDTH-1:0] c_next [0:nos-1][0:nos-1];
    logic [WIDTH-1:0] t2_next [0:nos-1][0:noo-1];
    logic [WIDTH-1:0] matrix_en3_next [0:nos-1][0:nos-1];
    logic [WIDTH-1:0] t_next [0:noo-1][0:noo-1];
    
    //Matrices expandidas    
    logic [WIDTH-1:0] t_nosxnos [0:nos-1][0:nos-1];
    logic [WIDTH-1:0] t2_nosxnos [0:nos-1][0:nos-1];
    logic [WIDTH-1:0] C_nosxnos [0:nos-1][0:nos-1];    

	//Entrada y salida multiplicacion
	
	
	
    logic [WIDTH-1:0] matrix_AxBxC [0:nos-1][0:nos-1]; //SALIDA DEL MULTIPLICADOR
    
    logic [WIDTH-1:0] matrix_mult [0:nos-1][0:nos-1];
    logic [WIDTH-1:0] matrix_mult_next [0:nos-1][0:nos-1];
	
    //Entrada inversion
    logic [WIDTH-1:0] prev_matrix_inversion [0:noo-1][0:noo-1];// C P(nk/nk-1) C^T + R
    logic [WIDTH-1:0] matrix_inv [0:noo-1][0:noo-1]; //SALIDA DEL INVERSION

    logic [WIDTH-1:0] prev_matrix_inversion_next [0:noo-1][0:noo-1];
	

	//Indices de matrices
	integer int_i0, int_i1, int_i2, int_i3, int_i4;
    integer int_j0, int_j1, int_j2, int_j3, int_j4;

	//*********************************************************************
	//Multiplicacion//*********************************************************************
    Three_Matrix_Mult#(
            .WIDTH(WIDTH),
            .nos(nos),
            .intDigits(intDigits)
        ) AxBxC(
            .clk(clk),
            .clk_en(clk_en),
            .startMult(Start_mult),
            .A(matrix_mult_in_1),
            .B(matrix_mult_in_2),
            .C(matrix_mult_in_3),
            .Res(matrix_AxBxC),
            .endMult(end_mult)
        );
	
	//*********************************************************************	
	//Inversion
	/*
    Matrix_Inversor_2x2#(
            .WIDTH(WIDTH),
            .intDigits(intDigits)
        ) MI2x2(
            .clk(clk),
            .clk_en(clk_en),
            .startInv(Start_inv2x2),
            .A(prev_matrix_inversion),
            .Res(matrix_inv),
            .endInv(end_inv2x2)
        );
    */
    Matrix_Inversor_1x1#(
            .WIDTH(WIDTH),
            .intDigits(intDigits)
        ) MI1x1(
            .clk(clk),
            .clk_en(clk_en),
            .startInv(Start_inv),
            .A(prev_matrix_inversion),
            .Res(matrix_inv),
            .endInv(end_inv)
        );
     
    //*********************************************************************

	
	
	assign end_Prediction = (state == STATE2);
    assign end_K_G   = ((state == STATE9)&&(end_mult));
    assign end_Update = (state == STATE13);


    always_comb
    begin
        
        ///////////////////////////////State Machine//////////////////////////////////////////
        case(state)
			IDLE: stateNext = (Start_Prediction)?STATE0:(Start_K_G)?STATE3:IDLE;
            
			STATE0: stateNext = STATE1;
            STATE1: stateNext = (end_mult)?STATE2:STATE1;
            STATE2: stateNext = (Start_K_G)?STATE3:STATE2;

            STATE3: stateNext = STATE4;
            STATE4: stateNext = (end_mult)?STATE5:STATE4;
            STATE5: stateNext = STATE6;
            STATE6: stateNext = STATE7;
            STATE7: stateNext = (end_inv)?STATE8:STATE7;
            STATE8: stateNext = STATE9;
            STATE9: stateNext = (end_mult)?STATE10:STATE9;
            STATE10: stateNext = STATE11;
            STATE11: stateNext = (end_mult)?STATE12:STATE11;
            STATE12: stateNext = STATE13;
            STATE13: stateNext = (Start_Prediction)?STATE0:STATE13;

            default: stateNext = IDLE;
        endcase
        /////////////////////////////////////////////////////////////////////////

		
        /////////////////////////////////Variables de control//////////////////////////////////////////
        case(state)
            IDLE: begin
                {Start_mult, Start_inv} = 2'b00;
                {en4, en3, en2, en1, en0} = 5'd0;
                Sel = 2'd0;
            end
            STATE0: begin
                {Start_mult, Start_inv} = 2'b10;
                {en4, en3, en2, en1, en0} = 5'd0;
                Sel = 2'd0;
            end
            STATE1: begin
                {Start_mult, Start_inv} = 2'b00;
                {en4, en3, en2, en1, en0} = 5'd0;
                Sel = 2'd0;
            end
            STATE2: begin
                {Start_mult, Start_inv} = 2'b00;
                {en4, en3, en2, en1, en0} = 5'b00001;
                Sel = 2'd0;
            end

			
            STATE3: begin
                {Start_mult, Start_inv} = 2'b10;
                {en4, en3, en2, en1, en0} = 5'd0;
                Sel = 2'd1;
            end
            STATE4: begin
                {Start_mult, Start_inv} = 2'b00;
                {en4, en3, en2, en1, en0} = 5'd0;
                Sel = 2'd1;
            end
            STATE5: begin
                {Start_mult, Start_inv} = 2'b00;
                {en4, en3, en2, en1, en0} = 5'd00010;
                Sel = 2'd1;
            end
            STATE6: begin
                {Start_mult, Start_inv} = 2'b01;
                {en4, en3, en2, en1, en0} = 5'd0;
                Sel = 2'd1;
            end
            STATE7: begin
                {Start_mult, Start_inv} = 2'b00;
                {en4, en3, en2, en1, en0} = 5'd0;
                Sel = 2'd1;
            end
            STATE8: begin
                {Start_mult, Start_inv} = 2'b10;
                {en4, en3, en2, en1, en0} = 5'd0;
                Sel = 2'd2;
            end
            STATE9: begin
                {Start_mult, Start_inv} = 2'b00;
                {en4, en3, en2, en1, en0} = 5'b00100;
                Sel = 2'd2;
            end

			
            STATE10: begin
                {Start_mult, Start_inv} = 2'b10;
                {en4, en3, en2, en1, en0} = 5'd0;
                Sel = 2'd3;
            end
            STATE11: begin
                {Start_mult, Start_inv} = 2'b00;
                {en4, en3, en2, en1, en0} = 5'd0;
                Sel = 2'd3;
            end
            STATE12: begin
                {Start_mult, Start_inv} = 2'b00;
                {en4, en3, en2, en1, en0} = 5'b01000;
                Sel = 2'd3;
            end
            STATE13: begin
                {Start_mult, Start_inv} = 2'b00;
                {en4, en3, en2, en1, en0} = 5'b10000;
                Sel = 2'd3;
            end
            default: begin
                {Start_mult, Start_inv} = 2'b00;
                {en4, en3, en2, en1, en0} = 5'd0;
                Sel = 2'd0;
            end
        endcase
        /////////////////////////////////////////////////////////////////////////		
		
        ///////////////////////////////Multiplexores//////////////////////////////////////////
        case(Sel)
            2'd0: begin
				matrix_mult_in_1 = A;
				matrix_mult_in_2 = c;
				matrix_mult_in_3 = d;
			end
            2'd1: begin
				matrix_mult_in_1 = C_nosxnos;
				matrix_mult_in_2 = g;
				matrix_mult_in_3 = j;
			end
            2'd2: begin
				matrix_mult_in_1 = g;
				matrix_mult_in_2 = j;
				matrix_mult_in_3 = t_nosxnos;
			end
            default: begin
				matrix_mult_in_1 = t2_nosxnos;
				matrix_mult_in_2 = C_nosxnos;
				matrix_mult_in_3 = g;
			end
        endcase
        /////////////////////////////////////////////////////////////////////////
		
        ///////////////////////////////Calculo de matrices//////////////////////////////////////////

        // A P(nk-1/nk-1) A^T + Q
        for (int_i0=0; int_i0 < nos; int_i0++)
            for(int_j0=0; int_j0 < nos; int_j0++)
                g_next[int_i0][int_j0] = (en0)?matrix_mult[int_i0][int_j0] + Q[int_i0][int_j0]:g[int_i0][int_j0];
        
		// C P(nk/nk-1) C^T + R 
        for (int_i1=0; int_i1 < noo; int_i1++)
            for(int_j1=0; int_j1 < noo; int_j1++)
                prev_matrix_inversion_next[int_i1][int_j1] = (en1)?matrix_mult[int_i1][int_j1] + R[int_i1][int_j1]:prev_matrix_inversion[int_i1][int_j1];

		// K(nk)
        for (int_i2=0; int_i2 < nos; int_i2++)
            for(int_j2=0; int_j2 < noo; int_j2++)
                t2_next[int_i2][int_j2] = (en2&&end_mult)?matrix_AxBxC[int_i2][int_j2]:t2[int_i2][int_j2];

        // P(nk/nk) 
        
        for (int_i3=0; int_i3 < nos; int_i3++)
            for(int_j3=0; int_j3 < nos; int_j3++)
            begin
                // P(nk/nk-1) - K(nk) C P(nk/nk-1) 
                matrix_en3_next[int_i3][int_j3] = (en3)?g[int_i3][int_j3] - matrix_mult[int_i3][int_j3]:matrix_en3[int_i3][int_j3];

                // (P(nk/nk) + P(nk/nk)^T)/2
                c_mean[int_i3][int_j3] = (matrix_en3[int_i3][int_j3])>>>1;
                c_next[int_i3][int_j3] = (en4)?c_mean[int_i3][int_j3] + c_mean[int_j3][int_i3]:c[int_i3][int_j3];
				//c_next[int_i3][int_j3] = (en4)?(matrix_en3[int_i3][int_j3] + matrix_en3[int_j3][int_i3])>>>1:c[int_i3][int_j3];
            end
        /////////////////////////////////////////////////////////////////////////

        ///////////////////////////////Reajuste de matrices//////////////////////////////////////////
		        
        for (int_i4=0; int_i4 < nos; int_i4++)
            for(int_j4=0; int_j4 < nos; int_j4++)
            begin
            
        // (C P(nk/nk-1) C^T + R)^(-1)
                t_nosxnos[int_i4][int_j4] = ((int_i4<noo)&&(int_j4<noo))?t[int_i4][int_j4]:{WIDTH{1'd0}};
        
        // K(nk)        
                t2_nosxnos[int_i4][int_j4] = (int_j4<noo)?t2[int_i4][int_j4]:{WIDTH{1'd0}};
        
        // C        
                C_nosxnos[int_i4][int_j4] = (int_i4<noo)?C[int_i4][int_j4]:{WIDTH{1'd0}};
        
        // C^T
                j[int_i4][int_j4] = C_nosxnos[int_j4][int_i4];
        
        // A^T        
                d[int_i4][int_j4] = A[int_j4][int_i4];
            end
        /////////////////////////////////////////////////////////////////////////



		///////////////////////////////////INVERTIR/////////////////////////////////////////////////

        if(end_inv) t_next = matrix_inv;
        else t_next = t;
		////////////////////////////////////////////////////////////////////////////////////

        //Calculate matrix_mult        
        if(end_mult) matrix_mult_next = matrix_AxBxC;
        else matrix_mult_next = matrix_mult;
		////////////////////////////////////////////////////////////////////////////////////
		
    end
    


    always_ff @(posedge clk)
    begin
		if(clk_en) 
		begin
			state <= (reset)?IDLE:stateNext;
			g <= (reset)?P0:g_next;
			c <= (reset)?P0:c_next;
			prev_matrix_inversion<= prev_matrix_inversion_next;
			t <= t_next;
			t2 <= t2_next;
			matrix_en3 <= matrix_en3_next;
			matrix_mult <= matrix_mult_next;
		end
		else
		begin
			state <= state;
			g <= g;
			c <= c;
			prev_matrix_inversion<= prev_matrix_inversion;
			t <= t;
			t2 <= t2;
			matrix_en3 <= matrix_en3;
			matrix_mult <= matrix_mult;
		end
	end
    
endmodule
