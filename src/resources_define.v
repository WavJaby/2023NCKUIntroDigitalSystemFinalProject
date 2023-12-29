`define imageBitdepth 16
`define imageW(index) ((`imgWidth>>((index)<<4))&16'hFFFF)
`define imageH(index) ((`imgHeight>>((index)<<4))&16'hFFFF)
`define image(index,x,y) [((((`itemStart>>(index)*24)&24'hFFFFFF)+((x)+(y)*`imageW(index)))<<4)+:16]
// item0(sphere.png): 16x16
// item1(brick.png): 16x6
`define itemStart 48'h000100000000
`define imgWidth 32'h00100010
`define imgHeight 32'h00060010
`define rom0ItemCount 2
`define rom0Length 5632