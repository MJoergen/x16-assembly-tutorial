X16EMU    = ~/git/commanderx16/x16-emulator/x16emu
ROM       = ~/git/commanderx16/x16-rom/build/x16/rom.bin
OPTIONS_R = -scale 2 -keymap nordic
OPTIONS_C = --mapfile tennis.map

all:
	ca65 --cpu 65c02 tennis.s
	ca65 --cpu 65c02 sprite.s
	ca65 --cpu 65c02 player.s
	ca65 --cpu 65c02 bot.s
	ca65 --cpu 65c02 score.s
	ca65 --cpu 65c02 ball.s
	ca65 --cpu 65c02 math.s
	ca65 --cpu 65c02 collision.s
	cl65 -C ld.cfg $(OPTIONS_C) tennis.o sprite.o player.o bot.o score.o ball.o collision.o math.o

run:
	$(X16EMU) -rom $(ROM) -prg tennis.prg -run $(OPTIONS_R)

clean:
	rm -rf *.o
	rm -rf tennis.prg
	rm -rf tennis.map

