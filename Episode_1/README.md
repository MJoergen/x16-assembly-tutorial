# Episode 1 : Hello World!

This is the first episode of the tutorial explaining how to write a TENNIS game
in assembly language for the Commander X16.

In this first episode, we will configure the project and get all the files
necessary to build a working executable. The actual functionality will be
pretty simple: Clear the screen and draw the playing field.  It is important to
set small manageable goals at each stage of the project!

## Organizing the source code
It is important to keep your source files organized, to avoid the entire
project becoming one big mess. In this project, we'll be having a player, a
ball, and a bot. Each object will appear on the screen as a sprite, and each
object will be controlled by a single source file. So I expect we'll at least
have source files named player.s, ball.s, and bot.s, controlling each of the
three objects in the game. For now, we'll just have a single source file
'tennis.s', which contains the initialization code and the main game loop.

## tennis.s
In this first episode we'll only have one source file tennis.s. It starts with
the line

```
.include "tennis.inc"
```

This includes another file in this project, which will contain various constants used
throughout the game. In this first episode that file contains the addresses for
the VERA registers.  It is wise to keep constants defined in a single place,
rather than have your code littered with funny constants everywhere.

Then follows the well-known auto-launcher sequence, which basically consists of
a small BASIC program with the single line

```
1 SYS 2061
```

The auto-launcher is implemented by the following lines:

```
.org $07FF                    ; Start address for assembler
.byt $01, $08                 ; Start address of program
.byt $0B, $08                 ; Start address of next line
.byt $01, $00                 ; Line number 1
.byt $9E                      ; SYS token
.byt "2061"                   ; $080D in decimal
.byt $00                      ; End of line
.byt $00, $00                 ; End of BASIC program
```

The first line ".org" tells the assembler where the program starts. You might have
expected the value $0801 here, but the reason is that .prg files must start
with a two-byte sequence containing the load address of the program.

The actual assembly code after the auto-launcher consists of the lines

```
jsr scene_init
rts
```

Later, we'll add calls to player\_init, ball\_init, etc, as well as have the
main game loop here as well. It's good programming style to split the code into
functions with a well-defined purpose. You could argue that there is no need to
move the scene\_init to a separate function, because it is only ever used once.
But it helps to keep your code organized, plus the name of the function serves
a dual purpose of documenting the purpose of function.

The actual initialization performed here is to clear the screen and to draw the
left, right, and top borders, as well as the barrier in the middle. I've chosen the
method where I don't actually bother with the characters, but only fill the
colour attributes of each screen character. It makes the program slightly
smaller.

So on the VERA, each character on the screen uses two bytes, one for the
PETSCII character code (on the even addresses), and one for the colour index
(on the odd addresses). Each character takes two bytes, and each line takes 256
bytes, even though only the first 160 bytes (80 characters) are visible. So the
top left corner is addresses $00000 and $00001, while the row just below starts
at $00100.

Clearing the screen is accomplished by setting the colour attribute of each
character to blue-on-blue (i.e. $66), while the walls are drawn by setting the
colour attribute to white-on-white (i.e. $11). So any text previously on the
screen is still there, it is just not visible!

## ld.cfg
The file ld.cfg is a linker script used to instruct the linker where each part
of the program goes. For this tutorial a simple script suffices:

```
MEMORY
{
   # This section contains the actual program file.
   CODE:
      start $07FF
      size  $8000
      type  ro
      file  "tennis.prg";
}

SEGMENTS
{
   CODE:
      load  CODE
      type  ro;
}
```

This script tells the linker that anything in the CODE segment (which is the
default), is to be placed in a block of memory also named CODE, and which
starts at address $07FF, and the contents should be written to the file
"tennis.prg". Here again the value $07FF appears, which is because the first
two bytes of the file is the loading address, and the following bytes are to be
placed in address $0801 and onwards.


## Building the .prg file
To build the .prg file, issue the following two commands:

```
	ca65 --cpu 65c02 tennis.s
	cl65 -C ld.cfg tennis.o
```

I've added a short Makefile (which is basically a programmable script), which
contains these two commands, so you can just type 'make' to build the .prg
file.

## Testing the program
It's important to continuously test the program to make sure everything works
as expected, before you proceed to the next episode. It's possible to load the
.prg file directly when the emulator starts up, by using the command line
option "-prg tennis.prg", and you can even add the command line option "-run"
so the program automatically runs. So the complete command line is:
```
x16emu -rom rom.bin -prg tennis.prg -run
```

## Congratulations!
In this first episode, you can now draw the initial playing screen. It is very
helpful to test the code you write as early as possible. That is why we
end this episode of the tutorial here. In the next episode, we will add the
player.

## Next step
I suggest you play around with the code so far. Here are some suggestions for
further investigation:
* Use different colours.
* Draw the left and white walls thicker (i.e. two characters).
* Draw a top wall.

