// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/04/Mult.asm

// Multiplies R0 and R1 and stores the result in R2.
// (R0, R1, R2 refer to RAM[0], RAM[1], and RAM[2], respectively.)
//
// This program only needs to handle arguments that satisfy
// R0 >= 0, R1 >= 0, and R0*R1 < 32768.
//res = 0;
@0
D=A
@R2
M=D
//i = 0;
@0
D=A
@i
M=D

//if(R0 == 0 || R1 == 0) return 0;
@R0
D=M
@END
D; JEQ
@R1
D=M
@END
D; JEQ

//while(i < R0) {
(LOOP)
  @R0
  D=M
  @i
  D=D-M;
  @END
  D; JEQ

  //res += R1;
  @R2
  D=M
  @R1
  D=D+M
  @R2
  M=D

  //i++;
  @i
  M=M+1;
  @LOOP
  0; JMP
//}
(END)
@END
0; JMP
