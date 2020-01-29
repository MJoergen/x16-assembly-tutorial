# Episode 7 : Music

This is the seventh episode of the tutorial explaining how to write a TENNIS
game in assembly language for the Commander X16.

In this episode we will add music to the game.

## The YM2151 chip
The sound on the X16 is controlled by the YM2151 chip. I will write a separate
tutorial on now to make sounds on this chip, so suffice to say here that the
chip supports up to eight simultaneous channels.

## Arranging music
For those new to music the first thing to consider is how to arrange the music,
i.e.  which sound channels should play which notes, and when.

In this project we'll be using four sound channels: One for the melody and
three for the accompanying chords. The musical score will consist of a single
table containing:
* The note to be played.
* The duration of the note.
* The accompanying chord.

## music\_init
The initialization code must initialize the four sound channels on the YM2151 chip,
including volume (actually attenuation) of each channel, as well as the timbre.
As I said, I won't go into any details here, but the initalization consists
of a number of writes to various registers internal in the YM2151.

These writes could have been arranged in a number of different ways, including
one large table with (address, value) pairs. The layout I've chosen makes it
easier (I believe) to make changes to the initialization values, as well as
providing at least a small amount of documentation for the purpose of each
write.

The initialization routine must initialize the current timeout, which controls
when the next note is to be played. This again makes use of the kernal function
clock\_get\_date\_time. Only the jiffie value is used.

The final task during initialization is to store the pointer to the first entry
in the musical score. Note that this pointer, declared at the top of the file,
is put into a separate segment ZP with the additional qualifier "zeropage" (see
line 19). This qualifier is an instruction to the assembler and the linker that
the pointer should be placed in a zeropage locaation. We will need that when
reading from the pointer. I've subsequently updated the linker script ld.cfg.

## music\_update
The first step is to check if anything at all needs to be done. The variable
music\_time contains the time for the next musical event, so if the current jiffie
counter does not match, then just return immediately.

The sequence of events following is to first send a "Key Off" event to the
chip, then setup the new note (and possibly chord) to play, and finally to send
a "Key On" event to the chip.

Each of the three bytes in the musical score is processed separately:
* music\_note
* music\_duration
* music\_chord

