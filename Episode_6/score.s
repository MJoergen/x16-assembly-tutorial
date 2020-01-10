; This file controls the score
;
; LICENSE: This program is public domain, and you may do anything and
; everything with it.

; External API

.export score_init
.export score_decrement_player
.export score_decrement_bot

; This section contains variables that are uninitialized at start.
.bss
; Current score of player and bot.
score_player : .res 1
score_bot    : .res 1


.code
.include "tennis.inc"

;
; This function is called repeatedly. It handles keyboard input and
; moves the player on the screen.
;

score_decrement_player:
         dec score_player
         lda score_player
         clc
         adc #3                        ; Player score starts at sprite #3
         jsr score_disable_sprite
         lda score_player
         rts

score_decrement_bot:
         dec score_bot
         lda score_bot
         clc
         adc #6                        ; Bot score starts at sprite #6
         jsr score_disable_sprite
         lda score_bot
         rts

score_disable_sprite:
         asl                           ; Multiply by eight
         asl
         asl

         clc
         adc #6
         tay
         ldx #$50
         lda #$1F
         sta VERAHI
         stx VERAMID
         sty VERALO
         stz VERADAT0                  ; Disable sprite
         rts


;
; This initialization routine is called once at start of the game.
;
score_init:
         lda #3
         sta score_player
         sta score_bot

         lda #$1F                      ; Set increment to 1, and address to $F5018
         ldx #$50
         ldy #$18
         sta VERAHI
         stx VERAMID
         sty VERALO

         ; Configure players score sprites (#3-#5)
         ldy #3
         ldx #88

:        lda #$F8                      ; Set sprite data address to $03F00
         sta VERADAT0
         lda #$81
         sta VERADAT0

         txa
         sta VERADAT0
         lda #0
         sta VERADAT0
         lda #88
         sta VERADAT0
         lda #0
         sta VERADAT0

         lda #$0C                      ; Set Z-depth to 3 (in front of layer 1)
         sta VERADAT0
         lda #$AE                      ; Set sprite size to 32x32, and colour index to E
         sta VERADAT0

         txa
         clc
         adc #40
         tax
         dey
         bne :-

         ; Configure bots score sprites (#6-#8)
         ldy #3
         ldx #128

:        lda #$F8                      ; Set sprite data address to $03F00
         sta VERADAT0
         lda #$81
         sta VERADAT0

         txa
         sta VERADAT0
         lda #1
         sta VERADAT0
         lda #88
         sta VERADAT0
         lda #0
         sta VERADAT0

         lda #$0C                      ; Set Z-depth to 3 (in front of layer 1)
         sta VERADAT0
         lda #$AE                      ; Set sprite size to 32x32, and colour index to E
         sta VERADAT0

         txa
         clc
         adc #40
         tax
         dey
         bne :-

         rts

