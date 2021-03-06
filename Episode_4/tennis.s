; This is the top-level file for the TENNIS program.
; Player controls are <LEFT> and <RIGHT> cursor keys.
;
; LICENSE: This program is public domain, and you may do anything and
; everything with it.

.include "vera.inc"
.include "kernal.inc"
.include "tennis.inc"

.import sprite_init           ; From sprite.s
.import player_init           ; From player.s
.import player_update         ; From player.s
.import ball_init             ; From ball.s
.import ball_update           ; From ball.s
.import ball_reset            ; From ball.s
.import collision_bottom      ; From collision.s

; This section contains variables that are uninitialized at start.
.bss
tennis_timer : .res 1

.code

; The auto-lancher sequence starts here:

.org $07FF                    ; Start address for assembler
.byt $01, $08                 ; Start address of program
.byt $0B, $08                 ; Start address of next line
.byt $01, $00                 ; Line number 1
.byt $9E                      ; SYS token
.byt "2061"                   ; $080D in decimal
.byt $00                      ; End of line
.byt $00, $00                 ; End of BASIC program


;
; This is the main entry point, at address $080D.
;

         jsr scene_init
         jsr sprite_init      ; In sprite.s
         jsr player_init      ; In player.s
         jsr ball_init        ; In ball.s

         ; Main loop starts here
@main_loop:
         jsr player_update
         jsr ball_update
         jsr collision_bottom
         bcs :+               ; Jump if no collision
         jsr ball_reset
:
         jsr wait_for_timer_interrupt
         jsr kernal_stop_key  ; Test for STOP key
         bne @main_loop
         rts                  ; Return to BASIC

;
; This function waits for a VSYNC interrupt (60 Hz) from the VERA
; This ensures the game runs at a predictable speed.
; It works by storing the current value of the tennis_timer, and
; then waiting until it changes.
;

wait_for_timer_interrupt:
         jsr kernal_clock_get_date_time
         lda $08              ; Get the jiffie counter (60 Hz)
         sta tennis_timer

         ; Repeat until timer is updated
:        jsr kernal_clock_get_date_time
         lda $08
         cmp tennis_timer
         beq :-
         rts

;
; This initialization routine is called once at start of the game.
;

scene_init:
         ; Clear the screen by filling all colour cells with blue-on-blue
         lda #$20             ; Set increment to 2, and address to $00001 (top left corner)
         ldx #$00
         ldy #$01
         sta VERA_ADDRx_H
         stx VERA_ADDRx_M
         sty VERA_ADDRx_L
         ldy #30              ; The number of colour cells to fill is 60*128, i.e. $3000
         ldx #0
         lda #$66             ; Blue on blue
:        sta VERA_DATA0
         dex
         bne :-
         dey
         bne :-

         ; Draw the left wall (60 characters with white-on-white)
         lda #$90             ; Set increment to 256, and address to $00001 (top left corner)
         ldx #$00
         ldy #$01
         sta VERA_ADDRx_H
         stx VERA_ADDRx_M
         sty VERA_ADDRx_L
         ldy #60
         lda #$11             ; White on white
:        sta VERA_DATA0
         dey
         bne :-

         ; Draw the right wall (60 characters with white-on-white)
         lda #$90             ; Set increment to 256, and address to $0009F (top right corner)
         ldx #$00
         ldy #$9F
         sta VERA_ADDRx_H
         stx VERA_ADDRx_M
         sty VERA_ADDRx_L
         ldy #60
         lda #$11             ; White on white
:        sta VERA_DATA0
         dey
         bne :-

         ; Draw the top wall (80 characters with white-on-white)
         lda #$20             ; Set increment to 2, and address to $00001 (top right corner)
         ldx #$00
         ldy #$01
         sta VERA_ADDRx_H
         stx VERA_ADDRx_M
         sty VERA_ADDRx_L
         ldy #80
         lda #$11             ; White on white
:        sta VERA_DATA0
         dey
         bne :-

         ; Draw the middle barrier (10 characters)
         lda #$90             ; Set increment to 256, and address to $0324F (top of barrier)
         ldx #$32
         ldy #$4F
         sta VERA_ADDRx_H
         stx VERA_ADDRx_M
         sty VERA_ADDRx_L
         ldy #10
         lda #$11             ; White on white
:        sta VERA_DATA0
         dey
         bne :-

         rts

