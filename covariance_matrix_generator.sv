`timescale 1ns / 1ps
module covariance_matrix_generator #(
        parameter WIDTH = 16,
        parameter nos = 4,//number of states
        parameter noo = 2 //number of outputs
    )(
    input logic clk,
    input logic reset,
    input logic restartCalculation,
    input logic Start_K_G,
    input logic [WIDTH-1:0] Fdnk [0:nos-1][0:nos-1], // 4x4
    input logic [WIDTH-1:0] H [0:noo-1][0:nos-1], // 2x4
    input logic [WIDTH-1:0] Q [0:nos-1][0:nos-1], //
    input logic [WIDTH-1:0] R [0:noo-1][0:noo-1], //
    input logic [WIDTH-1:0] P0 [0:nos-1][0:nos-1],

    output logic [WIDTH-1:0] t2 [0:nos-1][0:noo-1], // 4x2 K(nk)
    output logic end_K_G,
    output logic end_Pnk
    );
    
    localparam IDLE = 4'd15;//Waiting for starting signal
    localparam STATE0 = 4'd0;//Multiplicate Fdnk x c x d
    localparam STATE1 = 4'd1;//Finish multiplication
    localparam STATE2 = 4'd2;//Calculate g
    localparam STATE3 = 4'd3;//Multiplicate H x g x j
    localparam STATE4 = 4'd4;//Finish multiplication
    localparam STATE5 = 4'd5;//Inverse to calculate t
    localparam STATE6 = 4'd6;//Finish inversion
    localparam STATE7 = 4'd7;//Multiplicate g x j x t
    localparam STATE8 = 4'd8;//Calculate t2
    localparam STATE9 = 4'd9;//Multiplicate t2 x H x g
    localparam STATE10 = 4'd10;//Finish multiplication
    localparam STATE11 = 4'd11;//Calculate matrix_en2
    localparam STATE12 = 4'd12;//Calculate c
        
    logic en0, en1, en2, en3, Start_mult, Start_inv;
    logic [1:0] Sel;
    logic [3:0] state = IDLE, stateNext;
        
    //logic end_mult, end_inv;
    logic [WIDTH-1:0] g [0:nos-1][0:nos-1]; // 4x4 P(nk/nk-1)
    logic [WIDTH-1:0] c [0:nos-1][0:nos-1]; // 4x4 P(nk-1/nk-1)        
    // Matrix intermedias
    logic [WIDTH-1:0] t [0:noo-1][0:noo-1]; // 2x2
    logic [WIDTH-1:0] t_next [0:noo-1][0:noo-1]; // 2x2
    
    logic [WIDTH-1:0] g_next [0:nos-1][0:nos-1]; // 4x4
    
    
    logic [WIDTH-1:0] c_next [0:nos-1][0:nos-1]; // 4x4
    
    logic [WIDTH-1:0] t2_next [0:nos-1][0:noo-1]; // 4x2
    logic [WIDTH-1:0] A [0:nos-1][0:nos-1]; // 4x4
    logic [WIDTH-1:0] B [0:nos-1][0:nos-1]; // 4x4
    logic [WIDTH-1:0] C [0:nos-1][0:nos-1]; // 4x4
    logic [WIDTH-1:0] matrix_en2 [0:nos-1][0:nos-1];
    logic [WIDTH-1:0] matrix_en2_next [0:nos-1][0:nos-1];
    logic [WIDTH-1:0] j [0:nos-1][0:nos-1]; //4x4
    logic [WIDTH-1:0] d [0:nos-1][0:nos-1]; //4x4
    logic [WIDTH-1:0] t_nosxnos [0:nos-1][0:nos-1]; //4x4
    logic [WIDTH-1:0] t2_nosxnos [0:nos-1][0:nos-1]; //4x4
    logic [WIDTH-1:0] H_nosxnos [0:nos-1][0:nos-1]; //4x4
        
    //Resultado multiplicacion
    logic [WIDTH-1:0] matrix_AxB [0:nos-1][0:nos-1];
    logic [WIDTH-1:0] matrix_AxBxC [0:nos-1][0:nos-1];
    logic [WIDTH-1:0] matrix_mult [0:nos-1][0:nos-1]; //4x4
    logic [WIDTH-1:0] matrix_mult_next [0:nos-1][0:nos-1]; //4x4
    
    //Resultado inversion
    logic [WIDTH-1:0] prev_matrix_inversion [0:noo-1][0:noo-1];

    logic [WIDTH-1:0] matrix_mult_in_1 [0:nos-1][0:nos-1];
    logic [WIDTH-1:0] matrix_mult_in_2 [0:nos-1][0:nos-1];
    
    Matrix_mult_2 #(.WIDTH(WIDTH), .nos(nos)) mult_AxBxC(.A1(matrix_mult_in_1), .B1(matrix_mult_in_2), .Res1(matrix_AxBxC));
    //Matrix_mult_2 #(.WIDTH(WIDTH), .nos(nos)) mutl_AxBxC(.A1(matrix_AxB), .B1(C), .Res1(matrix_AxBxC));
    
    integer int_i1, int_i2, int_i3, int_i4, int_i5, int_i6, int_i7;
    integer int_j1, int_j2, int_j3, int_j4, int_j5, int_j6, int_j7;
    
    logic [WIDTH-1:0] determinant;
    assign determinant = $signed(prev_matrix_inversion[0][0])*$signed(prev_matrix_inversion[1][1]) - $signed(prev_matrix_inversion[0][1])*$signed(prev_matrix_inversion[1][0]);
    assign end_K_G = (state == STATE8);
    assign end_Pnk = (state == STATE12);
    always_comb
    begin
        
        //State Machine
        
        case(state)
            IDLE: stateNext = (Start_K_G)?STATE0:IDLE;
            STATE0: stateNext = STATE1;
            STATE1: stateNext = STATE2;//(end_mult)?STATE2:STATE1;
            STATE2: stateNext = STATE3;
            STATE3: stateNext = STATE4;
            STATE4: stateNext = STATE5;//(end_mult)?STATE5:STATE4;
            STATE5: stateNext = STATE6;//(end_inv)?STATE6:STATE5;
            //STATE5_2: stateNext = STATE6;
            STATE6: stateNext = STATE7;
            STATE7: stateNext = STATE8;//(end_mult)?STATE8:STATE7;
            STATE8: stateNext = STATE9;
            STATE9: stateNext = STATE10;
            STATE10: stateNext = STATE11;//(end_mult)?STATE11:STATE10;
            STATE11: stateNext = STATE12;
            STATE12: stateNext = (restartCalculation)?STATE1:STATE12;
            default: stateNext = IDLE;
        endcase
        
        //Set Start_mult, Start_inv, en0, en1, en2, en3, Sel
        
        case(state)
            IDLE: begin
                {Start_mult, Start_inv} = 2'b00;
                {en3, en2, en1, en0} = 4'd0;
                Sel = 2'd0;
            end
            STATE0: begin
                {Start_mult, Start_inv} = 2'b10;
                {en3, en2, en1, en0} = 4'd0;
                Sel = 2'd0;
            end
            STATE1: begin
                {Start_mult, Start_inv} = 2'b10;
                {en3, en2, en1, en0} = 4'd0;
                Sel = 2'd0;
            end
            STATE2: begin
                {Start_mult, Start_inv} = 2'b00;
                {en3, en2, en1, en0} = 4'b0001;
                Sel = 2'd0;
            end
            STATE3: begin
                {Start_mult, Start_inv} = 2'b10;
                {en3, en2, en1, en0} = 4'd0;
                Sel = 2'd1;
            end
            STATE4: begin
                {Start_mult, Start_inv} = 2'b10;
                {en3, en2, en1, en0} = 4'd0;
                Sel = 2'd1;
            end
            STATE5: begin
                {Start_mult, Start_inv} = 2'b01;
                {en3, en2, en1, en0} = 4'd0;
                Sel = 2'd1;
            end
            STATE6: begin
                {Start_mult, Start_inv} = 2'b00;
                {en3, en2, en1, en0} = 4'd0;
                Sel = 2'd2;
            end
            STATE7: begin
                {Start_mult, Start_inv} = 2'b00;
                {en3, en2, en1, en0} = 4'd0;
                Sel = 2'd2;
            end
            STATE8: begin
                {Start_mult, Start_inv} = 2'b00;
                {en3, en2, en1, en0} = 4'b0010;
                Sel = 2'd2;
            end
            STATE9: begin
                {Start_mult, Start_inv} = 2'b10;
                {en3, en2, en1, en0} = 4'd0;
                Sel = 2'd3;
            end
            STATE10: begin
                {Start_mult, Start_inv} = 2'b10;
                {en3, en2, en1, en0} = 4'd0;
                Sel = 2'd3;
            end
            STATE11: begin
                {Start_mult, Start_inv} = 2'b00;
                {en3, en2, en1, en0} = 4'b0100;
                Sel = 2'd3;
            end
            STATE12: begin
                {Start_mult, Start_inv} = 2'b00;
                {en3, en2, en1, en0} = 4'b1000;
                Sel = 2'd3;
            end
            default: begin
                {Start_mult, Start_inv} = 2'b00;
                {en3, en2, en1, en0} = 4'd0;
                Sel = 2'd0;
            end
        endcase
        
        //Assign previous matrix inversion elements
        
        for (int_i1=0; int_i1 < noo; int_i1++)
            for(int_j1=0; int_j1 < noo; int_j1++)
                prev_matrix_inversion[int_i1][int_j1] = matrix_mult[int_i1][int_j1] + R[int_i1][int_j1];
        
        //Set C
        
        case(Sel)
            2'd0: C = d;
            2'd1: C = j;
            2'd2: C = t_nosxnos;
            default: C = g;
        endcase
        
        //Set B
        
        case(Sel)
            2'd0: B = c;
            2'd1: B = g;
            2'd2: B = j;
            default: B = H_nosxnos;
        endcase
        
        //Set A
        
        case(Sel)
            2'd0: A = Fdnk;
            2'd1: A = H_nosxnos;
            2'd2: A = g;
            default: A = t2_nosxnos;
        endcase
        
        //Assign matrix multiplication module inputs
        
        case(state)
            STATE0, STATE3, STATE9:
            begin
                matrix_mult_in_1 = A;
                matrix_mult_in_2 = B;
            end
            STATE1, STATE4, STATE10:
            begin
                matrix_mult_in_1 = matrix_mult;
                matrix_mult_in_2 = C;
            end
            default:
            begin
                matrix_mult_in_1 = A;
                matrix_mult_in_2 = B;
            end
        endcase
        
        //Calculate matrix_mult
        
        if(Start_mult)
        begin
            matrix_mult_next = matrix_AxBxC;
        end
        else matrix_mult_next = matrix_mult;

        //----------------------------------------

        for (int_i3=0; int_i3 < nos; int_i3++)
            for(int_j3=0; int_j3 < nos; int_j3++)
            begin
            
        //Calculate c
            
                c_next[int_i3][int_j3] = (en3)?(matrix_en2[int_i3][int_j3] + matrix_en2[int_j3][int_i3])>>1:c[int_i3][int_j3];
                
        //Calculate matrix_en2
                
                matrix_en2_next[int_i3][int_j3] = (en2)?g[int_i3][int_j3] - matrix_mult[int_i3][int_j3]:matrix_en2[int_i3][int_j3];
            end
            
        //Calculate t2

        for (int_i4=0; int_i4 < nos; int_i4++)
            for(int_j4=0; int_j4 < noo; int_j4++)
                t2_next[int_i4][int_j4] = (en1)?matrix_mult[int_i4][int_j4]:t2[int_i4][int_j4];

        
        //Calculate t

        t_next[0][0] = (Start_inv)?{{WIDTH-1{1'd0}}, 1'd1}:t[0][0];//$signed(prev_matrix_inversion[1][1])/$signed(determinant):t[0][0];
        t_next[0][1] = (Start_inv)?{WIDTH{1'd0}}:t[0][1];//$signed(~prev_matrix_inversion[0][1] + {{WIDTH-1{1'd0}}, 1'd1})/$signed(determinant):t[0][1];
        t_next[1][0] = (Start_inv)?{WIDTH{1'd0}}:t[1][0];//$signed(~prev_matrix_inversion[1][0] + {{WIDTH-1{1'd0}}, 1'd0})/$signed(determinant):t[1][0];
        t_next[1][1] = (Start_inv)?{{WIDTH-1{1'd0}}, 1'd1}:t[1][1];//$signed(prev_matrix_inversion[0][0])/$signed(determinant):t[1][1];
    
        //Calculate g

        for (int_i5=0; int_i5 < nos; int_i5++)
            for(int_j5=0; int_j5 < nos; int_j5++)
                g_next[int_i5][int_j5] = (en0)?matrix_mult[int_i5][int_j5] + Q[int_i5][int_j5]:g[int_i5][int_j5];

        //-----------------------------------------
        
        for (int_i6=0; int_i6 < nos; int_i6++)
            for(int_j6=0; int_j6 < nos; int_j6++)
            begin
            
        //Fit t
            
                t_nosxnos[int_i6][int_j6] = ((int_i6<noo)&&(int_j6<noo))?t[int_i6][int_j6]:{WIDTH{1'd0}};
        
        //Fit t2
        
                t2_nosxnos[int_i6][int_j6] = (int_j6<noo)?t2[int_i6][int_j6]:{WIDTH{1'd0}};
        
        //Fit H
        
                H_nosxnos[int_i6][int_j6] = (int_i6<noo)?H[int_i6][int_j6]:{WIDTH{1'd0}};
        
        //Calculate j
        
                j[int_i6][int_j6] = H_nosxnos[int_j6][int_i6];
        
        //Calculate d
        
                d[int_i6][int_j6] = Fdnk[int_j6][int_i6];
            end
    end
    
    always_ff @(posedge clk)
    begin
        state <= (reset)?IDLE:stateNext;
        matrix_mult <= matrix_mult_next;
        matrix_en2 <= matrix_en2_next;
        t2 <= t2_next;
        g <= g_next;
        t <= t_next;
        c <= (reset)?P0:c_next;
    end
    
endmodule
