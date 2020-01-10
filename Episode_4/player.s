; This file controls the player
;
; LICENSE: This program is public domain, and you may do anything and
; everything with it.

; External API

.export player_init
.export player_update
.export player_pos_x
.export player_pos_y

; This section contains variables that are uninitialized at start.
.bss
; Position of center of the players semicircle.
player_pos_x : .res 2
player_pos_y : .res 2


.code
.include "tennis.inc"

;
; This function is called repeatedly. It handles keyboard input and
; moves the player on the screen.
;

player_update:
         lda #$00
         jsr kernal_joystick_get
         and #$03
         beq @ret
         bit #$01
         beq @right
         bit #$02
         beq @left
@ret:    rts

@right:
         lda player_pos_x        ; Move player to the right
         clc
         adc #PLAYER_SPEED
         sta player_pos_x
         bcc :+
         inc player_pos_x+1
:
         lda player_pos_x+1      ; Check if we hit the barrier
         cmp #>(SCENE_RIGHT-PLAYER_RADIUS)
         bne :+
         lda player_pos_x
         cmp #<(SCENE_RIGHT-PLAYER_RADIUS)
:        bcc :+

         lda #>(SCENE_RIGHT-PLAYER_RADIUS)
         ldx #<(SCENE_RIGHT-PLAYER_RADIUS)
         stx player_pos_x
         sta player_pos_x+1

:        bra @update_sprite

@left:
         lda player_pos_x        ; Move player to the left
         sec
         sbc #PLAYER_SPEED
         sta player_pos_x
         bcs :+
         dec player_pos_x+1
:
         lda player_pos_x+1      ; Check if we hit the barrier
         cmp #>(SCENE_LEFT+PLAYER_RADIUS)
         bne :+
         lda player_pos_x
         cmp #<(SCENE_LEFT+PLAYER_RADIUS)
:        bcs :+

         ldx #<(SCENE_LEFT+PLAYER_RADIUS)
         lda #>(SCENE_LEFT+PLAYER_RADIUS)
         stx player_pos_x
         sta player_pos_x+1

@update_sprite:
:        lda #$1F                ; Set increment to 1, and address to $F5002
         ldx #$50
         ldy #$02
         sta VERAHI
         stx VERAMID
         sty VERALO

         lda player_pos_x        ; Set sprite X-position
         sec
         sbc #PLAYER_RADIUS
         sta VERADAT0
         lda player_pos_x+1
         sbc #0
         sta VERADAT0
         rts

;
; This initialization routine is called once at start of the game.
;

player_init:

         ; Set initial X-position of player to be approximately in the middle
         ; of the players field.
         ldx #<(BARRIER_LEFT/2)
         lda #>(BARRIER_LEFT/2)
         stx player_pos_x
         sta player_pos_x+1
         ldx #<SCENE_BOTTOM
         lda #>SCENE_BOTTOM
         stx player_pos_y
         sta player_pos_y+1

         ; Configure player sprite (#0)
         lda #$1F                ; Set increment to 1, and address to $F5000
         ldx #$50
         ldy #$00
         sta VERAHI
         stx VERAMID
         sty VERALO

         lda #$E0                ; Set sprite data address to $03C00
         sta VERADAT0
         lda #$81
         sta VERADAT0

         lda player_pos_x        ; Set sprite X-position
         sec
         sbc #PLAYER_RADIUS
         sta VERADAT0
         lda player_pos_x+1
         sbc #0
         sta VERADAT0

         lda player_pos_y        ; Set sprite Y-position
         sec
         sbc #PLAYER_RADIUS
         sta VERADAT0
         lda player_pos_y+1
         sbc #0
         sta VERADAT0

         lda #$0C                ; Set Z-depth to 3 (in front of layer 1)
         sta VERADAT0
         lda #$64                ; Set sprite size to 32x16, and colour index to 4
         sta VERADAT0

         rts

