# set clock 
set_location_assignment PIN_M9      -to clk;
# set reset
set_location_assignment PIN_P22     -to rst;

# set dot matrix column
set_location_assignment PIN_L8      -to dotCol0[7];
set_location_assignment PIN_J13     -to dotCol0[6];
set_location_assignment PIN_C15     -to dotCol0[5];
set_location_assignment PIN_B13     -to dotCol0[4];
set_location_assignment PIN_E16     -to dotCol0[3];
set_location_assignment PIN_G17     -to dotCol0[2];
set_location_assignment PIN_J18     -to dotCol0[1];
set_location_assignment PIN_A14     -to dotCol0[0];

set_location_assignment PIN_L8      -to dotCol1[7];
set_location_assignment PIN_J13     -to dotCol1[6];
set_location_assignment PIN_C15     -to dotCol1[5];
set_location_assignment PIN_B13     -to dotCol1[4];
set_location_assignment PIN_E16     -to dotCol1[3];
set_location_assignment PIN_G17     -to dotCol1[2];
set_location_assignment PIN_J18     -to dotCol1[1];

# set dot matrix row
set_location_assignment PIN_D13     -to dotRow[7];
set_location_assignment PIN_A13     -to dotRow[6];
set_location_assignment PIN_B12     -to dotRow[5];
set_location_assignment PIN_C13     -to dotRow[4];
set_location_assignment PIN_E14     -to dotRow[3];
set_location_assignment PIN_A12     -to dotRow[2];
set_location_assignment PIN_B15     -to dotRow[1];
set_location_assignment PIN_E15     -to dotRow[0];

# set seven digit output
set_location_assignment PIN_AA22    -to sevenDisp0[6];
set_location_assignment PIN_Y21     -to sevenDisp0[5];
set_location_assignment PIN_Y22     -to sevenDisp0[4];
set_location_assignment PIN_W21     -to sevenDisp0[3];
set_location_assignment PIN_W22     -to sevenDisp0[2];
set_location_assignment PIN_V21     -to sevenDisp0[1];
set_location_assignment PIN_U21     -to sevenDisp0[0];

set_location_assignment PIN_U22 	-to sevenDisp1[6];
set_location_assignment PIN_AA17    -to sevenDisp1[5];
set_location_assignment PIN_AB18    -to sevenDisp1[4];
set_location_assignment PIN_AA18    -to sevenDisp1[3];
set_location_assignment PIN_AA19    -to sevenDisp1[2];
set_location_assignment PIN_AB20    -to sevenDisp1[1];
set_location_assignment PIN_AA20    -to sevenDisp1[0];

set_location_assignment PIN_AB21    -to sevenDisp2[6];
set_location_assignment PIN_AB22    -to sevenDisp2[5];
set_location_assignment PIN_V14     -to sevenDisp2[4];
set_location_assignment PIN_Y14     -to sevenDisp2[3];
set_location_assignment PIN_AA10    -to sevenDisp2[2];
set_location_assignment PIN_AB17    -to sevenDisp2[1];
set_location_assignment PIN_Y19     -to sevenDisp2[0];

set_location_assignment PIN_V19     -to sevenDisp3[6];
set_location_assignment PIN_V18     -to sevenDisp3[5];
set_location_assignment PIN_U17     -to sevenDisp3[4];
set_location_assignment PIN_V16     -to sevenDisp3[3];
set_location_assignment PIN_Y17     -to sevenDisp3[2];
set_location_assignment PIN_W16     -to sevenDisp3[1];
set_location_assignment PIN_Y16     -to sevenDisp3[0];

set_location_assignment PIN_P9      -to sevenDisp4[6];
set_location_assignment PIN_Y15     -to sevenDisp4[5];
set_location_assignment PIN_U15     -to sevenDisp4[4];
set_location_assignment PIN_U16     -to sevenDisp4[3];
set_location_assignment PIN_V20     -to sevenDisp4[2];
set_location_assignment PIN_Y20     -to sevenDisp4[1];
set_location_assignment PIN_U20     -to sevenDisp4[0];

set_location_assignment PIN_W19     -to sevenDisp5[6];
set_location_assignment PIN_C2      -to sevenDisp5[5];
set_location_assignment PIN_C1      -to sevenDisp5[4];
set_location_assignment PIN_P14     -to sevenDisp5[3];
set_location_assignment PIN_T14     -to sevenDisp5[2];
set_location_assignment PIN_M8      -to sevenDisp5[1];
set_location_assignment PIN_N9      -to sevenDisp5[0];

# set led output
set_location_assignment PIN_AA2     -to led[0];
set_location_assignment PIN_AA1     -to led[1];
set_location_assignment PIN_W2      -to led[2];
set_location_assignment PIN_Y3      -to led[3];
set_location_assignment PIN_N2      -to led[4];
set_location_assignment PIN_N1      -to led[5];
set_location_assignment PIN_U2      -to led[6];
set_location_assignment PIN_U1      -to led[7];
set_location_assignment PIN_L2      -to led[8];
set_location_assignment PIN_L1      -to led[9];

# set vga output
set_location_assignment PIN_H8      -to H_SYNC;
set_location_assignment PIN_G8      -to V_SYNC;

set_location_assignment PIN_A9      -to Red[0];
set_location_assignment PIN_B10     -to Red[1];
set_location_assignment PIN_C9      -to Red[2];
set_location_assignment PIN_A5      -to Red[3];

set_location_assignment PIN_L7      -to Green[0];
set_location_assignment PIN_K7      -to Green[1];
set_location_assignment PIN_J7      -to Green[2];
set_location_assignment PIN_J8      -to Green[3];

set_location_assignment PIN_B6      -to Blue[0];
set_location_assignment PIN_B7      -to Blue[1];
set_location_assignment PIN_A8      -to Blue[2];
set_location_assignment PIN_A7      -to Blue[3];

# set buttons input
set_location_assignment PIN_U7      -to button[0];
set_location_assignment PIN_W9      -to button[1];
set_location_assignment PIN_M7      -to button[2];
set_location_assignment PIN_M6      -to button[3];

# set switch input
set_location_assignment PIN_U13     -to switch[0];
set_location_assignment PIN_V13     -to switch[1];
set_location_assignment PIN_T13     -to switch[2];
set_location_assignment PIN_T12     -to switch[3];
set_location_assignment PIN_AA15    -to switch[4];
set_location_assignment PIN_AB15    -to switch[5];
set_location_assignment PIN_AA14    -to switch[6];
set_location_assignment PIN_AA13    -to switch[7];
set_location_assignment PIN_AB13    -to switch[8];
set_location_assignment PIN_AB12    -to switch[9];

# set key pad row
set_location_assignment PIN_F13     -to keyPadRow[3];
set_location_assignment PIN_G16     -to keyPadRow[2];
set_location_assignment PIN_G13     -to keyPadRow[1];
set_location_assignment PIN_J17     -to keyPadRow[0];

# set key pad col
set_location_assignment PIN_K16     -to keyPadCol[3];
set_location_assignment PIN_G12     -to keyPadCol[2];
set_location_assignment PIN_G15     -to keyPadCol[1];
set_location_assignment PIN_F12     -to keyPadCol[0];
