`include "src/define.v"
`include "src/resources_define.v"

module resource (
    output reg [`rom0Length-1:0] imageDataOut
);
    reg [`rom0Length-1:0] imageData[0:0];
    initial begin
        $readmemh("resources/rom0.hex", imageData);
        imageDataOut <= imageData[0];
    end
endmodule
