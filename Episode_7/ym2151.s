; This file controls the YM2151 FM sound chip.
;
; LICENSE: This program is public domain, and you may do anything and
; everything with it.

; External API

.export ym2151_channel_init
.export ym2151_keyon
.export ym2151_keyoff
.export ym2151_keycode


; YM2151 register addresses
YM2151_ADDR    = $9FE0
YM2151_VAL     = $9FE1
YM2151_REG_SM  = $08
YM2151_REG_CON = $20
YM2151_REG_KC  = $28
YM2151_REG_MUL = $40
YM2151_REG_TL  = $60
YM2151_REG_AR  = $80
YM2151_REG_D1R = $A0
YM2151_REG_D2R = $C0
YM2151_REG_RR  = $E0
YM2151_KEYOFF  = $00
YM2151_KEYON   = $08

; This section contains zero-page variables that are uninitialized at start.
.segment "ZP" : zeropage
; Pointer into array of initialization data.
ym2151_pointer : .res 2

.code

;
; Initialize sound channel
; A:X Pointer to 28-byte channel data.
; Y   Channel number.
; The 28 bytes are written to the YM2151 register address $20+8*offset+channel.
; $20 : Connect
; $28 : Key Code
; $30 : Key Fraction
; $38 : PMS AMS
; $40 : Modulator 1 : Multiplier
; $48 : Modulator 2 : Multiplier
; $50 : Carrier 1   : Multiplier
; $58 : Carrier 2   : Multiplier
; $60 : Modulator 1 : Total Level
; $68 : Modulator 2 : Total Level
; $70 : Carrier 1   : Total Level
; $78 : Carrier 2   : Total Level
; $80 : Modulator 1 : Attack Rate
; $88 : Modulator 2 : Attack Rate
; $90 : Carrier 1   : Attack Rate
; $98 : Carrier 2   : Attack Rate
; $A0 : Modulator 1 : First Decay Rate
; $A8 : Modulator 2 : First Decay Rate
; $B0 : Carrier 1   : First Decay Rate
; $B8 : Carrier 2   : First Decay Rate
; $C0 : Modulator 1 : Second Decay Rate
; $C8 : Modulator 2 : Second Decay Rate
; $D0 : Carrier 1   : Second Decay Rate
; $D8 : Carrier 2   : Second Decay Rate
; $E0 : Modulator 1 : Release Rate
; $E8 : Modulator 2 : Release Rate
; $F0 : Carrier 1   : Release Rate
; $F8 : Carrier 2   : Release Rate
;
ym2151_channel_init:
         stx ym2151_pointer
         sta ym2151_pointer+1
         tya
         clc
         adc #YM2151_REG_CON
         tax
         ldy #0

:        lda (ym2151_pointer),y
         jsr ym2151_write
         iny
         txa
         clc
         adc #8
         tax
         bcc :-
         rts

;
; Send Key On event
; Y   Channel number.
; A and X are destroyed.
ym2151_keyon:
         lda ym2151_val_keyon,y        ; A short-hand way of calculating A = YM2151_KEYON + Y.
         ldx #YM2151_REG_SM
         bra ym2151_write

;
; Send Key Off event
; Y   Channel number.
; A and X are destroyed.
ym2151_keyoff:
         lda ym2151_val_keyoff,y       ; A short-hand way of calculating A = YM2151_KEYOFF + Y.
         ldx #YM2151_REG_SM
         bra ym2151_write

;
; Set Key Code
; A   Key Code.
; Y   Channel number.
; X is destroyed.
ym2151_keycode:
         ldx ym2151_reg_kc,y           ; A short-hand way of calculating X = YM2151_REG_KC + Y.
         bra ym2151_write

; Write to a register in the chip.
ym2151_write:
         stx YM2151_ADDR
         sta YM2151_VAL
         rts

;
; Internal tables
ym2151_reg_kc:
.byt YM2151_REG_KC
.byt YM2151_REG_KC+1
.byt YM2151_REG_KC+2
.byt YM2151_REG_KC+3
.byt YM2151_REG_KC+4
.byt YM2151_REG_KC+5
.byt YM2151_REG_KC+6
.byt YM2151_REG_KC+7

ym2151_val_keyoff:
.byt YM2151_KEYOFF
.byt YM2151_KEYOFF+1
.byt YM2151_KEYOFF+2
.byt YM2151_KEYOFF+3
.byt YM2151_KEYOFF+4
.byt YM2151_KEYOFF+5
.byt YM2151_KEYOFF+6
.byt YM2151_KEYOFF+7

ym2151_val_keyon:
.byt YM2151_KEYON
.byt YM2151_KEYON+1
.byt YM2151_KEYON+2
.byt YM2151_KEYON+3
.byt YM2151_KEYON+4
.byt YM2151_KEYON+5
.byt YM2151_KEYON+6
.byt YM2151_KEYON+7

