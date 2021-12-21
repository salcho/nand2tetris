// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/04/Fill.asm

// Runs an infinite loop that listens to the keyboard input.
// When a key is pressed (any key), the program blackens the screen,
// i.e. writes "black" in every pixel;
// the screen should remain fully black as long as the key is pressed. 
// When no key is pressed, the program clears the screen, i.e. writes
// "white" in every pixel;
// the screen should remain fully clear as long as no key is pressed.

//while(true) {
(LOOP)
  // key = RAM[KEYBOARD]
  @KBD
  D=M
  //if (!key) white()
  @WHITE
  D; JEQ

//  black()
  @BLACK
  0; JMP
//}

(WHITE)
// i=0
@0
D=A
@i
M=D
// while (i<8k)
  (FILL_WHITE)
  @i
  D=M
  @8192 // 8k+1
  D=A-D
  @LOOP
  D; JEQ
  // screen[i] = 0;
  @SCREEN
  D=A
  @i
  D=D+M
  A=D
  M=0
  // i++
  @i
  D=M
  D=D+1
  M=D
// }
@FILL_WHITE
0; JMP

(BLACK)
// i=0
@0
D=A
@i
M=D
// while (i<8k)
  (FILL_BLACK)
  @i
  D=M
  @8192 // 8k+1
  D=A-D
  @LOOP
  D; JEQ
  // screen[i] = -1;
  @SCREEN
  D=A
  @i
  D=D+M
  A=D
  M=-1
  // i++
  @i
  D=M
  D=D+1
  M=D
// }
@FILL_BLACK
0; JMP
