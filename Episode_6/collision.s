; This file implements all the collision handling.
;
; LICENSE: This program is public domain, and you may do anything and
; everything with it.

; External API
.export collision_left_wall
.export collision_right_wall
.export collision_top_wall
.export collision_left_barrier
.export collision_right_barrier
.export collision_top_barrier
.export collision_left_corner
.export collision_right_corner
.export collision_player
.export collision_bot
.export collision_bottom
.export collision_compare_pos_x

.import math_store_to_arg0
.import math_store_to_arg1
.import math_multiply
.import math_multiply_add
.import math_divide
.import math_load_from_mult
.import math_load_from_div
.import math_cmp_with_mult
.import math_negate
.import math_abs
.import math_double
.import math_increase

.import ball_reset

.import player_pos_x
.import player_pos_y
.import bot_pos_x
.import bot_pos_y
.import ball_pos_x
.import ball_pos_y
.import ball_vel_x
.import ball_vel_y


; This section contains variables that are uninitialized at start.
.bss
; Temporary variables used during collision handling.
collision_dp_x : .res 3    ; X-displacement from ball to collision point.
collision_dp_y : .res 3    ; Y-displacement from ball to collision point.
collision_r2   : .res 3    ; Radius squared of ball.
collision_len2 : .res 3    ; Len2=DP_x^2+DP_y^2.
collision_t    : .res 3    ; T=2*P/Len2.

.code
.include "tennis.inc"

;
; Handle collision with left wall
;
collision_left_wall:
         ldy #0
         ldx #<(SCENE_LEFT+BALL_RADIUS)
         lda #>(SCENE_LEFT+BALL_RADIUS)
         jsr collision_compare_pos_x
         bcc return              ; Return if no collision

         ; Collision detected, now check velocity
         lda ball_vel_x+2
         bpl return              ; Return if moving right

         jmp negate_vel_x
return:  rts
         

;
; Handle collision with right wall
;
collision_right_wall:
         ldy #0
         ldx #<(SCENE_RIGHT-BALL_RADIUS)
         lda #>(SCENE_RIGHT-BALL_RADIUS)
         jsr collision_compare_pos_x
         bcs return              ; Return if no collision

         ; Collision detected, now check velocity
         lda ball_vel_x+2
         bmi return              ; Return if moving left

         jmp negate_vel_x        ; Change sign of X-component of velocity


;
; Handle collision with top wall
;
collision_top_wall:
         ldy #0
         ldx #<(SCENE_TOP+BALL_RADIUS)
         lda #>(SCENE_TOP+BALL_RADIUS)
         jsr compare_pos_y
         bcc return              ; Return if no collision

         ; Collision detected, now check velocity
         lda ball_vel_y+2
         bpl return              ; Return if moving down

         jmp negate_vel_y        ; Change sign of Y-component of velocity


;
; Handle collision with left side of barrier
;
collision_left_barrier:
         ; First check the y-component
         ldy #0
         ldx #<(BARRIER_TOP)
         lda #>(BARRIER_TOP)
         jsr compare_pos_y
         bcs return              ; Return if no collision

         ; Check left side of barrier
         ldy #0
         ldx #<(BARRIER_LEFT-BALL_RADIUS)
         lda #>(BARRIER_LEFT-BALL_RADIUS)
         jsr collision_compare_pos_x
         bcs return              ; Return if no collision

         ; Check middle of barrier
         ldy #0
         ldx #<((BARRIER_LEFT+BARRIER_RIGHT)/2)
         lda #>((BARRIER_LEFT+BARRIER_RIGHT)/2)
         jsr collision_compare_pos_x
         bcc return              ; Return if no collision

         ; Collision detected, now check velocity
         lda ball_vel_x+2
         bmi return              ; Return if moving left

         jmp negate_vel_x        ; Change sign of X-component of velocity


