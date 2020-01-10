; This is the top-level file for the TENNIS program.
; Player controls are <LEFT> and <RIGHT> cursor keys.
;
; LICENSE: This program is public domain, and you may do anything and
; everything with it.

.include "tennis.inc"

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
         rts                  ; End of game


;
; This initialization routine is called once at start of the game.
;

scene_init:
         ; Clear the screen by filling all colour cells with blue-on-blue
         lda #$20             ; Set increment to 2, and address to $00001 (top left corner)
         ldx #$00
         ldy #$01
         sta VERAHI
         stx VERAMID
         sty VERALO
         ldy #30              ; The number of colour cells to fill is 60*128, i.e. $3000
         ldx #0
         lda #$66             ; Blue on blue
:        sta VERADAT0
         dex
         bne :-
         dey
         bne :-

         ; Draw the left wall (60 characters with white-on-white)
         lda #$90             ; Set increment to 256, and address to $00001 (top left corner)
         ldx #$00
         ldy #$01
         sta VERAHI
         stx VERAMID
         sty VERALO
         ldy #60
         lda #$11             ; White on white
:        sta VERADAT0
         dey
         bne :-

         ; Draw the right wall (60 characters with white-on-white)
         lda #$90             ; Set increment to 256, and address to $0009F (top right corner)
         ldx #$00
         ldy #$9F
         sta VERAHI
         stx VERAMID
         sty VERALO
         ldy #60
         lda #$11             ; White on white
:        sta VERADAT0
         dey
         bne :-

         ; Draw the top wall (80 characters with white-on-white)
         lda #$20             ; Set increment to 2, and address to $00001 (top right corner)
         ldx #$00
         ldy #$01
         sta VERAHI
         stx VERAMID
         sty VERALO
         ldy #80
         lda #$11             ; White on white
:        sta VERADAT0
         dey
         bne :-

         ; Draw the middle barrier (10 characters)
         lda #$90             ; Set increment to 256, and address to $0324F (top of barrier)
         ldx #$32
         ldy #$4F
         sta VERAHI
         stx VERAMID
         sty VERALO
         ldy #10
         lda #$11             ; White on white
:        sta VERADAT0
         dey
         bne :-

         rts

