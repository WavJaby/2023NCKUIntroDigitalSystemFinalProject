`include "./src/resources_define.v"

module random (
    input clk,
    output reg [`randomLen-1:0] randoms
);
    reg [`randomLen-1:0] lfsr = `randomList;

    always @(posedge clk) begin
        lfsr <= lfsr << 1;
        lfsr[0] <= lfsr[`randomLen-1] ^ lfsr[`randomLen-2];
        randoms <= lfsr;
    end
endmodule