;
; Handle collision with right side of barrier
;
collision_right_barrier:
         ; First check the y-component
         ldy #0
         ldx #<(BARRIER_TOP)
         lda #>(BARRIER_TOP)
         jsr compare_pos_y
         bcs return              ; Return if no collision

         ; Check right side of barrier
         ldy #0
         ldx #<(BARRIER_RIGHT+BALL_RADIUS)
         lda #>(BARRIER_RIGHT+BALL_RADIUS)
         jsr collision_compare_pos_x
         bcc return              ; Return if no collision

         ; Check middle of barrier
         ldy #0
         ldx #<((BARRIER_LEFT+BARRIER_RIGHT)/2)
         lda #>((BARRIER_LEFT+BARRIER_RIGHT)/2)
         jsr collision_compare_pos_x
         bcs return              ; Return if no collision

         ; Collision detected, now check velocity
         lda ball_vel_x+2
         bpl return              ; Return if moving right

         jmp negate_vel_x        ; Change sign of X-component of velocity


;
; Handle collision with top side of barrier
;
collision_top_barrier:
         ; First check the x-component interval
         ldy #0
         ldx #<(BARRIER_LEFT)
         lda #>(BARRIER_LEFT)
         jsr collision_compare_pos_x
         bcs return1             ; Return if no collision

         ldy #0
         ldx #<(BARRIER_RIGHT)
         lda #>(BARRIER_RIGHT)
         jsr collision_compare_pos_x
         bcc return1             ; Return if no collision

         ; Check top side of barrier
         ldy #0
         ldx #<(BARRIER_TOP-BALL_RADIUS)
         lda #>(BARRIER_TOP-BALL_RADIUS)
         jsr compare_pos_y
         bcs return1             ; Return if no collision

         ; Collision detected, now check velocity
         lda ball_vel_y+2
         bmi return1             ; Return if moving up

         jmp negate_vel_y        ; Change sign of Y-component of velocity
return1: rts


;
; Compare A:X.Y with balls X-position
;
collision_compare_pos_x:
         cmp ball_pos_x+2
         bne :+
         cpx ball_pos_x+1
         bne :+
         cpy ball_pos_x
:        rts


;
; Compare A:X.Y with balls Y-position
;
compare_pos_y:
         cmp ball_pos_y+2
         bne :+
         cpx ball_pos_y+1
         bne :+
         cpy ball_pos_y
:        rts


;
; Change sign of X-component of velocity
;
negate_vel_x:
         clc
         lda ball_vel_x
         eor #$ff
         adc #$01
         sta ball_vel_x
         lda ball_vel_x+1
         eor #$ff
         adc #$00
         sta ball_vel_x+1
         lda ball_vel_x+2
         eor #$ff
         adc #$00
         sta ball_vel_x+2
         rts

;
; Change sign of Y-component of velocity
;
negate_vel_y:
         clc
         lda ball_vel_y
         eor #$ff
         adc #$01
         sta ball_vel_y
         lda ball_vel_y+1
         eor #$ff
         adc #$00
         sta ball_vel_y+1
         lda ball_vel_y+2
         eor #$ff
         adc #$00
         sta ball_vel_y+2
         rts


;
; Calculate A:X.Y - ball_pos_x. Result is in A:X.Y
;
sub_ball_pos_x:
         pha
         tya
         sec
         sbc ball_pos_x
         tay
         txa
         sbc ball_pos_x+1
         tax
         pla
         sbc ball_pos_x+2
         rts


;
; Calculate A:X.Y - ball_pos_y. Result is in A:X.Y
;
sub_ball_pos_y:
         pha
         tya
         sec
         sbc ball_pos_y
         tay
         txa
         sbc ball_pos_y+1
         tax
         pla
         sbc ball_pos_y+2
         rts


