# Episode 2 : The player

This is the second episode of the tutorial explaining how to write a TENNIS
game in assembly language for the Commander X16.

In this episode we will add the player to the game. This includes defining a
sprite, getting movements from the joystick/keybaord, and moving the sprite
around.

## The main loop (in tennis.s)
Let's first look at the main loop. In the main loop, all the game objects get
updated.  So in the file tennis.s you'll see these lines:

```
@main_loop:
         jsr player_update
         jsr wait_for_timer_interrupt
         jsr kernal_stop_key  ; Test for STOP key
         bne @main_loop
```

The player\_update function takes care of the user input, and of moving the
player sprite around. Each call moves the sprite a fixed amount, so to get a
smooth movement on the screen, we need to control how often this function gets
called. We can do this by making use of the VERA VSYNC interrupt, which occurs
60 times a second. We won't need to write any interrupt service handler;
instead we rely on the existing kernal interrupt handler that updates the
current time of day.  This is taken care of in the function
wait\_for\_timer\_interrupt, which returns only when the time of day has
changed due to an interrupt. More on this function in a moment.

Next we call another kernal function, which checks whether we press the STOP
key (in the emulator this is CTRL-C). This function returns equal-to-zero, if
the user wants to stop the game.

Calling kernal functions is easy, but you do have to define the address
yourself. So in the file tennis.inc I've added references to the kernal
functions I'm using. I've chosen to prefix all the names with "kernal\_",
because a good naming convention makes the program easier to read and maintain.

So far, we only have a player, but later we'll add calls to ball\_update,
bot\_update, etc. And that's it. The main loop is done, and we now look at
the function wait\_for\_timer\_interrupt and later how to program the player.

## wait\_for\_timer\_interrupt

I'll just briefly go over this routine. The kernal provides a function that
returns the current date and time, with a resolution of 1/60 seconds.  Instead
of allowing direct access to the kernal's internal variables (which are subject
to change), the kernal API is designed so that the kernal functions copy the
desired values to some designated registers in zero page. In this case, calling
the function kernal\_clock\_get\_date\_time copies the jiffie counter to the
zero page address $08. So the idea is to repeatedly call the kernal function
and check when the jiffie counter gets updated. Then we know a VERA VSYNC
interrupt has just occurred.

```
         jsr kernal_clock_get_date_time
         lda $08              ; Get the jiffie counter (60 Hz)
         sta tennis_timer

         ; Repeat until timer is updated
:        jsr kernal_clock_get_date_time
         lda $08
         cmp tennis_timer
         beq :-
         rts
```

## Declaring variables

The variable tennis\_timer is one of many temporary variables we'll need in
this program. We need to declare the variable in the tennis.s file, so the following
lines appear near the beginning.

```
.bss
tennis_timer : .res 1

.code
```

The instruction ".res 1" simply means to reserve one byte. The lines ".bss" and
".code" are segment commands. The reason is that variables, like tennis\_timer,
should not be initialized and should not even be part of the .prg file. In fact
they should be placed in a different memory segment alltogether. The command
".bss" means "everything following should be placed in the segment reserved
for uninitiailzed variables", whereas the command ".code" means "everything
following should be placed in the segment reserved for program code". This
is the default, at the beginning of each file.

I've chosen to prefix the variable name with "tennis\_" to indicate this is a
variable defined in the file tennis.s.

## Updates to ld.cfg
The linker must be instructed where in memory the uninitialized variables
should go.  This is achieved by adding the following lines to the linker script
ld.cfg:

```
MEMORY
{
   BSS:
      start $0400
      size  $0400
      type  rw
      file  "";
}

SEGMENTS
{
   BSS:
      load  BSS
      type  rw;
}
```

This reserves 1 kB of variables in the memory area $0400 to $07FF.

## Updates to tennis.inc
This file, which contains various global constants, is the perfect place to
store the pixel coordinates of the various parts of the screen.

```
; Game constants
PLAYER_RADIUS = 16
SCENE_LEFT    = 8
SCENE_RIGHT   = 640-8
SCENE_TOP     = 8
SCENE_BOTTOM  = 480
BARRIER_LEFT  = 320-8
BARRIER_RIGHT = 320
BARRIER_TOP   = 480-8*10
```

Notice that SCENE\_LEFT, SCENE\_RIGHT, and SCENE\_TOP have been adjusted for
the width (8 pixels) of the wall.


## Sprites
The bitmap data for the sprites are stored in Video RAM. There is no fixed
memorymap for the Video RAM, but the default settings places the screen
characters in the address range $00000 to $03BFF. I've therefore chosen to
place the sprite data from address $03C00 and onwards.

Since both the player and the bot will be using the same sprite bitmap, I've
decided to split the sprite data initialization into a separate file sprite.s.
This file is nice and short and provides a single function sprite\_init.  I've
decided to draw the player and bot sprites as a semicircle with a radius of 16
pixels. This leads to a 32x16 pixel sprite for the player.

A sprite may have either 4 or 8 colour bits per pixel. I've decided on 8 bits
per pixel, because this is simply 1 byte per pixel. This is grossly overkill,
but it's a small game so there is an abundant amount of Video RAM.

## The player
The player is implemented in the file player.s. It provides two functions:
player\_init, which is called once at startup, and player\_update, which is
called once every VSYNC, i.e. 60 times a second.

I've chosen to maintain local copies (in player\_pos\_x and player\_pos\_y) of
the position of the player sprite.  Technically, this is duplicating data,
because the VERA contains the same information.  Duplication of data is
discouraged, because it requires manual management to ensure that both copies
are always in sync with each other. In other words, whenever the local copy is
updated, the same data must be copied to the VERA.  However, the benifit is
that accessing data from the VERA is cumbersome, particularly in the middle of
some calculation.

One twist though is that I've chosen to translate the sprite coordinates so the
local copies point to the "center" of the player, i.e. the center of the
semicircle. This is to later on simplify the functions handling collision.
However, this is yet another layer of complexity the programmer must be aware
of, so there is a cost.

Looking now into the player\_init function, we see that the sprite coordinates
must be aligned correctly. So the x,y value poked into the VERA is the top left
corner of the sprite. To ensure the sprite is correctly placed, we must
calculately the position of the top left corner of the sprite. This essentially
corresponds to subtracting PLAYER\_RADIUS from both the X- and Y-coordinates.

Now the player\_update function is quite simple. We call yet another kernal
function to determine whether the arrow keys are pressed, and then branch out
accordingly. We either shift right or left by some fixed amount, here defined
in the constant PLAYER\_SPEED to have the value 3. Since this occurs 60 times a
second, the actual speed on the screen is 180 pixels/second. 

## Updates to the Makefile
I've added some more features to the Makefile, so it is now possieble to type
"make run" to start the emulator and run the program. Furthermore, you can type
"make clean", and all the generated files will be deleted.  I've furthermore
added the option "--mapfile tennis.map" to the linker. This generates a text
file with all the exported symbols. This can be useful when debugging.

