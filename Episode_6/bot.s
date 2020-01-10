; This file controls the bot
;
; LICENSE: This program is public domain, and you may do anything and
; everything with it.

; External API

.export bot_init
.export bot_update
.export bot_pos_x
.export bot_pos_y
.import ball_pos_x
.import ball_pos_y

; This section contains variables that are uninitialized at start.
.bss
; Position of center of the bots semicircle.
bot_pos_x    : .res 2   ; 16.0 integer
bot_pos_y    : .res 2   ; 16.0 integer
bot_target_x : .res 2   ; 16.0 integer


.code
.include "tennis.inc"

;
; This function is called repeatedly. It handles keyboard input and
; moves the bot on the screen.
;
bot_update:
         ; The bot tries to place itself slightly to the right of the ball.
         ldx ball_pos_x+1
         lda ball_pos_x+2

         ; Add two to A:X
         pha
         txa
         clc
         adc #2
         tax
         pla
         adc #0

         stx bot_target_x
         sta bot_target_x+1

         ; Compare with current bot position
         cmp bot_pos_x+1
         bne :+
         cpx bot_pos_x
:        beq @update_sprite            ; Don't move if we're in the right position.

         bcc @skip_right

         lda bot_pos_x                 ; Move bot to the right
         clc
         adc #BOT_SPEED
         sta bot_pos_x
         bcc :+
         inc bot_pos_x+1
:
         lda bot_pos_x+1               ; Check if we hit the wall
         cmp #>(SCENE_RIGHT-BOT_RADIUS)
         bne :+
         lda bot_pos_x
         cmp #<(SCENE_RIGHT-BOT_RADIUS)
:        bcc :+

         lda #>(SCENE_RIGHT-BOT_RADIUS)
         ldx #<(SCENE_RIGHT-BOT_RADIUS)
         stx bot_pos_x
         sta bot_pos_x+1
:

@skip_right:
         ldx bot_target_x
         lda bot_target_x+1
         ; Compare with current bot position
         cmp bot_pos_x+1
         bne :+
         cpx bot_pos_x
:        beq @update_sprite            ; Don't move if we're in the right position.
         bcs @skip_left

         lda bot_pos_x                 ; Move bot to the left
         sec
         sbc #BOT_SPEED
         sta bot_pos_x
         bcs :+
         dec bot_pos_x+1
:
         lda bot_pos_x+1               ; Check if we hit the barrier
         cmp #>(BARRIER_RIGHT+BOT_RADIUS)
         bne :+
         lda bot_pos_x
         cmp #<(BARRIER_RIGHT+BOT_RADIUS)
:        bcs :+

         ldx #<(BARRIER_RIGHT+BOT_RADIUS)
         lda #>(BARRIER_RIGHT+BOT_RADIUS)
         stx bot_pos_x
         sta bot_pos_x+1
:
@skip_left:
@update_sprite:
         lda #$1F                      ; Set increment to 1, and address to $F5012
         ldx #$50
         ldy #$12
         sta VERAHI
         stx VERAMID
         sty VERALO

         lda bot_pos_x                 ; Set sprite X-position
         sec
         sbc #BOT_RADIUS
         sta VERADAT0
         lda bot_pos_x+1
         sbc #0
         sta VERADAT0
         rts


;
; This initialization routine is called once at start of the game.
;
bot_init:
         ; Set initial X-position of bot to be approximately in the middle
         ; of the bots field.
         ldx #<(3*BARRIER_LEFT/2)
         lda #>(3*BARRIER_LEFT/2)
         stx bot_pos_x
         sta bot_pos_x+1
         ldx #<SCENE_BOTTOM
         lda #>SCENE_BOTTOM
         stx bot_pos_y
         sta bot_pos_y+1

         ; Configure bot sprite (#2)
         lda #$1F                ; Set increment to 1, and address to $F5010
         ldx #$50
         ldy #$10
         sta VERAHI
         stx VERAMID
         sty VERALO

         lda #$E0                ; Set sprite data address to $03C00
         sta VERADAT0
         lda #$81
         sta VERADAT0

         lda bot_pos_x           ; Set sprite X-position
         sec
         sbc #BOT_RADIUS
         sta VERADAT0
         lda bot_pos_x+1
         sbc #0
         sta VERADAT0

         lda bot_pos_y           ; Set sprite Y-position
         sec
         sbc #BOT_RADIUS
         sta VERADAT0
         lda bot_pos_y+1
         sbc #0
         sta VERADAT0

         lda #$0C                ; Set Z-depth to 3 (in front of layer 1)
         sta VERADAT0
         lda #$67                ; Set sprite size to 32x16, and colour index to 7
         sta VERADAT0

         rts

