; This file controls the music.
;
; LICENSE: This program is public domain, and you may do anything and
; everything with it.
;
; Note, the musical score is of the tune "Ievan Polkka".
; The arrangement is created by Harley Volkova, see this video:
; https://www.youtube.com/watch?v=Tct2kV1gjZg

.include "kernal.inc"
.include "tennis.inc"

; External API

.export music_init
.export music_update

.import ym2151_channel_init
.import ym2151_keyon
.import ym2151_keyoff
.import ym2151_keycode

; This controls the tempo of the music. Number of jiffies per 1/16 of a bar.
MUSIC_TIMER_STEP = 8

; Number of channels used
MUSIC_CHANNELS = 5


;
; This section contains variables that are uninitialized at start.
;
.bss
music_time    : .res 1                 ; Jiffie counter.


;
; This section contains zero-page variables that are uninitialized at start.
;
.segment "ZP" : zeropage
music_pointer : .res 2                 ; Current position in music score.


.code

;
; This function is called once at startup. It sets up the YM2151
; to make it ready to play music.
;

music_init:
         ; Initialize sound channels
         lda #>music_chan0
         ldx #<music_chan0
         ldy #$00
         jsr ym2151_channel_init

         lda #>music_chan1
         ldx #<music_chan1
         ldy #$01
         jsr ym2151_channel_init

         lda #>music_chan2
         ldx #<music_chan2
         ldy #$02
         jsr ym2151_channel_init

         lda #>music_chan3
         ldx #<music_chan3
         ldy #$03
         jsr ym2151_channel_init

         lda #>music_chan4
         ldx #<music_chan4
         ldy #$04
         jsr ym2151_channel_init

         ; Initialize current time.
         jsr kernal_clock_get_date_time
         lda $08
         sta music_time

         ; Initialize pointer to musical score.
         ldx #<music_data
         lda #>music_data
         stx music_pointer
         sta music_pointer+1
         rts


;
; This function is called repeatedly, once every jiffie.
;

music_update:
         ; Check whether it is time to do something.
         jsr kernal_clock_get_date_time
         lda $08
         cmp music_time
         beq :+
         rts
:
         ; Process next line of the musical score
         ldy #0
@next_chan:
         lda (music_pointer),y
         cmp #$fe                      ; Check if loop back to beginning
         beq @loop

         cmp #$ff                      ; Check if note is same as previous
         beq :+                        ; If so, do nothing.
         jsr music_note                ; Play the new note.
:
         iny
         cpy #MUSIC_CHANNELS
         bne @next_chan                ; Loop over all channels.

         jsr music_pointer_update      ; Go to next line in music score.
         jsr music_time_update         ; Set timer for next event.
         rts

@loop:
         ; Load new value of pointer
         iny
         lda (music_pointer),y
         tax
         iny
         lda (music_pointer),y
         stx music_pointer
         sta music_pointer+1
         ldy #0
         bra @next_chan                ; Read line again


music_pointer_update:
         lda music_pointer
         clc
         adc #MUSIC_CHANNELS
         sta music_pointer
         bcc :+
         inc music_pointer+1
:        rts


music_time_update:
         lda music_time
         clc
         adc #MUSIC_TIMER_STEP
         cmp #60                       ; Calculate mod 60.
         bcc :+
         sbc #60                       ; Carry is always set here.
:        sta music_time
         rts


; Play a note.
; On entry: A is the note to play, Y is the channel to play on.
; If A = 0, then don't play a note.
music_note:
         pha                           ; Store the note for later.
         jsr ym2151_keyoff             ; Send "Key off" event to the chip.
         pla                           ; Retrieve the note.
         beq :+                        ; Jump if no key to play.
         jsr ym2151_keycode            ; Set Key Code
         jsr ym2151_keyon              ; Send "Key on" event to the chip.
:        rts


; This is the initialization data for the channels of the YM2151 chip.

music_chan0:                           ; MELODY
.byt $E7, $00, $00, $00                ; Connect
.byt $00, $00, $00, $00                ; DT1 and MUL
.byt $00, $00, $00, $00                ; Total Level
.byt $1F, $00, $00, $00                ; Attack Rate
.byt $0B, $00, $00, $00                ; First Decay Rate
.byt $00, $00, $00, $00                ; Second Decay Rate
.byt $FF, $00, $00, $00                ; Release Rate

music_chan1:                           ; BASS
.byt $D7, $00, $00, $00                ; Connect
.byt $00, $00, $00, $00                ; DT1 and MUL
.byt $02, $00, $00, $00                ; Total Level
.byt $1F, $00, $00, $00                ; Attack Rate
.byt $07, $00, $00, $00                ; First Decay Rate
.byt $00, $00, $00, $00                ; Second Decay Rate
.byt $FF, $00, $00, $00                ; Release Rate

music_chan2:                           ; CHORD (FIRST NOTE)
.byt $D7, $00, $00, $00                ; Connect
.byt $00, $00, $00, $00                ; DT1 and MUL
.byt $02, $00, $00, $00                ; Total Level
.byt $1F, $00, $00, $00                ; Attack Rate
.byt $07, $00, $00, $00                ; First Decay Rate
.byt $00, $00, $00, $00                ; Second Decay Rate
.byt $FF, $00, $00, $00                ; Release Rate

music_chan3:                           ; CHORD (SECOND NOTE)
.byt $D7, $00, $00, $00                ; Connect
.byt $00, $00, $00, $00                ; DT1 and MUL
.byt $02, $00, $00, $00                ; Total Level
.byt $1F, $00, $00, $00                ; Attack Rate
.byt $07, $00, $00, $00                ; First Decay Rate
.byt $00, $00, $00, $00                ; Second Decay Rate
.byt $FF, $00, $00, $00                ; Release Rate

