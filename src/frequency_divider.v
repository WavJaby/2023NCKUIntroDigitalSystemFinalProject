module frequency_divider (
    clk,
    rst,
    freq,
    clock_div
);
    input rst, clk;
    input [31:0] freq;
    output reg clock_div;
    reg [31:0] count;

    always @(posedge clk) begin
        if (!rst) begin
            count <= 32'd0;
            clock_div <= 1'b0;
        end else begin
            if (count == freq) begin
                count <= 32'd0;
                clock_div <= ~clock_div;
            end else begin
                count <= count + 32'd1;
            end
        end
    end
endmodule