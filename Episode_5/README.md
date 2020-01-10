# Episode 5 : The bot

This is the fifth episode of the tutorial explaining how to write a TENNIS
game in assembly language for the Commander X16.

In this episode we will add a bot to compete against. This is a fairly straight
foward operation with a few minor additions.

## tennis.s
Let's first look at the changes to tennis.s. This amounts to inserting calls to
bot\_init and bot\_update at the same places as player\_init and player\_bot.

## tennis.inc
Similarly, we add definitions of BOT\_SPEED and BOT\_RADIUS to tennis.inc

## ball.s
Here we insert a call to collision\_bot.

## collision.s
Here we define the function collision\_bot, which mirrors collision\_player.

## Makefile
We insert the line
```
ca65 --cpu 65c02 bot.s
```

## player.s
And of course we must remember to adjust the boundaries of the player from
SCENE\_RIGHT to BARRIER\_LEFT.

## bot.s
So this leaves the new file bot.s containing the two functions bot\_init and
bot\_update.

### bot\_init
The function bot\_init is very similar to player\_init, except now we're using
sprite index 2 at VERA address $F5010, and a new colour.

### bot\_update
This is the "intelligence" of the bot, where it decides in which direction to
move.  For now, the bot simply aims slightly to the right of the ball, so that
a collision will tend to push the ball towards the player.

So first we calculate the target position for the bot, i.e. the position the
bot is aiming for. And then we move the bot towards that position, while
respecting the speed of movement and the boundaries.

In a later episode, we'll give the bot a more intelligent strategy.

And that's it for this episode! We now have something that is almost playable,
so in the next episode we'll add scoring.