music_chan4:                           ; CHORD (THIRD NOTE)
.byt $D7, $00, $00, $00                ; Connect
.byt $00, $00, $00, $00                ; DT1 and MUL
.byt $02, $00, $00, $00                ; Total Level
.byt $1F, $00, $00, $00                ; Attack Rate
.byt $07, $00, $00, $00                ; First Decay Rate
.byt $00, $00, $00, $00                ; Second Decay Rate
.byt $FF, $00, $00, $00                ; Release Rate



; Five bytes in each line, one for each channel.
; Each line corresponds to 1/16 of a bar.
; $00 means silence.
; $FF means continue previous note.
; $FE means loop back to address following.
music_data:

;
; INTRO
;
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
.byt $FF, $FF, $FF, $FF, $FF
.byt $51, $FF, $FF, $FF, $FF

music_loop:
;
; PART A
;
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

;
; PART A (again)
;
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

;
; PART B
;
.byt $5A, $FF, $41, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $61, $FF, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $61, $FF, $3A, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $FF, $3E, $FF, $FF
.byt $64, $FF, $FF, $FF, $FF
.byt $65, $FF, $41, $FF, $FF
.byt $65, $FF, $FF, $FF, $FF
.byt $61, $FF, $FF, $FF, $FF
.byt $61, $FF, $FF, $FF, $FF
.byt $61, $FF, $3A, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $61, $FF, $3E, $FF, $FF
.byt $65, $FF, $FF, $FF, $FF

.byt $64, $FF, $3A, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $5E, $FF, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $5E, $FF, $3E, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $64, $FF, $3A, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $65, $FF, $41, $FF, $FF
.byt $65, $FF, $FF, $FF, $FF
.byt $61, $FF, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $61, $FF, $3A, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $FF, $3E, $FF, $FF
.byt $61, $FF, $FF, $FF, $FF

.byt $5A, $FF, $41, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $61, $FF, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $61, $FF, $3A, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $FF, $3E, $FF, $FF
.byt $64, $FF, $FF, $FF, $FF
.byt $65, $FF, $41, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $61, $FF, $FF, $FF, $FF
.byt $61, $FF, $FF, $FF, $FF
.byt $61, $FF, $3A, $FF, $FF
.byt $61, $FF, $FF, $FF, $FF
.byt $61, $FF, $3E, $FF, $FF
.byt $65, $FF, $FF, $FF, $FF

.byt $6A, $FF, $3A, $FF, $FF
.byt $6A, $FF, $FF, $FF, $FF
.byt $6A, $FF, $FF, $FF, $FF
.byt $68, $FF, $FF, $FF, $FF
.byt $65, $FF, $3E, $FF, $FF
.byt $65, $FF, $FF, $FF, $FF
.byt $64, $FF, $3A, $FF, $FF
.byt $64, $FF, $FF, $FF, $FF
.byt $65, $FF, $41, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $61, $FF, $FF, $FF, $FF
.byt $61, $FF, $FF, $FF, $FF
.byt $61, $FF, $3A, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $61, $FF, $3E, $FF, $FF
.byt $65, $FF, $FF, $FF, $FF

.byt $6A, $FF, $41, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $6A, $FF, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $68, $FF, $3A, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $65, $FF, $3E, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $64, $FF, $3A, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $5E, $FF, $FF, $FF, $FF
.byt $5E, $FF, $FF, $FF, $FF
.byt $5E, $FF, $3A, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $5E, $FF, $3E, $FF, $FF
.byt $64, $FF, $FF, $FF, $FF

.byt $68, $FF, $3A, $FF, $FF
.byt $68, $FF, $FF, $FF, $FF
.byt $68, $FF, $FF, $FF, $FF
.byt $68, $FF, $FF, $FF, $FF
.byt $65, $FF, $3E, $FF, $FF
.byt $65, $FF, $FF, $FF, $FF
.byt $64, $FF, $3A, $FF, $FF
.byt $64, $FF, $FF, $FF, $FF
.byt $65, $FF, $41, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $61, $FF, $FF, $FF, $FF
.byt $61, $FF, $FF, $FF, $FF
.byt $61, $FF, $3A, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $FF, $3E, $FF, $FF
.byt $61, $FF, $FF, $FF, $FF

.byt $6A, $FF, $41, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $6A, $FF, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $68, $FF, $3A, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $65, $FF, $3E, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $64, $FF, $3A, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $5E, $FF, $FF, $FF, $FF
.byt $5E, $FF, $FF, $FF, $FF
.byt $5E, $FF, $3A, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $5E, $FF, $3E, $FF, $FF
.byt $64, $FF, $FF, $FF, $FF

.byt $68, $FF, $3A, $FF, $FF
.byt $68, $FF, $FF, $FF, $FF
.byt $68, $FF, $FF, $FF, $FF
.byt $68, $FF, $FF, $FF, $FF
.byt $65, $FF, $3E, $FF, $FF
.byt $65, $FF, $FF, $FF, $FF
.byt $64, $FF, $3A, $FF, $FF
.byt $64, $FF, $FF, $FF, $FF
.byt $65, $FF, $41, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $61, $FF, $FF, $FF, $FF
.byt $61, $FF, $FF, $FF, $FF
.byt $61, $FF, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $FF, $FF, $FF, $FF, $FF
.byt $51, $FF, $FF, $FF, $FF

.byt $FE                               ; Repeat
.word music_loop