;
; Handle collision with top left corner of barrier.
;
collision_left_corner:
         ; Step 1. Calculate DP\_x = Point\_x - Ball\_x.
         ldy #0
         ldx #<BARRIER_LEFT
         lda #>BARRIER_LEFT
         jsr sub_ball_pos_x
         sty collision_dp_x
         stx collision_dp_x+1
         sta collision_dp_x+2

         ; Step 2. Calculate DP\_y = Point\_y - Ball\_y.
         ldy #0
         ldx #<BARRIER_TOP
         lda #>BARRIER_TOP
         jsr sub_ball_pos_y
         sty collision_dp_y
         stx collision_dp_y+1
         sta collision_dp_y+2

         ; Step 3. Calculate R2 = Ball\_radius^2.
         ldy #0
         ldx #<(BALL_RADIUS*BALL_RADIUS)
         lda #>(BALL_RADIUS*BALL_RADIUS)
         sty collision_r2
         stx collision_r2+1
         sta collision_r2+2
         bra collision_point


;
; Handle collision with top right corner of barrier.
;
collision_right_corner:
         ; Step 1. Calculate DP\_x = Point\_x - Ball\_x.
         ldy #0
         ldx #<BARRIER_RIGHT
         lda #>BARRIER_RIGHT
         jsr sub_ball_pos_x
         sty collision_dp_x
         stx collision_dp_x+1
         sta collision_dp_x+2

         ; Step 2. Calculate DP\_y = Point\_y - Ball\_y.
         ldy #0
         ldx #<BARRIER_TOP
         lda #>BARRIER_TOP
         jsr sub_ball_pos_y
         sty collision_dp_y
         stx collision_dp_y+1
         sta collision_dp_y+2

         ; Step 3. Calculate R2 = Ball\_radius^2.
         ldy #0
         ldx #<(BALL_RADIUS*BALL_RADIUS)
         lda #>(BALL_RADIUS*BALL_RADIUS)
         sty collision_r2
         stx collision_r2+1
         sta collision_r2+2
         bra collision_point

collision_return:
         rts

;
; This handles collision against point.
; The variables collision_dp_x and collision_dp_y must be set up.
; A:X is the distance squared at time of collision.
;
collision_point:
         ; Step 4. Calculate Len2 = |DP_x|^2 + |DP_y|^2.
         ldy collision_dp_x
         ldx collision_dp_x+1
         lda collision_dp_x+2
         jsr math_abs
         bne collision_return          ; Return if overflow (MSB nonzero)
         cpx #$80
         bcs collision_return          ; Return if overflow (value greater than $80)
         jsr math_store_to_arg0
         jsr math_store_to_arg1
         jsr math_multiply             ; Calculate DP_x^2

         ldy collision_dp_y
         ldx collision_dp_y+1
         lda collision_dp_y+2
         jsr math_abs
         bne collision_return          ; Return if overflow (MSB nonzero)
         cpx #$80
         bcs collision_return          ; Return if overflow (value greater than $80)
         jsr math_store_to_arg0
         jsr math_store_to_arg1
         jsr math_multiply_add         ; Calculate Len2 = DP_x^2 + DP_y^2

         ; Step 5. Compare R2 with Len2. Return if less than.
         ldy collision_r2
         ldx collision_r2+1
         lda collision_r2+2
         jsr math_cmp_with_mult
         bcc collision_return          ; Return if no collision

         jsr math_load_from_mult       ; Get Len2
         sty collision_len2
         stx collision_len2+1
         sta collision_len2+2

         ; Step 6. Calculate P = Vel_x*DP_x + Vel_y*DP_y. Return if negative.
         ldy ball_vel_x
         ldx ball_vel_x+1
         lda ball_vel_x+2
         jsr math_store_to_arg0
         ldy collision_dp_x
         ldx collision_dp_x+1
         lda collision_dp_x+2
         jsr math_store_to_arg1
         jsr math_multiply

         ldy ball_vel_y
         ldx ball_vel_y+1
         lda ball_vel_y+2
         jsr math_store_to_arg0
         ldy collision_dp_y
         ldx collision_dp_y+1
         lda collision_dp_y+2
         jsr math_store_to_arg1
         jsr math_multiply_add

         jsr math_load_from_mult       ; Get P
         bpl :+
         rts                           ; Return if negative
