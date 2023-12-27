`include "src/define.v"
`include "src/vga_driver.v"
`include "src/seven_display.v"
`include "src/resource.v"
`include "src/resources_define.v"

`define DEBUG
`define NOCHIPI

`define objX 12
`define objY 12
`define objW 12
`define objH 12
`define objImgId 8

`define objXStart 0
`define objYStart (`objXStart+`objX)
`define objWStart (`objYStart+`objY)
`define objHStart (`objWStart+`objW)
`define objImgIdStart (`objHStart+`objH)
`define objDataLen (`objImgIdStart+`objImgId)
`define objCount 10

`define getObjX(index) [index*`objDataLen+`objXStart +: `objX]
`define getObjY(index) [index*`objDataLen+`objYStart +: `objY]
`define getObjW(index) [index*`objDataLen+`objWStart +: `objW]
`define getObjH(index) [index*`objDataLen+`objHStart +: `objH]
`define getObjImg(index) [index*`objDataLen+`objImgIdStart +: `objImgId]

module project (
    input clk,
    input rst,
    input [3:0] button,

    output reg [3:0] Red,
    output reg [3:0] Green,
    output reg [3:0] Blue,
    output H_SYNC,
    output V_SYNC,
    output wire [6:0] sevenDisp0,
    output wire [6:0] sevenDisp1,
    output wire [6:0] sevenDisp2,
    output wire [6:0] sevenDisp3,
    output wire [6:0] sevenDisp4,
    output wire [6:0] sevenDisp5
);
    `include "src/lib/math.v"
    wire available;
    wire nextFrame;
    wire [15:0] pixX;
    wire [15:0] pixY;
    wire [31:0] frameCount;
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

    reg [`objDataLen*`objCount-1:0] gameObjs;
    wire [`rom0Length-1:0] imageData;
    resource res (imageData);


    parameter testPtr = 0, ballPtr = 1, p1Ptr = 2, p2Ptr = 3;
    reg [31:0] p1Speed = 6;
    reg [31:0] p2Speed = 6;

    reg signed [31:0] ballVelX = 5;
    reg signed [31:0] ballVelY = 5;

    parameter slabWidth = 12'd8, slabDefaultLen = 12'd80, slabDefaultOffset = 12'd40;

`ifndef NOCHIPI
    parameter chipiWidth = 16'd64, chipiHeight = 16'd64, chipiTotalBit = chipiWidth*chipiHeight*`imageBitdepth;
    reg [31:0] chipiPosX = (ScreenWidth >> 1) - chipiWidth;
    reg [31:0] chipiPosY = (ScreenHeight >> 1) - chipiHeight;
    reg [chipiWidth*`imageBitdepth-1:0] chipiData0[0:chipiHeight-1];
    reg [chipiWidth*`imageBitdepth-1:0] chipiData1[0:chipiHeight-1];
    reg [chipiWidth*`imageBitdepth-1:0] chipiData2[0:chipiHeight-1];
    reg [chipiWidth*`imageBitdepth-1:0] chipiData3[0:chipiHeight-1];
    reg [chipiWidth*`imageBitdepth-1:0] chipiData4[0:chipiHeight-1];
    reg [2:0] chipiFrame = 0;
    reg chipiDir = 1;
    reg [31:0] chipiDiv = 0;
    initial begin
        $readmemh("resources/chipi/chipi-chipi_0.hex", chipiData0);
        $readmemh("resources/chipi/chipi-chipi_1.hex", chipiData1);
        $readmemh("resources/chipi/chipi-chipi_2.hex", chipiData2);
        $readmemh("resources/chipi/chipi-chipi_3.hex", chipiData3);
        $readmemh("resources/chipi/chipi-chipi_4.hex", chipiData4);
    end
`endif

    integer updateObjI, updateCacheImgI, updateCacheObjX, updateCacheObjY;
    integer nowX, nowY, newP1Y, newP2Y;
    always @(posedge nextFrame) begin : frame
        // Init
        if (frameCount==0) begin
            gameObjs`getObjX(5) <= 0;
            gameObjs`getObjY(5) <= 0;
            gameObjs`getObjW(5) <= 32;
            gameObjs`getObjH(5) <= 32;
            gameObjs`getObjImg(5) <= 1;

            gameObjs`getObjX(testPtr) <= 0;
            gameObjs`getObjY(testPtr) <= 32;
            gameObjs`getObjW(testPtr) <= 64;
            gameObjs`getObjH(testPtr) <= 29;
            gameObjs`getObjImg(testPtr) <= 2;

            gameObjs`getObjX(4) <= 0;
            gameObjs`getObjY(4) <= 32+29;
            gameObjs`getObjW(4) <= 64;
            gameObjs`getObjH(4) <= 23;
            gameObjs`getObjImg(4) <= 3;

            gameObjs`getObjX(6) <= 0;
            gameObjs`getObjY(6) <= 32+29+23;
            gameObjs`getObjW(6) <= 128;
            gameObjs`getObjH(6) <= 128;
            gameObjs`getObjImg(6) <= 4;

            gameObjs`getObjX(ballPtr) <= 0;
            gameObjs`getObjY(ballPtr) <= 0;
            gameObjs`getObjW(ballPtr) <= 32;
            gameObjs`getObjH(ballPtr) <= 32;
            gameObjs`getObjImg(ballPtr) <= 1;

            gameObjs`getObjX(p1Ptr) <= slabDefaultOffset;
            gameObjs`getObjY(p1Ptr) <= ScreenHeight / 2 - slabDefaultLen / 2;
            gameObjs`getObjW(p1Ptr) <= slabWidth;
            gameObjs`getObjH(p1Ptr) <= slabDefaultLen;
            gameObjs`getObjImg(p1Ptr) = 0;

            gameObjs`getObjX(p2Ptr) <= ScreenWidth - slabWidth - slabDefaultOffset;
            gameObjs`getObjY(p2Ptr) <= ScreenHeight / 2 - slabDefaultLen / 2;
            gameObjs`getObjW(p2Ptr) <= slabWidth;
            gameObjs`getObjH(p2Ptr) <= slabDefaultLen;
            gameObjs`getObjImg(p2Ptr) <= 0;

            disable frame;
        end

        // Player control
        newP1Y = gameObjs`getObjY(p1Ptr);
        if (!button[2]) begin
            newP1Y = gameObjs`getObjY(p1Ptr) - p1Speed;
            if (newP1Y < 0) newP1Y = 0;
            gameObjs`getObjY(p1Ptr) <= newP1Y;
        end else if (!button[3]) begin
            newP1Y = gameObjs`getObjY(p1Ptr) + p1Speed;
            if (newP1Y + gameObjs`getObjH(p1Ptr) > ScreenHeight) 
                newP1Y = ScreenHeight - gameObjs`getObjH(p1Ptr);
            gameObjs`getObjY(p1Ptr) <= newP1Y;
        end
        newP2Y = gameObjs`getObjY(p2Ptr);
        if (!button[0]) begin
            newP2Y = gameObjs`getObjY(p2Ptr) - p2Speed;
            if (newP2Y < 0) newP2Y = 0;
            gameObjs`getObjY(p2Ptr) <= newP2Y;
        end else if (!button[1]) begin
            newP2Y = gameObjs`getObjY(p2Ptr) + p2Speed;
            if (newP2Y + gameObjs`getObjH(p2Ptr) > ScreenHeight) 
                newP2Y = ScreenHeight - gameObjs`getObjH(p2Ptr);
            gameObjs`getObjY(p2Ptr) <= newP2Y;
        end

        // Ball control
        nowX = (gameObjs`getObjX(ballPtr)) + ballVelX;
        nowY = (gameObjs`getObjY(ballPtr)) + ballVelY;
        gameObjs`getObjX(ballPtr) <= nowX;
        gameObjs`getObjY(ballPtr) <= nowY;
        if (nowX < 0) begin
            ballVelX <= 0 - ballVelX;
            gameObjs`getObjX(ballPtr) <= `objX'd0;
        end
        if (nowX + gameObjs`getObjW(ballPtr) > ScreenWidth) begin
            ballVelX <= 0 - ballVelX;
            gameObjs`getObjX(ballPtr) <= ScreenWidth - gameObjs`getObjW(ballPtr);
        end
        if (nowY < 0) begin
            ballVelY <= 0 - ballVelY;
            gameObjs`getObjY(ballPtr) <= `objY'd0;
        end
        if (nowY + gameObjs`getObjH(ballPtr) > ScreenHeight) begin
            ballVelY <= 0 - ballVelY;
            gameObjs`getObjY(ballPtr) <= ScreenHeight - gameObjs`getObjH(ballPtr);
        end

        // Ball collition
        for (updateObjI = 0; updateObjI < `objCount; updateObjI = updateObjI + 1) begin
            if (updateObjI != ballPtr && intersectSphereBox(
                nowX+(gameObjs`getObjW(ballPtr)>>1), nowY+(gameObjs`getObjH(ballPtr)>>1), gameObjs`getObjW(ballPtr)>>1,
                gameObjs`getObjX(updateObjI), gameObjs`getObjY(updateObjI), 
                gameObjs`getObjW(updateObjI), gameObjs`getObjH(updateObjI))) begin
                ballVelX <= 0 - ballVelX;
                gameObjs`getObjX(ballPtr) <= (ballVelX > 0)
                    ? gameObjs`getObjX(updateObjI) - gameObjs`getObjW(ballPtr) 
                    : gameObjs`getObjX(updateObjI);
            end
        end

`ifndef NOCHIPI
        chipiDiv <= chipiDiv + 1;
        if (chipiDiv == 6) begin
            chipiDiv <= 0;
            if (chipiDir) chipiFrame = chipiFrame + 1;
            else chipiFrame = chipiFrame - 1;
            if (chipiFrame == 0) chipiDir <= 1;
            else if (chipiFrame == 4) chipiDir <= 0;
        end
`endif
    end

    reg [3:0] redCache = 4'd0;
    reg [3:0] greenCache = 4'd0;
    reg [3:0] blueCache = 4'd0;
    reg pixDraw = 1'd0;
    reg [`imageBitdepth-1:0] pixColor = `imageBitdepth'd0;
    integer renderObjI;
    always @(pixX or pixY) begin : screen
        if (!available) begin
            Red   <= 4'd0;
            Green <= 4'd0;
            Blue  <= 4'd0;
            disable screen;
        end
        pixDraw = 1'd0;
        redCache = 4'd0;
        greenCache = 4'd0;
        blueCache = 4'd0;

`ifndef NOCHIPI
        if ((pixX >= chipiPosX) && (pixX < chipiPosX+(chipiWidth<<1)) && 
            (pixY >= chipiPosY) && (pixY < chipiPosY+(chipiHeight<<1))) begin
                case (chipiFrame)
                    0: pixColor = chipiData0[(pixY-chipiPosY) >> 1] >> ((chipiWidth-(((pixX-chipiPosX) >> 1)+1))*`imageBitdepth);
                    1: pixColor = chipiData1[(pixY-chipiPosY) >> 1] >> ((chipiWidth-(((pixX-chipiPosX) >> 1)+1))*`imageBitdepth);
                    2: pixColor = chipiData2[(pixY-chipiPosY) >> 1] >> ((chipiWidth-(((pixX-chipiPosX) >> 1)+1))*`imageBitdepth);
                    3: pixColor = chipiData3[(pixY-chipiPosY) >> 1] >> ((chipiWidth-(((pixX-chipiPosX) >> 1)+1))*`imageBitdepth);
                    4: pixColor = chipiData4[(pixY-chipiPosY) >> 1] >> ((chipiWidth-(((pixX-chipiPosX) >> 1)+1))*`imageBitdepth);
                endcase
            if (pixColor) begin
                redCache = (((pixColor >> 12 & 4'b1111) * (pixColor & 4'b1111)) >> 4);
                greenCache = (((pixColor >> 8 & 4'b1111) * (pixColor & 4'b1111)) >> 4);
                blueCache = (((pixColor >> 4 & 4'b1111) * (pixColor & 4'b1111)) >> 4);
                pixDraw = 1;
            end
        end
`endif

        // Render game objects
        for (renderObjI = 0; renderObjI < `objCount; renderObjI = renderObjI + 1) begin
            updateCacheObjX = gameObjs`getObjX(renderObjI);
            updateCacheObjY = gameObjs`getObjY(renderObjI);
            if ((pixX >= updateCacheObjX) && (pixX < updateCacheObjX + gameObjs`getObjW(renderObjI)) && 
                (pixY >= updateCacheObjY) && (pixY < updateCacheObjY + gameObjs`getObjH(renderObjI))) begin
                updateCacheImgI = gameObjs`getObjImg(renderObjI);
                // If image id not 0, render image
                if (updateCacheImgI) begin
                    updateCacheImgI = updateCacheImgI - 1;
                    // Render image
                    if ((pixX >= updateCacheObjX) && (pixX < updateCacheObjX + `imageW(updateCacheImgI)) && 
                        (pixY >= updateCacheObjY) && (pixY < updateCacheObjY + `imageH(updateCacheImgI))) begin
                        pixColor = imageData`image(updateCacheImgI, pixX-updateCacheObjX, pixY-updateCacheObjY);
                        if (pixColor) begin
                            redCache = (((pixColor >> 12 & 4'b1111) * (pixColor & 4'b1111)) >> 4);
                            greenCache = (((pixColor >> 8 & 4'b1111) * (pixColor & 4'b1111)) >> 4);
                            blueCache = (((pixColor >> 4 & 4'b1111) * (pixColor & 4'b1111)) >> 4);
                            pixDraw = 1;
                        end
                    end
                end else begin
                    // Render color
                    redCache = 4'b1111;
                    greenCache = 4'b1111;
                    blueCache = 4'b1111;
                    pixDraw = 1;
                end
            end
        end

`ifdef DEBUG
        if (!pixDraw) begin
            if ((pixX == 0 && pixY == 0) || (pixX == 639 && pixY == 479)) begin
                redCache   = 4'b1111;
                greenCache = 4'b1111;
                blueCache  = 4'b1111;
            end else if (pixX == 0 || pixX == 639) begin
                redCache   = 4'b1111;
                greenCache = 4'b0000;
                blueCache  = 4'b0000;
            end else if (pixY == 0 || pixY == 479) begin
                redCache   = 4'b0000;
                greenCache = 4'b1111;
                blueCache  = 4'b0000;
            end
        end
`endif
        Red   <= redCache;
        Green <= greenCache;
        Blue  <= blueCache;
    end

    function pointInBox;
        input [31:0] pointX;
        input [31:0] pointY;
        input [31:0] boxX;
        input [31:0] boxY;
        input [31:0] boxW;
        input [31:0] boxH;
        pointInBox = (pointX >= boxX && pointX <= boxX + boxW && pointY >= boxY && pointY <= boxY + boxH);
    endfunction

    function intersectSphereBox;
        input [31:0] sphereX;
        input [31:0] sphereY;
        input [31:0] sphereR;
        input [31:0] boxX;
        input [31:0] boxY;
        input [31:0] boxW;
        input [31:0] boxH;
        integer x, y, distance;

        begin
            // get box closest point to sphere center by clamping
            x = max(boxX, min(sphereX, boxX + boxW));
            y = max(boxY, min(sphereY, boxY + boxH));
            // this is the same as isPointInsideSphere
            distance = ((x - sphereX) * (x - sphereX) + (y - sphereY) * (y - sphereY));
            intersectSphereBox = distance < sphereR * sphereR;
        end
    endfunction

`ifdef DEBUG
    six_digit_seven_display sevenDisp(
        frameCount,
        sevenDisp0,
        sevenDisp1,
        sevenDisp2,
        sevenDisp3,
        sevenDisp4,
        sevenDisp5
    );
`endif
endmodule
