module vga_driver (
    input rst,
    input clk,
    output reg H_SYNC = 0,
    output reg V_SYNC = 0,
    output reg available = 0,
    output reg nextFrame = 0,
    output reg [15:0] pixX = 0,
    output reg [15:0] pixY = 0,
    output reg [31:0] frameCount = 0
);

    parameter HSyncPulse = 16'd96, HBackPorch = 16'd48, HActiveVid = 16'd640, HFrontPorch = 16'd16;
    parameter VSyncPulse = 16'd2, VBackPorch = 16'd33, VActiveVid = 16'd480, VFrontPorch = 16'd10;

    reg vgaClk = 0;
    reg availableV = 0;
    reg [15:0] Hcount = 0;
    reg [15:0] Vcount = 0;

    always @(posedge clk) begin
        vgaClk = ~vgaClk;
    end

    always @(posedge vgaClk) begin
        if (Hcount == HSyncPulse - 1) begin
            H_SYNC <= 1;
        end else if (Hcount == HSyncPulse + HBackPorch - 1) begin
            if (availableV && rst) available <= 1;
        end else if (Hcount == HSyncPulse + HBackPorch + HActiveVid - 1) begin
            available <= 0;
        end else if (Hcount == HSyncPulse + HBackPorch + HActiveVid + HFrontPorch - 2) begin
            Vcount <= Vcount + 16'd1;
        end

        if (Hcount == HSyncPulse + HBackPorch + HActiveVid + HFrontPorch - 1) begin
            Hcount <= 0;
            H_SYNC <= 0;
        end else begin
            Hcount <= Hcount + 16'd1;
        end

        if (Vcount == VSyncPulse - 1) begin
            V_SYNC <= 1;
        end else if (Vcount == VSyncPulse + VBackPorch - 1) begin
            availableV <= 1;
        end else if (Vcount == VSyncPulse + VBackPorch + VActiveVid - 1) begin
            availableV <= 0;
            nextFrame  <= 0;
        end else if (Vcount == VSyncPulse + VBackPorch + VActiveVid + VFrontPorch - 1) begin
            Vcount <= 0;
            V_SYNC <= 0;
            if (!rst) frameCount <= 0;
            else frameCount <= frameCount + 1;
            nextFrame <= 1;
        end

        pixY <= Vcount - (VSyncPulse + VBackPorch) + 16'd1;
        pixX <= Hcount - (HSyncPulse + HBackPorch) + 16'd1;
    end
endmodule
