; This file controls the music.
;
; LICENSE: This program is public domain, and you may do anything and
; everything with it.

; External API

.export music_init
.export music_update

.include "tennis.inc"

; This section contains variables that are uninitialized at start.
.bss
; Time for next event.
music_time    : .res 1   ; Jiffie counter.

; This section contains zero-page variables that are uninitialized at start.
.segment "ZP" : zeropage
; Current position in music score.
music_pointer : .res 2

; This controls the tempo of the music. Number of jiffies per eighth of a bar.
MUSIC_TIMER_STEP = 8

; Number of channels used
MUSIC_CHANNELS = 5

.code

music_init:
         ldy #$00
         ldx #YM2151_REG_TL
:        lda music_total_level,y
         jsr music_write
         iny
         inx
         cpy #MUSIC_CHANNELS
         bne :-

         ldy #$00
         ldx #YM2151_REG_AR
:        lda music_attack_rate,y
         jsr music_write
         iny
         inx
         cpy #MUSIC_CHANNELS
         bne :-

         ldy #$00
         ldx #YM2151_REG_D1R
:        lda music_decay_rate,y
         jsr music_write
         iny
         inx
         cpy #MUSIC_CHANNELS
         bne :-

         ldy #$00
         ldx #YM2151_REG_RR
:        lda music_release_rate,y
         jsr music_write
         iny
         inx
         cpy #MUSIC_CHANNELS
         bne :-

         ldy #$00
         ldx #YM2151_REG_CON
:        lda music_connection,y
         jsr music_write
         iny
         inx
         cpy #MUSIC_CHANNELS
         bne :-

         ; Initialize current time.
         jsr kernal_clock_get_date_time
         lda $08
         sta music_time
; Fall through to music_pointer_reset.


music_pointer_reset:
         ; Initialize pointer to musical score.
         ldx #<music_data
         lda #>music_data
         stx music_pointer
         sta music_pointer+1
         rts


music_update:
         jsr kernal_clock_get_date_time
         lda $08
         cmp music_time
         beq :+
         rts
:
         ldy #0
@next_chan:
         lda (music_pointer),y
         cmp #$fe                      ; Check if loop back to beginning
         bne :+

         ; Load new value of pointer
         iny
         lda (music_pointer),y
         tax
         iny
         lda (music_pointer),y
         stx music_pointer
         sta music_pointer+1
         ldy #0
         bra @next_chan                ; Read again
:         
         cmp #$ff                      ; Check if note is same as previous
         beq @skip_note                ; If so, do nothing.
         jsr music_note                ; Play the new note.

@skip_note:         
         iny
         cpy #MUSIC_CHANNELS
         bne @next_chan                ; Loop over all channels.

         ; Increment pointer
         lda music_pointer
         clc
         adc #MUSIC_CHANNELS
         sta music_pointer
         bcc :+
         inc music_pointer+1
: 

         ; Set timer
         lda music_time
         clc
         adc #MUSIC_TIMER_STEP
:        cmp #60                       ; Calculate mod 60.
         bcc :+
         sbc #60                       ; Carry is always set here.
         bra :-
:
         sta music_time                ; Carry is always clear here.
         rts


; Play a note.
; On entry: A is the note to play, Y is the channel to play on.
; If A = 0, then don't play a note.
music_note:
         pha                           ; Store the note for later.
         ; Send "Key off" event to the chip.
         lda val_keyoff,y              ; A short-hand way of calculating A = YM2151_KEYOFF + Y.
         ldx #YM2151_REG_SM
         jsr music_write
         pla                           ; Retrieve the note.
         bne :+                        ; Should this channel be silent now?
         rts                           ; If so, just return.
:
         ; Set Key Code
         ldx reg_kc,y                  ; A short-hand way of calculating X = YM2151_REG_KC + Y.
         jsr music_write

         ; Send "Key on" event to the chip.
         lda val_keyon,y               ; A short-hand way of calculating A = YM2151_KEYON + Y.
         ldx #YM2151_REG_SM
         jsr music_write
         rts

