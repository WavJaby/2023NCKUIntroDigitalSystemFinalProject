`include "./src/vga_driver.v"
`include "./src/seven_display.v"
`include "./src/resource.v"
`include "./src/resources_define.v"
`include "./src/struct_define.v"

`define DEBUG
`define NOIMAGE

`define ScreenWidth 16'd640
`define ScreenHeight 16'd480

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
    `include "src/lib/math.sv"
    // Vga driver
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

    // Resources loader
`ifndef NOIMAGE
    wire [`rom0Length-1:0] imageData;
    resource res (imageData);
`endif

    // Gameobjects
    `gameObjsInit;

    parameter testPtr = 0, ballPtr = 1, p1Ptr = 2, p2Ptr = 3;
    parameter slabWidth = 16'd8, slabDefaultLen = 16'd80, slabDefaultOffset = 16'd40;

    reg signed [15:0] p1Speed = 16'd6, p2Speed = 16'd6;

    reg signed [15:0] ballVelX = 16'd1, ballVelY = 16'd1;

    reg signed [15:0] nowX = 16'd0, nowY = 16'd0,newP1Y = 16'd0, newP2Y = 16'd0;
    integer updateObjI, updateCacheI, updateCacheJ, updateCacheK;
    always @(posedge nextFrame) begin : frame
        // Init
        if (frameCount==0) begin
            // gameObjs`objX(4) <= 0;
            // gameObjs`objY(4) <= 0;
            // gameObjs`objW(4) <= `imageW(0);
            // gameObjs`objH(4) <= `imageH(0);
            // gameObjs`objImgId(4) <= 0;

            // gameObjs`objX(5) <= 0;
            // gameObjs`objY(5) <= `imageH(0);
            // gameObjs`objW(5) <= `imageW(1);
            // gameObjs`objH(5) <= `imageH(1);
            // gameObjs`objImgId(5) <= 1;

            // gameObjs`objX(6) <= 0;
            // gameObjs`objY(6) <= `imageH(0)+`imageH(1);
            // gameObjs`objW(6) <= `imageW(2);
            // gameObjs`objH(6) <= `imageH(2);
            // gameObjs`objImgId(6) <= 2;

            // gameObjs`objX(7) <= 0;
            // gameObjs`objY(7) <= `imageH(0)+`imageH(1)+`imageH(2);
            // gameObjs`objW(7) <= `imageW(3);
            // gameObjs`objH(7) <= `imageH(3);
            // gameObjs`objImgId(7) <= 3;

            updateCacheK = 10;
            for (updateCacheI = 0; updateCacheI < 4; updateCacheI = updateCacheI + 1) begin
                for (updateCacheJ = 0; updateCacheJ < 8; updateCacheJ = updateCacheJ + 1) begin
                    gameObjs`objX(updateCacheK) <= 128 + 48 * updateCacheJ;
                    gameObjs`objY(updateCacheK) <= 64 + 32 * updateCacheI;
                    gameObjs`objW(updateCacheK) <= `imageW(1);
                    gameObjs`objH(updateCacheK) <= `imageH(1);
                    gameObjs`objImgId(updateCacheK) <= 1;
                    updateCacheK = updateCacheK + 1;
                end
            end

            gameObjs`objX(ballPtr) <= 0;
            gameObjs`objY(ballPtr) <= 0;
            gameObjs`objW(ballPtr) <= `imageW(0);
            gameObjs`objH(ballPtr) <= `imageW(0);
            gameObjs`objImgId(ballPtr) <= 0;

            gameObjs`objX(p1Ptr) <= slabDefaultOffset;
            gameObjs`objY(p1Ptr) <= `ScreenHeight / 16'd2 - slabDefaultLen / 16'd2;
            gameObjs`objW(p1Ptr) <= slabWidth;
            gameObjs`objH(p1Ptr) <= slabDefaultLen;
            gameObjs`objImgId(p1Ptr) <= `objImgIdMask;

            gameObjs`objX(p2Ptr) <= `ScreenWidth - slabWidth - slabDefaultOffset;
            gameObjs`objY(p2Ptr) <= `ScreenHeight / 16'd2 - slabDefaultLen / 16'd2;
            gameObjs`objW(p2Ptr) <= slabWidth;
            gameObjs`objH(p2Ptr) <= slabDefaultLen;
            gameObjs`objImgId(p2Ptr) <= `objImgIdMask;

            disable frame;
        end

        // Player control
        newP1Y = gameObjs`objY(p1Ptr);
        if (!button[2]) begin
            newP1Y = gameObjs`objY(p1Ptr) - p1Speed;
            if (newP1Y < 0) newP1Y = 0;
            gameObjs`objY(p1Ptr) <= newP1Y;
        end else if (!button[3]) begin
            newP1Y = gameObjs`objY(p1Ptr) + p1Speed;
            if (newP1Y + gameObjs`objH(p1Ptr) > `ScreenHeight) 
                newP1Y = `ScreenHeight - gameObjs`objH(p1Ptr);
            gameObjs`objY(p1Ptr) <= newP1Y;
        end
        newP2Y = gameObjs`objY(p2Ptr);
        if (!button[0]) begin
            newP2Y = gameObjs`objY(p2Ptr) - p2Speed;
            if (newP2Y < 0) newP2Y = 0;
            gameObjs`objY(p2Ptr) <= newP2Y;
        end else if (!button[1]) begin
            newP2Y = gameObjs`objY(p2Ptr) + p2Speed;
            if (newP2Y + gameObjs`objH(p2Ptr) > `ScreenHeight) 
                newP2Y = `ScreenHeight - gameObjs`objH(p2Ptr);
            gameObjs`objY(p2Ptr) <= newP2Y;
        end

        // Ball control
        nowX = (gameObjs`objX(ballPtr)) + ballVelX;
        nowY = (gameObjs`objY(ballPtr)) + ballVelY;
        gameObjs`objX(ballPtr) <= nowX;
        gameObjs`objY(ballPtr) <= nowY;
        if (nowX < 0) begin
            ballVelX <= 16'd0 - ballVelX;
            gameObjs`objX(ballPtr) <= 16'd0;
        end
        if (nowX + gameObjs`objW(ballPtr) > `ScreenWidth) begin
            ballVelX <= 16'd0 - ballVelX;
            gameObjs`objX(ballPtr) <= `ScreenWidth - gameObjs`objW(ballPtr);
        end
        if (nowY < 0) begin
            ballVelY <= 16'd0 - ballVelY;
            gameObjs`objY(ballPtr) <= 16'd0;
        end
        if (nowY + gameObjs`objH(ballPtr) > `ScreenHeight) begin
            ballVelY <= 16'd0 - ballVelY;
            gameObjs`objY(ballPtr) <= `ScreenHeight - gameObjs`objH(ballPtr);
        end

        // Ball collition
        for (updateObjI = 0; updateObjI < `gameObjsMaxLen; updateObjI = updateObjI + 1) begin : collition
            // Continue if ball or null
            if (updateObjI == ballPtr || !gameObjs`objW(updateObjI))
                disable collition; 

            updateCacheI = intersectSphereBox(
                nowX+(gameObjs`objW(ballPtr)>>1), nowY+(gameObjs`objH(ballPtr)>>1), gameObjs`objW(ballPtr)>>1,
                gameObjs`objX(updateObjI), gameObjs`objY(updateObjI), 
                gameObjs`objW(updateObjI), gameObjs`objH(updateObjI));
            if (updateCacheI & 2'b10) begin
                gameObjs`objX(ballPtr) <= (ballVelX > 0)
                    ? gameObjs`objX(updateObjI) - gameObjs`objW(ballPtr) 
                    : gameObjs`objX(updateObjI) + gameObjs`objW(updateObjI);
                ballVelX <= 0 - ballVelX;
            end
            if (updateCacheI & 2'b01) begin
                gameObjs`objY(ballPtr) <= (ballVelY > 0)
                    ? gameObjs`objY(updateObjI) - gameObjs`objH(ballPtr) 
                    : gameObjs`objY(updateObjI) + gameObjs`objH(updateObjI);
                ballVelY <= 0 - ballVelY;
            end
        end
    end

    reg [3:0] redCache = 4'd0,  greenCache = 4'd0, blueCache = 4'd0;
    reg pixDraw = 1'd0;
    reg [`imageBitdepth-1:0] pixColor = `imageBitdepth'd0;
    reg [`objImgIdSize-1:0] renderCacheImgI = `objImgIdSize'd0;
    integer renderObjI, renderCacheObjX, renderCacheObjY;
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

        // Render game objects
        for (renderObjI = 0; renderObjI < `gameObjsMaxLen; renderObjI = renderObjI + 1) begin
            renderCacheObjX = gameObjs`objX(renderObjI);
            renderCacheObjY = gameObjs`objY(renderObjI);
            if (gameObjs`objW(renderObjI) &&
                (pixX >= renderCacheObjX) && (pixX < renderCacheObjX + gameObjs`objW(renderObjI)) && 
                (pixY >= renderCacheObjY) && (pixY < renderCacheObjY + gameObjs`objH(renderObjI))) begin
                renderCacheImgI = gameObjs`objImgId(renderObjI);
                // If image id not 0, render image
                if (renderCacheImgI != `objImgIdMask) begin
`ifndef NOIMAGE
                    // Render image
                    if ((pixX >= renderCacheObjX) && (pixX < renderCacheObjX + `imageW(renderCacheImgI)) && 
                        (pixY >= renderCacheObjY) && (pixY < renderCacheObjY + `imageH(renderCacheImgI))) begin
                        pixColor = imageData`image(renderCacheImgI, pixX-renderCacheObjX, pixY-renderCacheObjY);
                        if (pixColor) begin
                            redCache = (((pixColor >> 12 & 4'b1111) * (pixColor & 4'b1111)) >> 4);
                            greenCache = (((pixColor >> 8 & 4'b1111) * (pixColor & 4'b1111)) >> 4);
                            blueCache = (((pixColor >> 4 & 4'b1111) * (pixColor & 4'b1111)) >> 4);
                            pixDraw = 1;
                        end
                    end
`else
                    // Show only border for NOIMAGE mode
                    if ((pixX == renderCacheObjX) || (pixX + 16'd1 == renderCacheObjX + `imageW(renderCacheImgI)) || 
                        (pixY == renderCacheObjY) || (pixY + 16'd1 == renderCacheObjY + `imageH(renderCacheImgI))) begin
                        redCache = 4'b0;
                        greenCache = 4'b0;
                        blueCache = 4'b1111;
                    end
`endif
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

    function [1:0] intersectSphereBox;
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
            x = max(boxX, min(sphereX, boxX + boxW)) - sphereX;
            y = max(boxY, min(sphereY, boxY + boxH)) - sphereY;
            // this is the same as isPointInsideSphere
            distance = (x * x + y * y);
            if (distance < sphereR * sphereR)
                intersectSphereBox = abs(x) > abs(y) ? 2'b10 : abs(x) < abs(y) ? 2'b01 : 2'b11;
            else 
                intersectSphereBox = 0;
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
