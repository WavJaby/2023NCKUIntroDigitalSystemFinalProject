module six_digit_seven_display (
    input  [31:0] number,
    output [ 6:0] sevenDisp0,
    output [ 6:0] sevenDisp1,
    output [ 6:0] sevenDisp2,
    output [ 6:0] sevenDisp3,
    output [ 6:0] sevenDisp4,
    output [ 6:0] sevenDisp5
);
    seven_display seven0 (
        (number % 10),
        sevenDisp0
    );
    seven_display seven1 (
        (number / 10) % 10,
        sevenDisp1
    );
    seven_display seven2 (
        (number / 100) % 10,
        sevenDisp2
    );
    seven_display seven3 (
        (number / 1000) % 10,
        sevenDisp3
    );
    seven_display seven4 (
        (number / 10000) % 10,
        sevenDisp4
    );
    seven_display seven5 (
        (number / 100000) % 10,
        sevenDisp5
    );
endmodule

module seven_display (
    input [3:0] count,
    output reg [6:0] OUT
);
    always @(count) begin
        case (count)
            4'h0: OUT = 7'b1000000;
            4'h1: OUT = 7'b1111001;
            4'h2: OUT = 7'b0100100;
            4'h3: OUT = 7'b0110000;
            4'h4: OUT = 7'b0011001;
            4'h5: OUT = 7'b0010010;
            4'h6: OUT = 7'b0000010;
            4'h7: OUT = 7'b1111000;
            4'h8: OUT = 7'b0000000;
            4'h9: OUT = 7'b0011000;
            4'hA: OUT = 7'b0001000;
            4'hB: OUT = 7'b0000011;
            4'hC: OUT = 7'b1000110;
            4'hD: OUT = 7'b0100001;
            4'hE: OUT = 7'b0000110;
            4'hF: OUT = 7'b0001110;
        endcase
    end

endmodule
