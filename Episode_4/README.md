# Episode 4 : The ball - part 2

This is the fourth episode of the tutorial explaining how to write a TENNIS
game in assembly language for the Commander X16.

In this episode we will add collision handling to the ball. This is going
to be a very long episode, so strap up!

## Types of collisions
There are three types of collisions to be handled in this game:

* Collision with line. These are the walls (left, right, and top) as well as
  the barrier (left, right, and top).
* Collision with corner. These are the left and right corners of the barrier.
* Collision with semicircle. These are the player and the bot.

The three collision types are similar, yet different. They will therefore need
to be treated separately.  To keep the source files nice and tidy, I've decided
to move all the collision handling to a separate file collision.s.  So in the
file ball.s, I've just added the following calls:

```
; Handle collisions
jsr collision_left_wall
jsr collision_right_wall
jsr collision_top_wall
jsr collision_left_barrier
jsr collision_right_barrier
jsr collision_top_barrier
jsr collision_left_corner
jsr collision_right_corner
jsr collision_player
```

## Discrete nature of movement
Before we proceed we must stress one thing that complicates the collision
handling: The updates are discrete nature, i.e. collision handling is called at
regular discrete intervals (60 times a second). This means that at the time the
collision function is called the ball has moved slightly *past* the point of
collision. And if the speed of the ball is large, the ball may have propagated
quite far into the other object. Remember, the speed is measured in pixels pr
time step, and if the speed is, say, 8, then the ball will have moved up to 8
pixels *into* the object, and possibly through the object.  To avoid strange
things happening during collisions, it is therefore imperative that the speed
of the ball is not too great. One way to achieve this is to have more updates,
i.e. to have smaller time steps.  This should not be necessary in this game,
but is worth keeping in mind as an option, if the collision handling is not
quite working as expected.

Another complication is that the ball may undergo multiple collision events in
the same update. For instance, it may happen that the ball is colliding with a
wall, but is moving away from the wall. This should not be possible under
normal circumstances, but may happen - again due to the discrete nature of the
movement.

## Collision with line
The nice thing with the lines in this game is that they are all horizontal or
vertical, i.e. parallel to the coordinate axes. This makes the collision
handling much simpler.

Take the left wall first. When the X-coordinate of the ball's left-hand-side
becomes less than SCENE\_LEFT, then we know the ball has collided with the
wall.   If furthermore the x-component of the velocity is negative, we know the
ball has a direction towards the wall, and we therefore replace the x-component
with the absolute value. We leave the y-component unchanged.

Is it really necessary with this extra check for the sign of the x-component?
Well, yes it is, because there may be other collision events happening
simultaneously, e.g. if the ball collides with both the wall and the player.
In that case the ball may be "inside" the wall for several frames, and we must
make sure the final direction of the ball is away from the wall.

So for instance, checking for collision with the left wall is as easy as
the following:

```
collision_left_wall:
         ldy #0
         ldx #<(SCENE_LEFT+BALL_RADIUS)
         lda #>(SCENE_LEFT+BALL_RADIUS)
         jsr compare_pos_x
         bcc return              ; Return if no collision

         ; Collision detected, now check velocity
         lda ball_vel_x+2
         bpl return              ; Return if moving right

         jmp negate_vel_x
return:  rts
```

Note how I need to adjust the wall's position with the radius of the ball. This
is because the balls position is the center of the ball.

Here I'm calling a utility function compare\_pos\_x, which simply compares the
16.8 bit value in A:X.Y with the balls X-position.

I'm using yet another utility function negate\_vel\_x, which negates the
X-component of the velocity. Using these utility functions makes the code more
readable, simply because the function name describes the intent of the code.

The other walls are treated in much the same way.

The barrier is slightly more complicated, because the barrier is actually quite
thin.  So to check if the ball is inside the barrier, we need to check an
*interval* on the X-axis, as well as checking the Y-coordinate.  This all looks
like the following:

