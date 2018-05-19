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
    
    localparam IDLE = 4'd0;
    localparam INVERSION0 = 4'd1;
    localparam ENDINV0 = 4'd2;
    localparam INVERSION1 = 4'd3;
    localparam ENDINV1 = 4'd4;
    localparam INVERSION2 = 4'd5;
    localparam ENDINV2 = 4'd6;
    localparam INVERSION3 = 4'd7;
    localparam ENDINV3 = 4'd8;
    localparam ENDINV = 4'd9;
    
    logic [3:0] state = 4'd0, stateNext;
    
    logic [WIDTH-1:0] ResNext[0:1][0:1];
    
    logic [WIDTH-1:0] dividend;
    logic [WIDTH-1:0] divisor;
    
    logic div_valid;
    logic [31:0] div_data;
    logic t_valid;
    assign t_valid = ((state == INVERSION0)||(state == INVERSION1)||(state == INVERSION2)||(state == INVERSION3));
    assign endInv = (state == ENDINV);
    
    div_gen_1 Div(
            .aclk(clk),
            .s_axis_dividend_tdata(dividend), //16 bits
            .s_axis_dividend_tvalid(t_valid), //1 bit
            .s_axis_divisor_tdata(divisor), //16 bits
            .s_axis_divisor_tvalid(t_valid), //1 bit
            .m_axis_dout_tdata(div_data), //32 bits
            .m_axis_dout_tvalid(div_valid) //1 bit
        );
    
    always_comb
    begin
        case(state)
            IDLE: stateNext = (startInv)?INVERSION0:IDLE;
            INVERSION0: stateNext = (div_valid)?ENDINV0:INVERSION0;
            ENDINV0: stateNext = (~div_valid)?INVERSION1:ENDINV0;
            INVERSION1: stateNext = (div_valid)?ENDINV1:INVERSION1;
            ENDINV1: stateNext = (~div_valid)?INVERSION2:ENDINV1;
            INVERSION2: stateNext = (div_valid)?ENDINV2:INVERSION2;
            ENDINV2: stateNext = (~div_valid)?INVERSION3:ENDINV2;
            INVERSION3: stateNext = (div_valid)?ENDINV3:INVERSION3;
            ENDINV3: stateNext = (~div_valid)?ENDINV:ENDINV3;
            ENDINV: stateNext = IDLE;
            default: stateNext = IDLE;
        endcase
        if(state == IDLE) divisor = 16'd1;
        else divisor = ($signed(A[0][0]) * $signed(A[1][1]))-($signed(A[0][1]) * $signed(A[1][0]));
        
        case(state)
            INVERSION0, ENDINV0: dividend = A[1][1];
            INVERSION1, ENDINV1: dividend = -A[0][1];
            INVERSION2, ENDINV2: dividend = -A[1][0];       
            INVERSION3, ENDINV3: dividend = A[0][0];
            default: dividend = 16'd0;
        endcase
        
        if(state == ENDINV0) ResNext[0][0] = div_data[31:16];
        else ResNext[0][0] = Res[0][0];
        
        if(state == ENDINV1) ResNext[0][1] = div_data[31:16];
        else ResNext[0][1] = Res[0][1];
        
        if(state == ENDINV2) ResNext[1][0] = div_data[31:16];
        else ResNext[1][0] = Res[1][0];
        
        if(state == ENDINV3) ResNext[1][1] = div_data[31:16];
        else ResNext[1][1] = Res[1][1];
    end
    always_ff@(posedge clk)
    begin
        Res <= ResNext;
        state <= stateNext;
    end
endmodule
