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
        else intersectSphereBox = 0;
    end
endfunction

function intersectBoxBox;
    input [31:0] aBoxX;
    input [31:0] aBoxY;
    input [31:0] aBoxW;
    input [31:0] aBoxH;
    input [31:0] bBoxX;
    input [31:0] bBoxY;
    input [31:0] bBoxW;
    input [31:0] bBoxH;
    intersectBoxBox = 
        aBoxX <= bBoxX + bBoxW &&
        aBoxX + aBoxW >= bBoxX &&
        aBoxY <= bBoxY + bBoxH &&
        aBoxY + aBoxH >= bBoxY;
endfunction