; Write to a register in the chip.
music_write:
         stx YM2151_ADDR
         sta YM2151_VAL
         rts

reg_kc:
.byt YM2151_REG_KC
.byt YM2151_REG_KC+1
.byt YM2151_REG_KC+2
.byt YM2151_REG_KC+3
.byt YM2151_REG_KC+4

val_keyoff:
.byt YM2151_KEYOFF
.byt YM2151_KEYOFF+1
.byt YM2151_KEYOFF+2
.byt YM2151_KEYOFF+3
.byt YM2151_KEYOFF+4

val_keyon:
.byt YM2151_KEYON
.byt YM2151_KEYON+1
.byt YM2151_KEYON+2
.byt YM2151_KEYON+3
.byt YM2151_KEYON+4


; This is the initialization data for the channels of the YM2151 chip.

music_total_level:
.byt $00; Channel 0
.byt $02; Channel 1
.byt $08; Channel 2
.byt $08; Channel 3
.byt $08; Channel 4

music_attack_rate:
.byt $1F; Channel 0
.byt $1F; Channel 1
.byt $1F; Channel 2
.byt $1F; Channel 3
.byt $1F; Channel 4

music_decay_rate:
.byt $0B; Channel 0
.byt $07; Channel 1
.byt $07; Channel 2
.byt $07; Channel 3
.byt $07; Channel 4

music_release_rate:
.byt $FF; Channel 0
.byt $FF; Channel 1
.byt $FF; Channel 2
.byt $FF; Channel 3
.byt $FF; Channel 4

music_connection:
.byt $E7; Channel 0
.byt $D7; Channel 1
.byt $D7; Channel 2
.byt $D7; Channel 3
.byt $D7; Channel 4


; This is the musical score of the tune "Ievan Polkka".
; Four bytes in each line, one for each channel.
; Each line corresponds to one eighth of a bar.
; $00 means silence.
; $FF means continue previous note.
music_data:
.byt $FF, $31, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $FF, $41, $45, $4A
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $2A, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $FF, $41, $45, $4A
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $31, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $FF, $41, $45, $4A
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $2A, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $FF, $41, $45, $4A
.byt $FF, $FF, $FF, $FF, $FF

.byt $FF, $31, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $FF, $41, $45, $4A
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $2A, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $FF, $41, $45, $4A
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $31, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $FF, $41, $45, $4A
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $2A, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $FF, $41, $45, $4A
.byt $FF, $FF, $FF, $FF, $FF

.byt $FF, $31, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $FF, $41, $45, $4A
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $2A, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $FF, $41, $45, $4A
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $31, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $FF, $41, $45, $4A
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $2A, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $FF, $41, $45, $4A
.byt $FF, $FF, $FF, $FF, $FF

.byt $FF, $31, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $FF, $41, $45, $4A
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $2A, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $FF, $41, $45, $4A
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $31, $41, $45, $4A
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $51, $FF, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF

music_loop:
.byt $4A, $31, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $51, $FF, $41, $45, $4A
.byt $FF, $FF, $FF, $FF, $FF
.byt $51, $2A, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $FF, $41, $45, $4A
.byt $54, $FF, $FF, $FF, $FF
.byt $55, $31, $FF, $FF, $FF
.byt $55, $FF, $FF, $FF, $FF
.byt $51, $FF, $41, $45, $4A
.byt $51, $FF, $FF, $FF, $FF
.byt $51, $2A, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $51, $FF, $41, $45, $4A
.byt $55, $FF, $FF, $FF, $FF

.byt $54, $2E, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $4E, $FF, $3E, $44, $4A
.byt $FF, $FF, $FF, $FF, $FF
.byt $4E, $2A, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $54, $FF, $3E, $44, $4A
.byt $FF, $FF, $FF, $FF, $FF
.byt $55, $31, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $51, $FF, $41, $45, $4A
.byt $FF, $FF, $FF, $FF, $FF
.byt $51, $2A, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $51, $FF, $41, $45, $4A
.byt $51, $FF, $FF, $FF, $FF

