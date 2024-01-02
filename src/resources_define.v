`define imageBitdepth 16
`define imageW(index) ((`imgWidth>>((index)<<4))&16'hFFFF)
`define imageH(index) ((`imgHeight>>((index)<<4))&16'hFFFF)
`define image(index,x,y) [((((`itemStart>>((index)*20))&20'hFFFFF)+((x)+(y)*`imageW(index)))<<4)+:16]
// item0(sphere.png): 16x16
// item1(brick.png): 16x6
`define itemStart 40'h0010000000
`define imgWidth 32'h00100010
`define imgHeight 32'h00060010
`define rom0ItemCount 2
`define rom0Length 5632

`define fontLength 4606
`define fontCharHeight 7
`define fontCharMaxWidth 7
`define fontOff_33 0 // !
`define fontOff_34 1 // "
`define fontOff_35 2 // #
`define fontOff_36 3 // $
`define fontOff_37 4 // %
`define fontOff_38 5 // &
`define fontOff_39 6 // '
`define fontOff_40 7 // (
`define fontOff_41 8 // )
`define fontOff_42 9 // *
`define fontOff_43 10 // +
`define fontOff_44 11 // ,
`define fontOff_45 12 // -
`define fontOff_46 13 // .
`define fontOff_47 14 // /
`define fontOff_58 25 // :
`define fontOff_59 26 // ;
`define fontOff_60 27 // <
`define fontOff_61 28 // =
`define fontOff_62 29 // >
`define fontOff_63 30 // ?
`define fontOff_64 31 // @
`define fontOff_91 58 // [
`define fontOff_92 59 // \
`define fontOff_93 60 // ]
`define fontOff_94 61 // ^
`define fontOff_95 62 // _
`define fontOff_96 63 // `
`define fontOff_123 90 // {
`define fontOff_124 91 // |
`define fontOff_125 92 // }
`define fontOff_126 93 // ~
`define fontDigitStart 80'h1817161514131211100f
`define fontDigitOff(digit) ((`fontDigitStart>>((digit)<<3))&8'hFF)
`define fontLetterStart 416'h595857565554535251504f4e4d4c4b4a49484746454443424140393837363534333231302f2e2d2c2b2a29282726252423222120
`define fontLetterOff(letter) (letter>"Z"?((`fontLetterStart>>((letter-71)<<3))&8'hFF):((`fontLetterStart>>((letter-"A")<<3))&8'hFF))
`define fontCharStart 1880'h0028b002840027d002760026f00268002610025a002530024c002450023e002370023000229002220021b002140020d00206001ff001f8001f1001ea001e3001dc001d5001ce001c7001c0001b9001b2001ab001a40019d001960018f00188001810017a001730016c001650015e001570015000149001420013b001340012d001260011f00118001110010a00103000fc000f5000ee000e7000e0000d9000d2000cb000c4000bd000b6000af000a8000a10009a000930008c000850007e000770007000069000620005b000540004d000460003f00038000310002a000230001c000150000e0000700000
`define fontChar(index,x,y) [(y)*658+(x)+((`fontCharStart>>((index)*20))&20'hFFFFF)+:1]
`define fontCharWidth 1504'h0007000700070007000700070007000700070007000700070007000700070007000700070007000700070007000700070007000700070007000700070007000700070007000700070007000700070007000700070007000700070007000700070007000700070007000700070007000700070007000700070007000700070007000700070007000700070007000700070007000700070007000700070007000700070007000700070007000700070007000700070007000700070007
`define fontCharW(index) ((`fontCharWidth>>((index)<<4))&16'hFFFF)

`define randomLen 8
`define randomList 8'h13
