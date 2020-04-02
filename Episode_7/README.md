# Episode 7 : Music

This is the seventh episode of the tutorial explaining how to write a TENNIS
game in assembly language for the Commander X16.

In this episode we will add music to the game.

## The YM2151 chip
The sound on the X16 is controlled by the YM2151 chip. I have written a
separate [tutorial](https://github.com/MJoergen/x16-ym2151-tutorial) on now to
make sounds on this chip, so suffice to say here that the chip supports up to
eight simultaneous channels.

## Arranging music
For those new to music the first thing to consider is how to arrange the music,
i.e.  which sound channels should play which notes, and when.

In this project we'll be using five sound channels: One for the melody, one for the bass, and
three for the accompanying chords. The musical score will be arranged in lines,
where each line corresponds to 1/16 of a bar. Each line will consist
of five bytes, one for each channel. A channel may either:
* Play a new note
* Keep the same note as before (i.e. do nothing).
* Go silent

This gets translated into commands to the YM2151 chip:
* Send Key Off => channel goes silent.
* Set Key Code => change the note to play.
* Send Key On  => channel starts playing new note.

## music\_init
The initialization code must initialize the five sound channels on the YM2151 chip,
including volume (actually attenuation) of each channel, as well as the timbre.
As I said, I won't go into any details here, but the initalization consists
of a number of writes to various registers internal in the YM2151.

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
counter does not match, then just return immediately. Using the jiffie counter
ensures that the music will be played at a regular pace. The tempo can be adjusted
by the constant MUSIC\_TIMER\_STEP, which is the number of jiffies allocated
for each 1/16 of a bar.

