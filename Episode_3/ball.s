; This file controls the ball.
;
; LICENSE: This program is public domain, and you may do anything and
; everything with it.

; External API

.export ball_init
.export ball_update

; This section contains variables that are uninitialized at start.
.bss
; Position of center of the ball, in 16.8 fractional representation.
ball_pos_x : .res 3
ball_pos_y : .res 3
; Velocity of the ball, in 16.8 fractional representation.
ball_vel_x : .res 3
ball_vel_y : .res 3

.code
.include "tennis.inc"

;
; This function is called repeatedly. It moves the ball on the screen
; and handles collision.
;

ball_update:

         ; Handle gravity
         clc
         lda ball_vel_y
         adc #GRAVITY
         sta ball_vel_y
         bcc :+
         inc ball_vel_y+1
         bne :+
         inc ball_vel_y+2
:

         ; Update ball position
         clc
         lda ball_pos_y
         adc ball_vel_y
         sta ball_pos_y
         lda ball_pos_y+1
         adc ball_vel_y+1
         sta ball_pos_y+1
         lda ball_pos_y+2
         adc ball_vel_y+2
         sta ball_pos_y+2

         clc
         lda ball_pos_x
         adc ball_vel_x
         sta ball_pos_x
         lda ball_pos_x+1
         adc ball_vel_x+1
         sta ball_pos_x+1
         lda ball_pos_x+2
         adc ball_vel_x+2
         sta ball_pos_x+2

         ; Update sprite
         lda #$1F                ; Set increment to 1, and address to $F500A
         ldx #$50
         ldy #$0A
         sta VERAHI
         stx VERAMID
         sty VERALO

         lda ball_pos_x+1        ; Set sprite X-position
         sec
         sbc #BALL_RADIUS
         sta VERADAT0
         lda ball_pos_x+2
         sbc #0
         sta VERADAT0

         lda ball_pos_y+1        ; Set sprite Y-position
         sec
         sbc #BALL_RADIUS
         sta VERADAT0
         lda ball_pos_y+2
         sbc #0
         sta VERADAT0

         rts


;
; This initialization routine is called once at start of the game.
;

ball_init:

         ; Set initial X-position of player to be approximately in the middle
         ; of the players field.
         ldy #0
         ldx #<(BARRIER_LEFT/2-2)
         lda #>(BARRIER_LEFT/2-2)
         sty ball_pos_x          ; fractional part
         stx ball_pos_x+1
         sta ball_pos_x+2
         ldy #0
         ldx #<(SCENE_TOP+200)
         lda #>(SCENE_TOP+200)
         sty ball_pos_y          ; fractional part
         stx ball_pos_y+1
         sta ball_pos_y+2

         ; Set initial velocity
         stz ball_vel_x
         stz ball_vel_x+1
         stz ball_vel_x+2
         stz ball_vel_y
         stz ball_vel_y+1
         stz ball_vel_y+2

         ; Configure ball sprite (#1)
         lda #$1F                ; Set increment to 1, and address to $F5008
         ldx #$50
         ldy #$08
         sta VERAHI
         stx VERAMID
         sty VERALO

         lda #$F0                ; Set sprite data address to $03E00
         sta VERADAT0
         lda #$81
         sta VERADAT0

         lda ball_pos_x+1        ; Set sprite X-position
         sec
         sbc #BALL_RADIUS
         sta VERADAT0
         lda ball_pos_x+2
         sbc #0
         sta VERADAT0

         lda ball_pos_y+1        ; Set sprite Y-position
         sec
         sbc #BALL_RADIUS
         sta VERADAT0
         lda ball_pos_y+2
         sbc #0
         sta VERADAT0

         lda #$0C                ; Set Z-depth to 3 (in front of layer 1)
         sta VERADAT0
         lda #$53                ; Set sprite size to 16x16, and colour index to 3
         sta VERADAT0

         rts

