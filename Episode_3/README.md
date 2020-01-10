# Episode 3 : The ball - part 1

This is the third episode of the tutorial explaining how to write a TENNIS
game in assembly language for the Commander X16.

In this and the next episode we will add the moving ball. I've decided to
splite the ball programming in two episodes, because the collision handling is
quite complicated.  So in this first part we will just focus on getting the
ball moving on the screen.  Collision handling is done in the next episode.

## Sprite data
Let's first add the sprite data for the ball. This is just a simple
modification to the sprite.s file. We must remember to keep track of the
address in Video RAM of the sprite data for the ball. Since the player sprite
uses $0200 bytes, the ball sprite data will be at $03E00..

## Fractional velocities
Before we do any more coding we need to introduce fractional velocities. The
reason is that velocities can be small but non-zero, and the current resolution
of 1 pixel pr. frame is way too coarse. This would result in very jerky
movement of the ball.

So for the velocities I've chosen a three-byte representation, where two bytes
are for the integer part, and one byte is for the fractional part in units of
1/256.  This means the value $001080 has an integer part of $0010, i.e. 16, and
a fractional part of $80/256, i,e, the value is 16.5.  With this three-byte
representation, the smallest non-zero velocity is 1/256 pixels pr frame, which
is approximately 1/4 pixel pr second.  That seems adequate for this game.
This representation is sometimes written as "16.8 representation", meaning 16
bits for the integer part and 8 bits for the fractonal part.

You might ask why two bytes for the integer part? Well, this is the easy way of
dealing with negative numbers. So an integer part of $FFFF corresponds to the
value -1.

The key learning here is that on an 8-bit cpu we should always take into
consideration the limited range of our values.  We could go to the other
extreme and use regular floating-point values for velocities, but this would be
way overkill.

And we must not forget that since we are storing the values in little-endian
format, the first byte is the fractional part, and the two following bytes are
the integer part. We could choose a different byte-ordering, but little-endian
is the most common byte ordering on 65C02.

Since the velocities are fractional we need fractional coordinates as well.
Again, we'll use one extra byte for the fractional part, so the X- and
Y-coordinates will be three bytes each.

## Getting the ball on the screen
The function ball\_init is very similar to player\_init, except for a few modifications,
including:

* Different address in Video RAM ($F5008 instead of $F5000).
* Different sprite location in Video RAM ($03E00 instead of $03C00).
* Different sprite size (16x16 instead of 32x16).
* Different colour.

We must remember to call ball\_init from tennis.s and we must remember to modify
the Makefile.

This is enough to get the ball displaying on the screen. But before we
close this episode, let's get the ball moving.

## Gravity
In tennis.inc I've added the constant GRAVITY, which is the value of the
acceleration measured in 1/256 parts of a pixel pr frame pr frame. So on every
frame the vertical velocity increses with GRAVITY/256 pixels pr frame. So after
1 second the velocity has increased with approx GRAVITY/4 pixels pr frame,
which is the same as 15\*GRAVITY pixels pr second. So a rather small value of
GRAVITY seems appropriate, e.g. 12.

The gravity is applied in the function ball\_update, where first velocity is
added to the position, and then gravity is added to the velocity. After that
the ball sprite position is updated. And remember that the first byte is the
fractional part, and we must translate the X,Y position from the center of the
ball to the top-left pixel in the sprite data.

Now the ball should gradually fall down. At the moment, it will pass right
through the player, because there is no collision handling yet. This is the
topic for the next episode.

