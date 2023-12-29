`include "src/vga_driver.v"
`include "src/seven_display.v"

`define DEBUG

`define ScreenWidth

`define objectX 16
`define objectY 16
`define objectW 16
`define objectH 16

`define objectXStart 0
`define objectYStart (`objectXStart + `objectX)
`define objectWStart (`objectYStart + `objectY)
`define objectHStart (`objectWStart + `objectW)
`define objectDataLen (`objectHStart + `objectH)

`define imageBitdepth 16

module project (
    input clk,
    input rst,

    output reg [3:0] Red,
    output reg [3:0] Green,
    output reg [3:0] Blue,
    output H_SYNC,
    output V_SYNC,
    input [2:0] button,
    output wire [6:0] sevenDisp0,
    output wire [6:0] sevenDisp1,
    output wire [6:0] sevenDisp2,
    output wire [6:0] sevenDisp3,
    output wire [6:0] sevenDisp4,
    output wire [6:0] sevenDisp5
);
    wire [31:0] frameCount;
    seven_display seven0 (
        (frameCount % 10),
        sevenDisp0
    );
    seven_display seven1 (
        (frameCount / 10) % 10,
        sevenDisp1
    );
    seven_display seven2 (
        (frameCount / 100) % 10,
        sevenDisp2
    );
    seven_display seven3 (
        (frameCount / 1000) % 10,
        sevenDisp3
    );
    seven_display seven4 (
        (frameCount / 10000) % 10,
        sevenDisp4
    );
    seven_display seven5 (
        (frameCount / 100000) % 10,
        sevenDisp5
    );

    wire available, nextFrame;
    wire [15:0] pixX;
    wire [15:0] pixY;
    vga_driver vga (
        rst,
        clk,
        H_SYNC,
        V_SYNC,
        available,
        nextFrame,
        pixX,
        pixY,
        frameCount
    );

    parameter ScreenWidth = 16'd640, ScreenHeight = 16'd480;

    // reg [31:0] ballPosX = ScreenWidth / 2;
    // reg [31:0] ballPosY = ScreenHeight / 2;
    // reg [31:0] ballRidus = 20;
    // reg [31:0] ballVelX = 10;
    // reg [31:0] ballVelY = 10;

    parameter imgWidth = 16'd50, imgHeight = 16'd67;
    reg [31:0] imgPosX = 32'd0;
    reg [31:0] imgPosY = 32'd0;
    reg [31:0] imgVelX = 32'd2;
    reg [31:0] imgVelY = 32'd2;
    reg [imgWidth*`imageBitdepth-1:0] imageData[0:imgHeight-1];
    reg [imgWidth*`imageBitdepth-1:0] imageData2[0:imgHeight-1];

    initial begin
        $readmemh("resources/tree001.hex", imageData, 0);
        $readmemh("resources/tree002.hex", imageData2, 0);
    end

    reg [3:0] redCache = 4'd0;
    reg [3:0] greenCache = 4'd0;
    reg [3:0] blueCache = 4'd0;
    reg pixDraw = 1'd0;
    reg [`imageBitdepth-1:0] pixColor = `imageBitdepth'd0;
    always @(pixX or pixY) begin : screen
        if (!available) begin
            Red   <= 4'd0;
            Green <= 4'd0;
            Blue  <= 4'd0;
            disable screen;
        end

        // if (abs(
        //         pixX - ballPosX
        //     ) * abs(
        //         pixX - ballPosX
        //     ) + abs(
        //         pixY - ballPosY
        //     ) * abs(
        //         pixY - ballPosY
        //     ) < (ballRidus * ballRidus)) begin

        pixDraw = 1'd0;
        redCache = 4'd0;
        greenCache = 4'd0;
        blueCache = 4'd0;
        if ((pixX >= imgPosX) && (pixX < imgPosX + (imgWidth << 1)) && 
            (pixY >= imgPosY) && (pixY < imgPosY + (imgHeight << 1))) begin
            if ((frameCount >> 4) & 1'b1)
                pixColor = imageData[(pixY-imgPosY)>>1] >> ((imgWidth - (((pixX-imgPosX)>>1)+1)) * `imageBitdepth);
            else
                pixColor = imageData2[(pixY-imgPosY)>>1] >> ((imgWidth - (((pixX-imgPosX)>>1)+1)) * `imageBitdepth);
            if (pixColor) begin
                redCache = ((pixColor >> 12 & 4'b1111) * (pixColor & 4'b1111)) >> 4;
                greenCache = ((pixColor >> 8 & 4'b1111) * (pixColor & 4'b1111)) >> 4;
                blueCache = ((pixColor >> 4 & 4'b1111) * (pixColor & 4'b1111)) >> 4;
                pixDraw = 1;
            end
        end

        // if (abs(pixX - ballPosX) < ballRidus && abs(pixY - ballPosY) < ballRidus) begin
        //     Red   <= 4'b1111;
        //     Green <= 4'b1111;
        //     Blue  <= 4'b1111;
        //     pixDraw = 1;
        // end

`ifdef DEBUG
        if (!pixDraw) begin
            if (pixX == 0 && pixY == 0) begin
                redCache = 4'b1111;
                greenCache = 4'b1111;
                blueCache = 4'b1111;
                pixDraw = 1;
            end else if (pixX == 639 && pixY == 479) begin
                redCache = 4'b1111;
                greenCache = 4'b1111;
                blueCache = 4'b1111;
                pixDraw = 1;
            end else if (pixX == 0 || pixX == 639) begin
                redCache = 4'b1111;
                greenCache = 4'b0000;
                blueCache = 4'b0000;
                pixDraw = 1;
            end else if (pixY == 0 || pixY == 479) begin
                redCache = 4'b0000;
                greenCache = 4'b1111;
                blueCache = 4'b0000;
                pixDraw = 1;
            end
        end
`endif
        Red   <= redCache;
        Green <= greenCache;
        Blue  <= blueCache;
    end

    integer nowX, nowY;
    always @(posedge frameCount) begin : frame
        // ballPosX <= ballPosX + ballVelX;
        // ballPosY <= ballPosY + ballVelY;
        // if (ballPosX + ballVelX > ScreenWidth - ballRidus || ballPosX + ballVelX < ballRidus) begin
        //     ballVelX <= 0 - ballVelX;
        // end
        // if (ballPosY + ballVelY > ScreenHeight - ballRidus || ballPosY + ballVelY < ballRidus) begin
        //     ballVelY <= 0 - ballVelY;
        // end

        if (!rst) begin
            imgPosX <= 0;
            imgPosY <= 0;
            disable frame;
        end

        nowX = imgPosX + imgVelX;
        nowY = imgPosY + imgVelY;
        imgPosX <= nowX;
        imgPosY <= nowY;
        if (nowX < 0) begin
            imgVelX <= 0 - imgVelX;
            imgPosX <= 0;
        end
        if (nowX + (imgWidth << 1) > ScreenWidth) begin
            imgVelX <= 0 - imgVelX;
            imgPosX <= ScreenWidth - (imgWidth << 1);
        end
        if (nowY < 0) begin
            imgVelY <= 0 - imgVelY;
            imgPosY <= 0;
        end
        if (nowY + (imgHeight << 1) > ScreenHeight) begin
            imgVelY <= 0 - imgVelY;
            imgPosY <= ScreenHeight - (imgHeight << 1);
        end
    end


    function [31:0] abs;
        input [31:0] in;
        if (in[31]) abs = 1 + ~in;
        else abs = in;
    endfunction
endmodule
