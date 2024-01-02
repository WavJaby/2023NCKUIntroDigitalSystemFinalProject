module dot_display (
    input clk,  //original clk
    input rst,
    input [1:0] light_state,
    output reg [7:0] dot_row,
    output reg [7:0] dot_col0,
    output reg [7:0] dot_col1
);
    reg [31:0] freq;
    reg [ 2:0] count;
    always @(posedge clk) begin
        if (freq == 5000) begin
            case (count)
                3'd0: dot_row <= 8'b01111111;
                3'd1: dot_row <= 8'b10111111;
                3'd2: dot_row <= 8'b11011111;
                3'd3: dot_row <= 8'b11101111;
                3'd4: dot_row <= 8'b11110111;
                3'd5: dot_row <= 8'b11111011;
                3'd6: dot_row <= 8'b11111101;
                3'd7: dot_row <= 8'b11111110;
            endcase
            if (light_state == 2'd0) begin  //both dark mode
                dot_col0 <= 8'b00000000;
                dot_col1 <= 8'b00000000;
            end else if (light_state == 2'd1) begin  // board become large 
                dot_col1 <= 8'b00000000;
                case (count)
                    3'd0: dot_col0 <= 8'b00000000;
                    3'd1: dot_col0 <= 8'b00100100;
                    3'd2: dot_col0 <= 8'b01000010;
                    3'd3: dot_col0 <= 8'b11111111;
                    3'd4: dot_col0 <= 8'b01000010;
                    3'd5: dot_col0 <= 8'b00100100;
                    3'd6: dot_col0 <= 8'b00000000;
                    3'd7: dot_col0 <= 8'b11111111;
                endcase
            end else if (light_state == 2'd2) begin  //speed up
                dot_col0 <= 8'b00000000;
                case (count)
                    3'd0: dot_col1 <= 8'b00011000;
                    3'd1: dot_col1 <= 8'b00011000;
                    3'd2: dot_col1 <= 8'b00011000;
                    3'd3: dot_col1 <= 8'b11111111;
                    3'd4: dot_col1 <= 8'b11111111;
                    3'd5: dot_col1 <= 8'b00011000;
                    3'd6: dot_col1 <= 8'b00011000;
                    3'd7: dot_col1 <= 8'b00011000;
                endcase
            end else if (light_state == 2'd3) begin  //speed up and board become large
                case (count)
                    3'd0: dot_col0 <= 8'b00000000;
                    3'd1: dot_col0 <= 8'b00100100;
                    3'd2: dot_col0 <= 8'b01000010;
                    3'd3: dot_col0 <= 8'b11111111;
                    3'd4: dot_col0 <= 8'b01000010;
                    3'd5: dot_col0 <= 8'b00100100;
                    3'd6: dot_col0 <= 8'b00000000;
                    3'd7: dot_col0 <= 8'b11111111;
                endcase
                case (count)
                    3'd0: dot_col1 <= 8'b00011000;
                    3'd1: dot_col1 <= 8'b00011000;
                    3'd2: dot_col1 <= 8'b00011000;
                    3'd3: dot_col1 <= 8'b11111111;
                    3'd4: dot_col1 <= 8'b11111111;
                    3'd5: dot_col1 <= 8'b00011000;
                    3'd6: dot_col1 <= 8'b00011000;
                    3'd7: dot_col1 <= 8'b00011000;
                endcase
            end
            count <= count + 1;
            freq  <= 0;
        end else begin
            freq <= freq + 1;
        end
    end
endmodule
