`include "src/resources_define.v"

module resource (
    output reg [`rom0Length-1:0] imageDataOut,
    output reg [`fontLength-1:0] fontDataOut
);
    reg [`rom0Length-1:0] imageData[0:0];
    reg [`fontLength-1:0] fontData[0:0];
    initial begin
        $readmemh("resources/rom0.hex", imageData);
        imageDataOut <= imageData[0];

        $readmemb("resources/font.hex", fontData);
        fontDataOut <= fontData[0];
    end
endmodule
