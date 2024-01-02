`include "./src/vga_driver.v"
`include "./src/keypad_driver.v"
`include "./src/seven_display_driver.v"

`include "./src/dot_display.v"

`include "./src/resource.v"
`include "./src/resources_define.v"
`include "./src/struct_define.v"

`define DEBUG
`define NOIMAGE
// `define NOFONT

`define charAt(index) [index << 3 +: 8]

`define color16R(color) (((color) >> 12) & 4'b1111)
`define color16G(color) (((color) >> 8) & 4'b1111)
`define color16B(color) (((color) >> 4) & 4'b1111)
`define color16A(color) ((color) & 4'b1111)

`define color12R(color) (((color) >> 9) & 4'b0111 << 1)
`define color12G(color) (((color) >> 6) & 4'b0111 << 1)
`define color12B(color) (((color) >> 3) & 4'b0111 << 1)
`define color12A(color) ((color) & 4'b0111 << 1)

`define imgColBit (`imageBitdepth-1)

`define ScreenWidth 12'd640
`define ScreenHeight 12'd480

`define nullTag `objTagSize'd0
`define playerTag `objTagSize'd1
`define ballTag `objTagSize'd2
`define brickTag `objTagSize'd3
`define skillTag `objTagSize'd4

module project (
    input clk,
    input rst,
    input [3:0] button,

    input [3:0] keypadCol,
    output [3:0] keypadRowRequest,

    output reg [9:0] led,

    output reg [3:0] vgaRed,
    output reg [3:0] vgaGreen,
    output reg [3:0] vgaBlue,
    output vgaH_SYNC,
    output vgaV_SYNC,

    output [6:0] sevenDisp0,
    output [6:0] sevenDisp1,
    output [6:0] sevenDisp2,
    output [6:0] sevenDisp3,
    output [6:0] sevenDisp4,
    output [6:0] sevenDisp5,

    output [7:0] matrixRow,
    output [7:0] matrixCol0,
    output [7:0] matrixCol1
);
    `include "src/lib/math.sv"
    `include "src/lib/collision_check.sv"

    // Vga driver
    wire available;
    wire nextFrame;
    wire [15:0] pixX;
    wire [15:0] pixY;
    wire [31:0] frameCount;
    vga_driver vga (
        rst,
        clk,
        vgaH_SYNC,
        vgaV_SYNC,
        available,
        nextFrame,
        pixX,
        pixY,
        frameCount
    );
    // Keypad
    wire [3:0] keypadRow0, keypadRow1, keypadRow2, keypadRow3;
    keypad_driver keypad (
        clk,
        rst,
        keypadCol,
        keypadRowRequest,
        keypadRow0,
        keypadRow1,
        keypadRow2,
        keypadRow3
    );
    // Dot Display
    reg [1:0] lightState;
    dot_display dotDisplay(
        clk,
        rst,
        lightState,
        matrixRow,
        matrixCol0,
        matrixCol1
    );

    // Resources loader
    wire [`fontLength-1:0] fontData;
    wire [`rom0Length-1:0] imageData;
    resource res (imageData, fontData);

    // Gameobjects
    `gameObjsInit;

    parameter ballPtr = 0, ball2Ptr = 1, p1Ptr = 2, p2Ptr = 3, skillPtr = 4;

    reg [8*13 - 1:0] gameTitle;


    // Player
    parameter slabWidth = `objHSize'd8, slabDefaultLen = `objWSize'd80, slabDefaultOffset = `objYSize'd40, slabDefaultSpeed = `objXSize'd4;
    reg signed [`objXSize-1:0] p1Speed = slabDefaultSpeed, p2Speed = slabDefaultSpeed;
    reg signed [11:0] newP1X = `objXSize'd0, newP2X = `objXSize'd0;

    // Ball
    parameter initBallVel = -`objYSize'd5;
    reg unsigned [1:0] ballState = 1;
    reg signed [11:0] ballVelX = `objXSize'd0, ballVelY = `objXSize'd0;
    reg signed [11:0] ballNewX = `objXSize'd0, ballNewY = `objYSize'd0;

    // Text
    reg unsigned [15:0] textScale = 16'd2;
    reg unsigned [15:0] textX = 16'd0, textY = 16'd5;

    // Skill box
    reg signed [11:0] skillBoxX = 12'd0, skillBoxY = 12'd0, skillBoxVelY = 12'd3;


    // Game Update
    integer updateObjI, updateCacheI, updateCacheJ, updateCacheK;
    always @(posedge nextFrame) begin : frame
        // Init
        if (frameCount == 0) begin
            gameTitle = "Brick Breaker";

            textX = (`ScreenWidth - ((`fontCharMaxWidth + 1) << textScale) * 3) >> 1;

            p1Speed = slabDefaultSpeed;
            p2Speed = slabDefaultSpeed;

            updateCacheK = 5;
            for (updateCacheI = 0; updateCacheI < 4; updateCacheI = updateCacheI + 1) begin
                for (updateCacheJ = 0; updateCacheJ < 8; updateCacheJ = updateCacheJ + 1) begin
                    gameObjs`objX(updateCacheK) <= `objXSize'd96 + `objXSize'd56 * updateCacheJ;
                    gameObjs`objY(updateCacheK) <= `objXSize'd64 + `objXSize'd32 * updateCacheI;
                    gameObjs`objW(updateCacheK) <= `imageW(1) << 1;
                    gameObjs`objH(updateCacheK) <= `imageH(1) << 1;
                    gameObjs`objTag(updateCacheK) <= `brickTag;
                    gameObjs`objImgId(updateCacheK) <= 1;
                    gameObjs`objColor(updateCacheK) <= `objColorSize'hFFFF;
                    gameObjs`objImgScale(updateCacheK) <= 1;
                    updateCacheK = updateCacheK + 1;
                end
            end

            ballState = 1;
            ballVelX = `objXSize'd0;
            ballVelY = `objXSize'd0;
            gameObjs`objTag(ballPtr) <= `ballTag;
            gameObjs`objX(ballPtr) <= 0;
            gameObjs`objY(ballPtr) <= 0;
            gameObjs`objW(ballPtr) <= `imageW(0);
            gameObjs`objH(ballPtr) <= `imageH(0);
            gameObjs`objColor(ballPtr) <= `objColorSize'hFFFF;
            gameObjs`objImgId(ballPtr) <= 0;

            gameObjs`objTag(ball2Ptr) <= `nullTag;
            gameObjs`objX(ball2Ptr) <= 0;
            gameObjs`objY(ball2Ptr) <= 0;
            gameObjs`objW(ball2Ptr) <= `imageW(0);
            gameObjs`objH(ball2Ptr) <= `imageH(0);
            gameObjs`objColor(ball2Ptr) <= `objColorSize'hFFFF;
            gameObjs`objImgId(ball2Ptr) <= 0;

            gameObjs`objTag(p1Ptr) <= `playerTag;
            gameObjs`objX(p1Ptr) <= `ScreenWidth / `objXSize'd4 - slabDefaultLen / `objXSize'd2;
            gameObjs`objY(p1Ptr) <= `ScreenHeight - slabDefaultOffset;
            gameObjs`objW(p1Ptr) <= slabDefaultLen;
            gameObjs`objH(p1Ptr) <= slabWidth;
            gameObjs`objColor(p1Ptr) <= `objColorSize'hFAFF;
            gameObjs`objImgId(p1Ptr) <= `objImgIdMask;

            gameObjs`objTag(p2Ptr) <= `playerTag;
            gameObjs`objX(p2Ptr) <= `ScreenWidth / `objXSize'd4 * `objXSize'd3 - slabDefaultLen / `objXSize'd2;
            gameObjs`objY(p2Ptr) <= `ScreenHeight - slabDefaultOffset;
            gameObjs`objW(p2Ptr) <= slabDefaultLen;
            gameObjs`objH(p2Ptr) <= slabWidth;
            gameObjs`objColor(p2Ptr) <= `objColorSize'hAFFF;
            gameObjs`objImgId(p2Ptr) <= `objImgIdMask;

            gameObjs`objTag(skillPtr) <= `nullTag;
            gameObjs`objX(skillPtr) <= 0;
            gameObjs`objY(skillPtr) <= 0;
            gameObjs`objW(skillPtr) <= 16;
            gameObjs`objH(skillPtr) <= 16;
            gameObjs`objColor(skillPtr) <= `objColorSize'hFFFF;
            gameObjs`objImgId(skillPtr) <= `objImgIdMask;

            disable frame;
        end

        // Player control
        newP1X = gameObjs`objX(p1Ptr);
        if (keypadRow0[3]) begin
            newP1X = gameObjs`objX(p1Ptr) - p1Speed;
            if (newP1X < 0) newP1X = 0;
            gameObjs`objX(p1Ptr) <= newP1X;
        end else if (keypadRow0[2]) begin
            newP1X = gameObjs`objX(p1Ptr) + p1Speed;
            if (newP1X + gameObjs`objW(p1Ptr) >= `ScreenWidth) 
                newP1X = `ScreenWidth - gameObjs`objW(p1Ptr);
            gameObjs`objX(p1Ptr) <= newP1X;
        end
        newP2X = gameObjs`objX(p2Ptr);
        if (keypadRow0[1]) begin
            newP2X = gameObjs`objX(p2Ptr) - p2Speed;
            if (newP2X < 0) newP2X = 0;
            gameObjs`objX(p2Ptr) <= newP2X;
        end else if (keypadRow0[0]) begin
            newP2X = gameObjs`objX(p2Ptr) + p2Speed;
            if (newP2X + gameObjs`objW(p2Ptr) >= `ScreenWidth) 
                newP2X = `ScreenWidth - gameObjs`objW(p2Ptr);
            gameObjs`objX(p2Ptr) <= newP2X;
        end

        // Ball control
        case(ballState)
            2'd0: begin
                ballNewX = (gameObjs`objX(ballPtr)) + ballVelX;
                ballNewY = (gameObjs`objY(ballPtr)) + ballVelY;
                gameObjs`objX(ballPtr) <= ballNewX;
                gameObjs`objY(ballPtr) <= ballNewY;
                if (ballNewX < 0) begin
                    ballVelX <= `objXSize'd0 - ballVelX;
                    gameObjs`objX(ballPtr) <= `objXSize'd0;
                end else if (ballNewX + gameObjs`objW(ballPtr) >= `ScreenWidth) begin
                    ballVelX <= `objXSize'd0 - ballVelX;
                    gameObjs`objX(ballPtr) <= `ScreenWidth - gameObjs`objW(ballPtr);
                end
                if (ballNewY < 0) begin
                    ballVelY <= `objYSize'd0 - ballVelY;
                    gameObjs`objY(ballPtr) <= `objYSize'd0;
                end else if (ballNewY + gameObjs`objH(ballPtr) >= `ScreenHeight) begin
                    ballVelY <= `objYSize'd0 - ballVelY;
                    gameObjs`objY(ballPtr) <= `ScreenHeight - gameObjs`objH(ballPtr);
                end
            end
            2'd1: begin
                gameObjs`objX(ballPtr) <= newP1X + (gameObjs`objW(p1Ptr)>>1) - (gameObjs`objW(ballPtr)>>1);
                gameObjs`objY(ballPtr) <= gameObjs`objY(p1Ptr) - gameObjs`objH(ballPtr) - `objYSize'd5;
                if (keypadRow1[3]) begin
                    ballState <= 0;
                    ballVelX <= initBallVel;
                    ballVelY <= initBallVel;
                end
            end
        endcase

        // Ball collition
        updateCacheJ = 1;
        for (updateObjI = 0; updateObjI < `gameObjsMaxLen && updateCacheJ; updateObjI = updateObjI + 1) begin : collition
            // Continue if ball or null
            if (gameObjs`objTag(updateObjI) == `ballTag || gameObjs`objTag(updateObjI) == `nullTag)
                disable collition;

            updateCacheI = intersectSphereBox(
                ballNewX+(gameObjs`objW(ballPtr)>>1), ballNewY+(gameObjs`objH(ballPtr)>>1), gameObjs`objW(ballPtr)>>1,
                gameObjs`objX(updateObjI), gameObjs`objY(updateObjI), 
                gameObjs`objW(updateObjI), gameObjs`objH(updateObjI));
            // Brack brick
            if (updateCacheI > 0 && gameObjs`objTag(updateObjI) == `brickTag) begin
                gameObjs`objTag(updateObjI) <= `nullTag;
            end
            // Physics
            if (updateCacheI & 2'b10) begin
                gameObjs`objX(ballPtr) <= (ballVelX > 0)
                    ? gameObjs`objX(updateObjI) - gameObjs`objW(ballPtr) 
                    : gameObjs`objX(updateObjI) + gameObjs`objW(updateObjI);
                ballVelX <= 0 - ballVelX;
                updateCacheJ = 0;
            end
            if (updateCacheI & 2'b01) begin
                gameObjs`objY(ballPtr) <= (ballVelY > 0)
                    ? gameObjs`objY(updateObjI) - gameObjs`objH(ballPtr) 
                    : gameObjs`objY(updateObjI) + gameObjs`objH(updateObjI);
                ballVelY <= 0 - ballVelY;
                updateCacheJ = 0;
            end
        end

        if (frameCount % 60 == 0)
            lightState <= lightState + 1;
    end

    reg unsigned [3:0] alphaCache = 4'd0;
    reg unsigned [`imageBitdepth-1:0] pixColor = `imageBitdepth'd0, pixColorB = `imageBitdepth'd0;
    reg unsigned [15:0] renderCacheImgI = 16'd0, renderCacheImgS = 16'd0, renderCacheFontIndex = 16'b0;
    integer renderObjI, renderCacheObjX, renderCacheObjY, renderCacheTextOffX;
    always @(pixX or pixY) begin : screen
        if (!available) begin
            vgaRed   <= 4'd0;
            vgaGreen <= 4'd0;
            vgaBlue  <= 4'd0;
            disable screen;
        end

        pixColor = 0;
        for (renderObjI = 0; renderObjI < `gameObjsMaxLen; renderObjI = renderObjI + 1) begin
            renderCacheObjX = gameObjs`objX(renderObjI);
            renderCacheObjY = gameObjs`objY(renderObjI);
            if (gameObjs`objTag(renderObjI) != `nullTag &&
                (pixX >= renderCacheObjX) && (pixX < renderCacheObjX + gameObjs`objW(renderObjI)) && 
                (pixY >= renderCacheObjY) && (pixY < renderCacheObjY + gameObjs`objH(renderObjI))) begin
                renderCacheImgI = gameObjs`objImgId(renderObjI);
                // If image id not 0, render image
                if (renderCacheImgI != `objImgIdMask) begin
                    renderCacheImgS = gameObjs`objImgScale(renderObjI);
`ifndef NOIMAGE
                    // Render image
                    if ((pixX >= renderCacheObjX) && (pixX < renderCacheObjX + (`imageW(renderCacheImgI) << renderCacheImgS)) && 
                        (pixY >= renderCacheObjY) && (pixY < renderCacheObjY + (`imageH(renderCacheImgI) << renderCacheImgS))) begin
                        pixColor = imageData`image(renderCacheImgI, (pixX - renderCacheObjX) >> renderCacheImgS, (pixY - renderCacheObjY) >> renderCacheImgS);
                        // pixColorB = gameObjs`objColor(renderObjI);
                        // pixColor[0+:4] = `color16A(pixColor)+(`color16A(pixColorB)*(`imgColBit-`color16A(pixColor))/`imgColBit);
                        // pixColor[12+:4]= ({16'b0,`color16R(pixColor)}*`color16A(pixColor)+`color16R(pixColorB)*`color16A(pixColorB)*(`imgColBit-`color16A(pixColor))/`imgColBit)/pixColor[0+:4];
                        // pixColor[8+:4] = ({16'b0,`color16G(pixColor)}*`color16A(pixColor)+`color16G(pixColorB)*`color16A(pixColorB)*(`imgColBit-`color16A(pixColor))/`imgColBit)/pixColor[0+:4];
                        // pixColor[4+:4] = ({16'b0,`color16B(pixColor)}*`color16A(pixColor)+`color16B(pixColorB)*`color16A(pixColorB)*(`imgColBit-`color16A(pixColor))/`imgColBit)/pixColor[0+:4];
                        
                        // redCache    = (`color16R(pixColor)*`color16A(pixColor)+`color16A(pixColorB)*`color16A(pixColorB)*(`imgColBit-`color16A(pixColor))/`imgColBit)/pixColor[0+:4];
                        // greenCache  = (`color16G(pixColor)*`color16A(pixColor)+`color16A(pixColorB)*`color16A(pixColorB)*(`imgColBit-`color16A(pixColor))/`imgColBit)/pixColor[0+:4];
                        // blueCache   = (`color16B(pixColor)*`color16A(pixColor)+`color16A(pixColorB)*`color16A(pixColorB)*(`imgColBit-`color16A(pixColor))/`imgColBit)/pixColor[0+:4];
                        
                        // alphaCache = `color16A(pixColor);
                        // if (alphaCache) begin
                        //     redCache    = (`color16R(pixColor) * alphaCache) >> 4;
                        //     greenCache  = (`color16G(pixColor) * alphaCache) >> 4;
                        //     blueCache   = (`color16B(pixColor) * alphaCache) >> 4;
                        // end
                    end
`else
                    // Show only border for NOIMAGE mode
                    if ((pixX == renderCacheObjX) || (pixX + 16'b1 == renderCacheObjX + (`imageW(renderCacheImgI) << renderCacheImgS)) || 
                        (pixY == renderCacheObjY) || (pixY + 16'b1 == renderCacheObjY + (`imageH(renderCacheImgI) << renderCacheImgS))) begin
                        pixColor = gameObjs`objColor(renderObjI);
                    end
`endif
                end else begin
                    // Render color
                    pixColor = gameObjs`objColor(renderObjI);
                end
            end
        end
        
`ifndef NOFONT
        // Second
        renderCacheImgI = frameCount / 60;

        renderCacheTextOffX = textX;
        renderCacheFontIndex = `fontDigitOff(renderCacheImgI/100%10);
        if ((pixX >= renderCacheTextOffX) && (pixX < renderCacheTextOffX + (`fontCharW(renderCacheFontIndex) << textScale)) && 
            (pixY >= textY) && (pixY < textY + (`fontCharHeight << textScale)) &&
            fontData`fontChar(renderCacheFontIndex, (pixX-renderCacheTextOffX)>>textScale, (pixY-textY)>>textScale))
            pixColor = 16'b1111111111111111;

        renderCacheTextOffX = textX + ((`fontCharW(renderCacheFontIndex) + 1) << textScale);
        renderCacheFontIndex = `fontDigitOff(renderCacheImgI/10%10);
        if ((pixX >= renderCacheTextOffX) && (pixX < renderCacheTextOffX + (`fontCharW(renderCacheFontIndex) << textScale)) && 
            (pixY >= textY) && (pixY < textY + (`fontCharHeight << textScale)) &&
            fontData`fontChar(renderCacheFontIndex, (pixX-renderCacheTextOffX)>>textScale, (pixY-textY)>>textScale))
            pixColor = 16'b1111111111111111;

        renderCacheTextOffX = textX + ((`fontCharW(renderCacheFontIndex) + 1) << textScale << 1);
        renderCacheFontIndex = `fontDigitOff(renderCacheImgI%10);
        if ((pixX >= renderCacheTextOffX) && (pixX < renderCacheTextOffX + (`fontCharW(renderCacheFontIndex) << textScale)) && 
            (pixY >= textY) && (pixY < textY + (`fontCharHeight << textScale)) &&
            fontData`fontChar(renderCacheFontIndex, (pixX-renderCacheTextOffX)>>textScale, (pixY-textY)>>textScale))
            pixColor = 16'b1111111111111111;
        
`endif

`ifdef DEBUG
        if(!pixColor) begin
            if ((pixX == 0 && pixY == 0) || (pixX == 639 && pixY == 479)) begin
                pixColor = 16'b1111111111111111;
            end else if (pixX == 0 || pixX == 639) begin
                pixColor = 16'b1111000000001111;
            end else if (pixY == 0 || pixY == 479) begin
                pixColor = 16'b0000111100001111;
            end
        end
`endif

        vgaRed   <= (`color16R(pixColor) * `color16A(pixColor)) >> 4;
        vgaGreen <= (`color16G(pixColor) * `color16A(pixColor)) >> 4;
        vgaBlue  <= (`color16B(pixColor) * `color16A(pixColor)) >> 4;
    end

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
