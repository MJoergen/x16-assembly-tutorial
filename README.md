# Assembly Tutorial
This is a step-by-step guide for how to write a simple game in assembly for the
Commander X16.

## Prerequisites
* You need to install the X16 emulator [release
  0.36](https://github.com/commanderx16/x16-emulator/releases/tag/r36).  Just
  download the zip-file for your system, and unpack it. The zip-file contains
  the emulator 'x16emu' and the ROM image 'rom.bin'.
* You also need to install the cc65 tool chain [version
  2.18](https://github.com/cc65/cc65/releases/tag/V2.18). Some linux
  distributions may already include the cc65 package. If that is the case, it
  may be an older version, but that should not pose any problems.

## Prior knowledge assumed
* I will assume you have some basic knowledge of BASIC programming. In
  particular, you can read and follow along the
  [TENNIS](https://github.com/MJoergen/x16-examples/blob/master/TENNIS.BAS)
  program written in BASIC.
* This will not be a primer on 65C02 assembly language. I assume you have access
  to other material explaining registers, adressing modes, etc for the 65C02
  processor.

## What this tutorial covers
* Where to begin, when writing a new game in assembly.
* What steps to take, and in which order, so as to keep the project 'alive',
  i.e.  so you don't get stuck and have to give up.

## Episodes
The tutorial is arranged into a sequence of episodes, where each episode adds a
new feature to the game. You are highly encouraged to make your own changes as
you go along, so as to "personalize" the game for yourself.  Experimenting with
modifying an existing program is a great way to learn.

* [Episode 1 - The initial scene](Episode_1): The bare minimum, where the
  initial scene is displayed.
* [Episode 2 - The player](Episode_2): Here we add the Player to the game.
* [Episode 3 - The ball - part 1](Episode_3): Here we add movement of the Ball.
* [Episode 4 - The ball - part 2](Episode_4): Here we add collision handling of the Ball.
* [Episode 5 - The bot](Episode_5): Here we add a bot to the game.
* [Episode 6 - The scoring](Episode_6): Here we add a score to the game.

It is important that each feature is added one-at-a-time and tested and
debugged and verified, before proceeding to the next episode. This is one key
way to manage the project and to avoid having a half-finished game, where
nothing really works.

