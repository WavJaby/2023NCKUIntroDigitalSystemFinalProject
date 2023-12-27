module key_pad (
    input clk,
    input rst,
    input [3:0] keypadCol,
    output reg [3:0] keypadRow,
    output reg [3:0] keypadoutput0,
    output reg [3:0] keypadoutput1,
    output reg [3:0] keypadoutput2,
    output reg [3:0] keypadoutput3,
    output reg available
);
    reg [15:0] keypadBuf;
    reg [31:0] keyadDelay;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            keypadRow  <= 4'b1110;
            keypadBuf  <= 16'd0;
            keyadDelay <= 32'd0;
        end else begin
            if (keyadDelay == 32'd500000) begin
                keyadDelay <= 0;
                if (keypadRow == 8'b1110) begin
                    available = 1'd1;
                    keypadoutput0 = keypadBuf[3:0];
                    keypadoutput1 = keypadBuf[7:4];
                    keypadoutput2 = keypadBuf[11:8];
                    keypadoutput3 = keypadBuf[15:12];
                    keypadBuf = 16'd0;
                end
                available = 1'd0;
                case (keypadRow)
                    8'b1110: keypadBuf = keypadBuf | {12'b0, ~keypadCol} << 0;
                    8'b1101: keypadBuf = keypadBuf | {12'b0, ~keypadCol} << 4;
                    8'b1011: keypadBuf = keypadBuf | {12'b0, ~keypadCol} << 8;
                    8'b0111: keypadBuf = keypadBuf | {12'b0, ~keypadCol} << 12;
                endcase
                case (keypadRow)
                    4'b1110: keypadRow = 4'b1101;
                    4'b1101: keypadRow = 4'b1011;
                    4'b1011: keypadRow = 4'b0111;
                    4'b0111: keypadRow = 4'b1110;
                    default: keypadRow = 4'b1110;
                endcase
            end else keyadDelay <= keyadDelay + 1;
        end
    end
endmodule
