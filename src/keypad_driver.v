module keypad_driver (
    input clk,
    input rst,
    input [3:0] keypadCol,
    output reg [3:0] keypadRowRequest,
    output reg [3:0] keypadRowRequest0 = 4'd0,
    output reg [3:0] keypadRowRequest1 = 4'd0,
    output reg [3:0] keypadRowRequest2 = 4'd0,
    output reg [3:0] keypadRowRequest3 = 4'd0
);
    reg [31:0] keyadDelay;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            keypadRowRequest <= 4'b1110;
            keyadDelay <= 32'd0;
            keypadRowRequest0 <= 4'd0;
            keypadRowRequest1 <= 4'd0;
            keypadRowRequest2 <= 4'd0;
            keypadRowRequest3 <= 4'd0;
        end else begin
            if (keyadDelay == 32'd500000) begin
                keyadDelay <= 0;
                case (keypadRowRequest)
                    8'b1110: keypadRowRequest0 <= ~keypadCol;
                    8'b1101: keypadRowRequest1 <= ~keypadCol;
                    8'b1011: keypadRowRequest2 <= ~keypadCol;
                    8'b0111: keypadRowRequest3 <= ~keypadCol;
                endcase
                case (keypadRowRequest)
                    4'b1110: keypadRowRequest = 4'b1101;
                    4'b1101: keypadRowRequest = 4'b1011;
                    4'b1011: keypadRowRequest = 4'b0111;
                    4'b0111: keypadRowRequest = 4'b1110;
                    default: keypadRowRequest = 4'b1110;
                endcase
            end else keyadDelay <= keyadDelay + 1;
        end
    end
endmodule