```
collision_left_barrier:
         ; First check the y-component
         ldy #0
         ldx #<(BARRIER_TOP)
         lda #>(BARRIER_TOP)
         jsr compare_pos_y
         bcs return              ; Return if no collision

         ; Check left side of barrier
         ldy #0
         ldx #<(BARRIER_LEFT-BALL_RADIUS)
         lda #>(BARRIER_LEFT-BALL_RADIUS)
         jsr compare_pos_x
         bcs return              ; Return if no collision

         ; Check middle of barrier
         ldy #0
         ldx #<((BARRIER_LEFT+BARRIER_RIGHT)/2)
         lda #>((BARRIER_LEFT+BARRIER_RIGHT)/2)
         jsr compare_pos_x
         bcc return              ; Return if no collision

         ; Collision detected, now check velocity
         lda ball_vel_x+2
         bmi return              ; Return if moving left

         jmp negate_vel_x        ; Change sign of X-component of velocity
```

## Collision with corner and with player
Corner collision and player collision is much more complicated, so we'll need
to break it down into a number of steps. Fortunately, they are very similar,
so they can be treated simultaneously.

### The physics
Let's start with the physics of collisions, in particular collision with a
corner. Let V be the velocity of the ball, and let DP be the vector from the
center of the ball to the point of collision (the corner).  Both V and DP are
two-dimensional vectors. If the angle between V and DP is zero, then the ball
is headed straight towards the collision point, whereas if the angle between
the two vectors is 180 degress then the ball is moving straight away from the
collision point.

Collision has occurred when the collision point is inside the ball, i.e. when
the length of DP is less than the radius of the ball, i.e. DP^2 <
ball\_radius^2. We calculate the length squared of DP, so as to avoid having to
calculate a square root.

Furthermore, if the ball is moving away from the collision point, then we'll
ignore the collision. This is the case if the angle between V and DP is greater
than 90 degrees.

When a collision happens the velocity V must be updated, but the new velocity
has to have the same magnitude as before.  The change in velocity (due to the
force of the collision) must furthermore be in the direction of -DP.

So we have the following two equations, where DV is the change in velocity and
V+DV is the new velocity after the collision:

1. (V+DV)\*(V+DV) = V^2
2. DV = -T\*DP

where T is a scalar quantity (single value, not a vector) yet to be determined.

Equation 1 above is derived from conservation of kinetic energy, whereas
equation 2 is related to Newton's second law: Change in momentum is
proportional to force.

After some simplifications, we get the following equation determining the value
of T:

T = 2\*V\*DP/(DP\*DP)

where V\*DP is the vector product, i.e. V\_x\*DP\_x + V\_y\*DP\_y.  A
negative value of T corresponds to the ball moving away from the collision
point.

Just a note on collision with player. We don't have the coordinates of the
collision point, but it turns out that only the above equations only rely on
the *direction* towards the collision point, and so for DP we can use the
vector from the center of the ball to the center of the player.  And collision
then occurs when the length of this vector is less than the combined radii of
the ball and the player.

### The algorithm
To translate the above algebra into assembly language, it is useful to first
break down the calculation into a number of steps.

1. Calculate DP\_x = Point\_x - Ball\_x.
2. Calculate DP\_y = Point\_y - Ball\_y.
3. Calculate R2 = Ball\_radius^2 or (Ball\_radius+Player\_radius)^2.
4. Calculate Len2 = |DP\_x|^2 + |DP\_y|^2.
5. Compare R2 with Len2. Return if less than.
6. Calculate P = Vel\_x\*DP\_x + Vel\_y\*DP\_y. Return if negative.
7. Calculate T = 2\*P/Len2.
8. Calculate DV\_x = -T\*DP\_x and add to Vel\_x.
9. Calculate DV\_y = -T\*DP\_y and add to Vel\_y.

It turns out the value of P can be stored in the processor registers, because
it is used only once, right after it is calculated. The other variables need to
be stored in memory, so we get the following declarations in collision.s:

```
.bss
; Temporary variables used during collision handling.
collision_dp_x : .res 3    ; X-displacement from ball to collision point.
collision_dp_y : .res 3    ; Y-displacement from ball to collision point.
collision_r2   : .res 3    ; Radius squared of ball.
collision_len2 : .res 3    ; Len2=DP_x^2+DP_y^2.
collision_t    : .res 3    ; T=2*P/Len2.
```

Note that all numbers are 3 bytes in size and use the 16.8 fractional
representation.

### Example
Before we move on, it's useful to look at a concrete numerical example:
Consider the ball traveling vertically down towards the left corner of the
barrier. When it reaches the left corner, we may have the following values
(given both in decimal and in the 16.8 bit representation):

|  Variable  |   Value   |  16.8 bit  |
|  --------  |  -------  |  --------  |
| `Vel_x`    | ` 0.0000` | `0000.00`  |
| `Vel_y`    | ` 3.0625` | `0003.10`  |
| `DP_x`     | ` 2.0000` | `0002.00`  |
| `DP_y`     | ` 6.2500` | `0006.40`  |
| `Len2`     | `43.0625` | `002B.10`  |
| `P`        | `19.1406` | `0013.24`  |
| `T`        | ` 0.8890` | `0000.E4`  |
| `DV_x`     | `-1.7779` | `FFFE.39`  |
| `DV_y`     | `-5.5561` | `FFFA.72`  |
| `NewV_x`   | `-1.7779` | `FFFE.39`  |
| `NewV_y`   | `-2.4936` | `FFFD.82`  |

First of all, note that the square root of Len2 gives 6.6, which is less than
the radius of the ball. So here we see concretely, that the ball has travelled
almost two pixels *into* the corner. This is consistent with the value of Vel,
which is just over 3 pixels pr time step.

To check the consistency (and accuracy) of the calculation, the kinetic energy
before and after should be the same.  The old kinetic energy is calculated as
Vel\_x^2 + Vel\_y^2 = 0.0000^2 + 3.0625^2 = 9.3789.  The new kinetic energy is
calculated as NewV\_x^2 + NewV\_y^2 = (-1.7779)^2 + (-2.4936)^2 = 9.3789.

One thing to note here is the value of T is quite small, and the accuracy is
therefore pretty bad, since we're only using 8 bits. We could try to scale the
values to get a better range, i.e. more bits to represent the value of T,
but instead I've decided to keep things simple and to always round up the value
of T, i.e. to round away from zero.

### Range of values
Before we go into the details of implementation, let's look more detailed into the
possible ranges of the values in the table above. As mentioned before, the
ball's velocity is in pixels pr. time step, and it seems reasonable to demand
that the ball doesn't move further than its own radius within a single time
step.  So |Vel\_xy| is less than 8.

|DP\_xy| is less than 8 when considering collision between ball and point,
because it is the distance from center of ball to collision point. However,
when we consider collision with the player, the collision point will be the
center of the player, and so |DP\_xy| can be up to 8+16=24. Therefore Len2
can be up to 24^2=576 (for collision with player) or 8^2=64 (for collision with
corner).

The maximum value of |P| is when Vel and DP are parallel. Then |P| can be up to
8\*24=192 (for collision with player) or 8\*8=64 (for collision with corner).

The maximum value of |T| will be 2\*192/576=0.7 (for collision with player) or
2\*64/64=2 (for collision with corner).

The maximum value of |DV| will be 16 in both cases, which corresponds to twice
the value of |V|.

In summary we have the following table of maximal values in the two different
collision situations:

|  Variable  | Max corner | Max player |
|  --------  |  -------   |  --------  |
| `Vel_xy`   | ` 8`       | `  8  `    |
| `DP_xy`    | ` 8`       | ` 24  `    |
| `Len2`     | `64`       | `576  `    |
| `P`        | `64`       | `192  `    |
| `T`        | ` 2`       | `  0.7`    |
| `DV`       | `16`       | `16   `    |