.byt $4A, $31, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $51, $FF, $41, $45, $4A
.byt $FF, $FF, $FF, $FF, $FF
.byt $51, $2A, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $FF, $41, $45, $4A
.byt $54, $FF, $FF, $FF, $FF
.byt $55, $31, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $51, $FF, $41, $45, $4A
.byt $51, $FF, $FF, $FF, $FF
.byt $51, $2A, $FF, $FF, $FF
.byt $51, $FF, $FF, $FF, $FF
.byt $51, $FF, $41, $45, $4A
.byt $55, $FF, $FF, $FF, $FF

.byt $5A, $2E, $FF, $FF, $FF
.byt $5A, $FF, $FF, $FF, $FF
.byt $5A, $FF, $3E, $44, $4A
.byt $58, $FF, $FF, $FF, $FF
.byt $55, $2A, $FF, $FF, $FF
.byt $55, $FF, $FF, $FF, $FF
.byt $54, $FF, $3E, $44, $4A
.byt $54, $FF, $FF, $FF, $FF
.byt $55, $31, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $51, $FF, $41, $45, $4A
.byt $FF, $FF, $FF, $FF, $FF
.byt $51, $2A, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $51, $FF, $41, $45, $4A
.byt $55, $FF, $FF, $FF, $FF

.byt $5A, $31, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $5A, $FF, $41, $45, $4A
.byt $FF, $FF, $FF, $FF, $FF
.byt $58, $2A, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $55, $FF, $41, $45, $4A
.byt $FF, $FF, $FF, $FF, $FF
.byt $54, $2E, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $4E, $FF, $3E, $44, $4A
.byt $4E, $FF, $FF, $FF, $FF
.byt $4E, $2A, $FF, $FF, $FF
.byt $4E, $FF, $FF, $FF, $FF
.byt $4E, $FF, $3E, $44, $4A
.byt $54, $FF, $FF, $FF, $FF

.byt $58, $2E, $FF, $FF, $FF
.byt $58, $FF, $FF, $FF, $FF
.byt $58, $FF, $3E, $44, $4A
.byt $58, $FF, $FF, $FF, $FF
.byt $55, $2A, $FF, $FF, $FF
.byt $55, $FF, $FF, $FF, $FF
.byt $54, $FF, $3E, $44, $4A
.byt $54, $FF, $FF, $FF, $FF
.byt $55, $31, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $51, $FF, $41, $45, $4A
.byt $51, $FF, $FF, $FF, $FF
.byt $51, $2A, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $FF, $41, $45, $4A
.byt $55, $FF, $FF, $FF, $FF

.byt $5A, $31, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $5A, $FF, $41, $45, $4A
.byt $FF, $FF, $FF, $FF, $FF
.byt $58, $2A, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $55, $FF, $41, $45, $4A
.byt $FF, $FF, $FF, $FF, $FF
.byt $54, $2E, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $4E, $FF, $3E, $44, $4A
.byt $FF, $FF, $FF, $FF, $FF
.byt $4E, $2A, $FF, $FF, $FF
.byt $54, $FF, $FF, $FF, $FF
.byt $54, $FF, $3E, $44, $4A
.byt $54, $FF, $FF, $FF, $FF

.byt $58, $2E, $FF, $FF, $FF
.byt $58, $FF, $FF, $FF, $FF
.byt $58, $FF, $3E, $44, $4A
.byt $58, $FF, $FF, $FF, $FF
.byt $55, $2A, $FF, $FF, $FF
.byt $55, $FF, $FF, $FF, $FF
.byt $54, $FF, $3E, $44, $4A
.byt $54, $FF, $FF, $FF, $FF
.byt $55, $31, $41, $45, $4A
.byt $FF, $FF, $FF, $FF, $FF
.byt $51, $FF, $FF, $FF, $FF
.byt $51, $FF, $FF, $FF, $FF
.byt $51, $FF, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $51, $FF, $FF, $FF, $FF

.byt $FE                               ; Repeat
.word music_loop


