function [31:0] abs;
    input [31:0] in;
    abs = in[31] ? (1 + ~in) : in;
endfunction

function [31:0] max;
    input [31:0] a;
    input [31:0] b;
    max = a > b ? a : b;
endfunction

function [31:0] min;
    input [31:0] a;
    input [31:0] b;
    min = a < b ? a : b;
endfunction