From the above we conclude that T always fits in an 8.8 bit representation.

### The math routines
Staying true to the philosophy of keeping the source files readable and of
manageable size, I've decided to place all the low-level math routines (e.g.
multiply and divide) in a separate file math.s.

The main math routines we'll need are multiply and divide. To keep things
generic and readable, I've decided to introduce two source arguments in the
math.s file (math\_arg0 and math\_arg1) and two destination accumulators
(math\_res\_mult and math\_res\_div), and to provide functions that access
these variables. In other words, it is not "allowed" to read/write the
arguments and accumulators directly. This does introduce a lot more function
calls, but I believe the code ends up more readable.

The collision code therefore makes use of the following functions, found in
math.s:
* math\_store\_to\_arg0
* math\_store\_to\_arg1
* math\_multiply
* math\_multiply\_add
* math\_divide
* math\_load\_from\_mult
* math\_load\_from\_div
* math\_cmp\_with\_mult
* math\_negate
* math\_abs
* math\_double
* math\_increase

The functions math\_multiply and math\_multiply\_add perform the following calculations:
* math\_multiply      : MUL = ACC0\*ACC1
* math\_multiply\_add : MUL += ACC0\*ACC1

For instance, step 6 calculating P is achieved by the following lines:
```
; Step 6. Calculate P = Vel_x*DP_x + Vel_y*DP_y. Return if negative.
ldy ball_vel_x
ldx ball_vel_x+1
lda ball_vel_x+2
jsr math_store_to_arg0
ldy collision_dp_x
ldx collision_dp_x+1
lda collision_dp_x+2
jsr math_store_to_arg1
jsr math_multiply

ldy ball_vel_y
ldx ball_vel_y+1
lda ball_vel_y+2
jsr math_store_to_arg0
ldy collision_dp_y
ldx collision_dp_y+1
lda collision_dp_y+2
jsr math_store_to_arg1
jsr math_multiply_add

jsr math_load_from_mult       ; Get P
bpl :+
rts                           ; Return if negative
:
```

I find the above code reasonably easy to read and self-documenting.

### math.s
In the file math.s we have the following declarations:
```
.bss
math_arg0     : .res 3   ; 16.8 bit representation
math_arg1     : .res 3   ; 16.8 bit representation
math_res_mult : .res 3   ; 16.8 bit representation
math_res_div  : .res 3   ; 16.8 bit representation
math_tmp      : .res 1   ; Temporary
```

For the multiplication part, we'll be assuming that math\_arg0 and math\_arg1
are within +/- 128. This simplifies the implementation nicely, because we can
completely ignore the MSB.

The multiplication algorithm works by repeated addition of ARG1. The inner
algorithm requires ARG0 to be positive. Therefore, we must initially check if
ARG0 is negative, and if so, we negate both ARG0 and ARG1.  The loop runs 16
times, and shifts ARG0 to the right and ARG1 to the left.

The division algorithm works just like regular old-school long division, by
repeated subtraction and shifting.

## Testing the collision code
In this episode I've decided to temporarily allow the player to move all over
the scene. So in player.s I've replaced BARRIER\_LEFT with SCENE\_RIGHT.  This
will have to be changed back when the game is finished, but for now it is nice
to be able to test the collision.

So this episode has been very long, but it was necessary to cover a lot of
material in order to get something that can be tested.

Before we finish we must have some mechanism to detect when the player misses
the ball. I've therefore added the following lines to tennis.s

```
   jsr collision_bottom
   bcs :+               ; Jump if no collision
   jsr ball_reset
:
```

The function collision\_bottom compares the balls Y-coordinate with the bottom
of the scene, and the function ball\_reset resets the Y-coordinate of the ball
as well as the velocity. Later on, this is where we'll add the scoring mechanism.

In the next episode we'll add a simple bot.

