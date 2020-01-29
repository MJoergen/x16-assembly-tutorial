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

.code

music_init:
         ldy #$00
         ldx #YM2151_REG_TL
:        lda music_total_level,y
         jsr music_write
         iny
         inx
         cpy #4
         bne :-

         ldy #$00
         ldx #YM2151_REG_AR
:        lda music_attack_rate,y
         jsr music_write
         iny
         inx
         cpy #4
         bne :-

         ldy #$00
         ldx #YM2151_REG_D1R
:        lda music_decay_rate,y
         jsr music_write
         iny
         inx
         cpy #4
         bne :-

         ldy #$00
         ldx #YM2151_REG_RR
:        lda music_release_rate,y
         jsr music_write
         iny
         inx
         cpy #4
         bne :-

         ldy #$00
         ldx #YM2151_REG_CON
:        lda music_connection,y
         jsr music_write
         iny
         inx
         cpy #4
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

:        ; Send "Key off" event to the chip.
         ldx #YM2151_REG_SM
         lda #YM2151_KEYOFF
         jsr music_write

         ; Get next note to play
:        lda (music_pointer)
         beq @duration
         cmp #$ff
         bne @note
         jsr music_pointer_reset
         bra :-

@note:
         jsr music_note

@duration:
         jsr music_inc_pointer
         lda (music_pointer)
         jsr music_duration
         
         ; Get chord
         jsr music_inc_pointer
         lda (music_pointer)
         beq :+
         jsr music_chord
:

; Fall through to music_inc_pointer

music_inc_pointer:
         inc music_pointer
         bne :+
         inc music_pointer+1
:        rts         

         ; Play the next note
music_note:
         ldx #YM2151_REG_KC
         jsr music_write
         ldx #YM2151_REG_SM
         lda #YM2151_KEYON
         jsr music_write
         rts

         ; Send timeout for next event
music_duration:
         asl
         asl
         asl
         adc music_time                ; Carry is always clear here.

         ; Calculate mod 60.
:        cmp #60
         bcc @store
         sbc #60                       ; Carry is always set here.
         bra :-

@store:
         sta music_time
         rts

         ; Play the chord
music_chord:

         ; First send "Key Off" event for the chord.
         pha
         ldx #YM2151_REG_SM
         lda #YM2151_KEYOFF+1
         jsr music_write
         ldx #YM2151_REG_SM
         lda #YM2151_KEYOFF+2
         jsr music_write
         ldx #YM2151_REG_SM
         lda #YM2151_KEYOFF+3
         jsr music_write
         pla

         ; Set the notes of the chord
         cmp #$41
         beq @d_minor
         cmp #$3E
         beq @c_major
         rts

@d_minor:
         ldx #YM2151_REG_KC+1
         lda music_chord_d_minor
         jsr music_write
         inx
         lda music_chord_d_minor+1
         jsr music_write
         inx
         lda music_chord_d_minor+1
         jsr music_write
         bra @chord_key_on

@c_major:
         ldx #YM2151_REG_KC+1
         lda music_chord_c_major
         jsr music_write
         inx
         lda music_chord_c_major+1
         jsr music_write
         inx
         lda music_chord_c_major+1
         jsr music_write

         ; Send "Key on" event for the chord.
@chord_key_on:
         ldx #YM2151_REG_SM
         lda #YM2151_KEYON+1
         jsr music_write
         ldx #YM2151_REG_SM
         lda #YM2151_KEYON+2
         jsr music_write
         ldx #YM2151_REG_SM
         lda #YM2151_KEYON+3
         jsr music_write
         rts

music_write:
         stx YM2151_ADDR
         sta YM2151_VAL
         rts


; This is the initialization data for the channels of the YM2151 chip.

music_total_level:
.byt $00; Channel 0
.byt $08; Channel 1
.byt $08; Channel 2
.byt $08; Channel 3

music_attack_rate:
.byt $1F; Channel 0
.byt $1F; Channel 1
.byt $1F; Channel 2
.byt $1F; Channel 3

music_decay_rate:
.byt $0B; Channel 0
.byt $07; Channel 1
.byt $07; Channel 2
.byt $07; Channel 3

music_release_rate:
.byt $FF; Channel 0
.byt $FF; Channel 1
.byt $FF; Channel 2
.byt $FF; Channel 3

music_connection:
.byt $E7; Channel 0
.byt $D7; Channel 1
.byt $D7; Channel 2
.byt $D7; Channel 3


; This is the two chords used in this tune.
music_chord_d_minor:
.byt $41; Channel 1
.byt $45; Channel 2
.byt $4A; Channel 3

music_chord_c_major:
.byt $3E; Channel 1
.byt $44; Channel 2
.byt $48; Channel 3


; This is the musical score of the tune "Ievan Polkka".
; Three bytes in each line:
; First byte is the note
; Second byte is the duration
; Third byte is the chord
music_data:
.byt $51, 1, 0
.byt $4A, 2, $41
.byt $51, 2, 0
.byt $51, 3, 0
.byt $54, 1, 0
.byt $55, 2, $41
.byt $51, 2, 0
.byt $51, 2, 0
.byt $55, 1, 0
.byt $55, 1, 0
.byt $54, 2, $3E
.byt $4E, 2, 0
.byt $4E, 2, 0
.byt $54, 2, 0
.byt $55, 2, $41
.byt $51, 2, 0
.byt $51, 3, 0
.byt $51, 1, 0
.byt $4A, 2, $41
.byt $51, 2, 0
.byt $51, 3, 0
.byt $54, 1, 0
.byt $55, 2, $41
.byt $51, 2, 0
.byt $51, 2, 0
.byt $55, 1, 0
.byt $55, 1, 0
.byt $5A, 2, $3E
.byt $58, 2, 0
.byt $55, 2, 0
.byt $54, 2, 0
.byt $55, 2, $41
.byt $51, 2, 0
.byt $51, 3, 0
.byt $51, 1, 0
.byt $5A, 2, $41
.byt $5A, 2, 0
.byt $58, 2, 0
.byt $55, 2, 0
.byt $58, 2, $3E
.byt $54, 2, 0
.byt $54, 3, 0
.byt $54, 1, 0
.byt $58, 2, $3E
.byt $58, 2, 0
.byt $55, 2, 0
.byt $54, 2, 0
.byt $55, 2, $41
.byt $51, 2, 0
.byt $51, 3, 0
.byt $51, 1, 0
.byt $5A, 2, $41
.byt $5A, 2, 0
.byt $58, 2, 0
.byt $55, 2, 0
.byt $58, 2, $3E
.byt $54, 2, 0
.byt $54, 3, 0
.byt $54, 1, 0
.byt $58, 1, $3E
.byt $58, 1, 0
.byt $58, 2, 0
.byt $55, 2, 0
.byt $54, 2, 0
.byt $51, 4, $41
.byt $51, 3, 0
.byt $FF                               ; Repeat