:

         ; Step 7. Calculate T = 2*P/Len2.
         jsr math_double
         jsr math_store_to_arg0

         ldy collision_len2
         ldx collision_len2+1
         lda collision_len2+2
         jsr math_store_to_arg1
         jsr math_divide
         jsr math_load_from_div
         jsr math_increase         ; Round up.
         sty collision_t
         stx collision_t+1
         sta collision_t+2

         ; Step 8. Calculate DV_x = -T*DP_x and add to Vel_x.
         jsr math_store_to_arg1
         ldy collision_dp_x
         ldx collision_dp_x+1
         lda collision_dp_x+2
         jsr math_store_to_arg0
         jsr math_multiply
         jsr math_load_from_mult
         jsr math_negate
         pha
         tya
         clc
         adc ball_vel_x
         sta ball_vel_x
         txa
         adc ball_vel_x+1
         sta ball_vel_x+1
         pla
         adc ball_vel_x+2
         sta ball_vel_x+2
         
         ; Step 9. Calculate DV_y = -T*DP_y and add to Vel_y.
         ldy collision_t
         ldx collision_t+1
         lda collision_t+2
         jsr math_store_to_arg1
         ldy collision_dp_y
         ldx collision_dp_y+1
         lda collision_dp_y+2
         jsr math_store_to_arg0
         jsr math_multiply
         jsr math_load_from_mult
         jsr math_negate
         pha
         tya
         clc
         adc ball_vel_y
         sta ball_vel_y
         txa
         adc ball_vel_y+1
         sta ball_vel_y+1
         pla
         adc ball_vel_y+2
         sta ball_vel_y+2

@return: rts

;
; Handle collision with player
;
collision_player:
         ; Step 1. Calculate DP_x = Player_x - Ball_x.
         ldy #0
         ldx player_pos_x
         lda player_pos_x+1
         jsr sub_ball_pos_x
         sty collision_dp_x
         stx collision_dp_x+1
         sta collision_dp_x+2

         ; Step 2. Calculate DP_y = Player_y - Ball_y.
         ldy #0
         ldx player_pos_y
         lda player_pos_y+1
         jsr sub_ball_pos_y
         sty collision_dp_y
         stx collision_dp_y+1
         sta collision_dp_y+2

         ; Step 3. Calculate R2 = (Player_radius+Ball_radius)^2.
         ldy #0
         ldx #<((PLAYER_RADIUS+BALL_RADIUS)*(PLAYER_RADIUS+BALL_RADIUS))
         lda #>((PLAYER_RADIUS+BALL_RADIUS)*(PLAYER_RADIUS+BALL_RADIUS))
         sty collision_r2
         stx collision_r2+1
         sta collision_r2+2
         jmp collision_point


;
; Handle collision with bot
;
collision_bot:
         ; Step 1. Calculate DP_x = Bot_x - Ball_x.
         ldy #0
         ldx bot_pos_x
         lda bot_pos_x+1
         jsr sub_ball_pos_x
         sty collision_dp_x
         stx collision_dp_x+1
         sta collision_dp_x+2

         ; Step 2. Calculate DP_y = Bot_y - Ball_y.
         ldy #0
         ldx bot_pos_y
         lda bot_pos_y+1
         jsr sub_ball_pos_y
         sty collision_dp_y
         stx collision_dp_y+1
         sta collision_dp_y+2

         ; Step 3. Calculate R2 = (Bot_radius+Ball_radius)^2.
         ldy #0
         ldx #<((BOT_RADIUS+BALL_RADIUS)*(BOT_RADIUS+BALL_RADIUS))
         lda #>((BOT_RADIUS+BALL_RADIUS)*(BOT_RADIUS+BALL_RADIUS))
         sty collision_r2
         stx collision_r2+1
         sta collision_r2+2
         jmp collision_point


;
; Handle collision with bottom
;
collision_bottom:
         ldy #0
         ldx #<(SCENE_BOTTOM)
         lda #>(SCENE_BOTTOM)
         jsr compare_pos_y
         bcs :+                        ; Return if no collision
         jmp ball_reset
:        rts

