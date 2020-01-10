# Episode 6 : The score

This is the sixth episode of the tutorial explaining how to write a TENNIS
game in assembly language for the Commander X16.

In this episode we will add scoring.

## tennis.s
Again let's start from the high level view and look at the main loop in tennis.s.
Here we've added the lines:

```
   ; Ok, the ball has been lost.
   ; We figure out who missed the ball,
   ; and update the score accordingly.
   ldy #0
   ldx #<((BARRIER_LEFT+BARRIER_RIGHT)/2)
   lda #>((BARRIER_LEFT+BARRIER_RIGHT)/2)
   jsr collision_compare_pos_x
   bcc :+

   jsr score_decrement_player
   beq @game_over
   bra @reset
:
   jsr score_decrement_bot
   beq @game_over
@reset:
   jsr ball_reset
```

So when a ball has been lost (through the bottom of the scene) we compare the
X-position with the middle of the barrier to determine who missed the ball.
Then we call one of the functions score\_decrement\_player or
score\_decrement\_bot.

Note how we make use of the function collision\_compare\_pos\_x already defined
in the file collision.s.

So far the @game\_over label just returns from the game. In a later episode,
we'll add a high score list to be displayed at this time.

## sprite.s
This file has been updated with the 32x32 heart sprite, which will reside in
VERA memory at the address $03F00.

## Makefile
Here we add the line

```
ca65 --cpu 65c02 score.s
```

## score.s
The file score.s implements the following functions:

```
score_init
score_decrement_player
score_decrement_bot
```

and defines the following local variables:

```
.bss
; Current score of player and bot.
score_player : .res 1
score_bot    : .res 1
```

The score\_init function initializes the lives to 3 each, and then initializes
a total of six sprites (three each) using two loops. The coordinates of the
sprites are calculated individually.

The functions score\_decrement\_player and score\_decrement\_bot decrement
the corresponding score variable and calls the common function score\_disable\_sprite.
Finally they check for whether the score has become zero.

The function score\_disable\_sprite takes as argument the sprite number to disable
and calculates the corresponding VERA address to zero out.

## Next steps
We have a playable game now. Here is a list of possible next steps:

* Gradually increase the speed of the game. This can be done simply by
  increasing the gravity. 
* Introduce randomness in collisions.
* Make a better bot.
* Add a high score list.

