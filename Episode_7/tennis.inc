; This file contains various global constants.

; VERA register addresses
VERALO   = $9F20
VERAMID  = $9F21
VERAHI   = $9F22
VERADAT0 = $9F23
VERADAT1 = $9F24
VERACTRL = $9F25
VERAIEN  = $9F26
VERAISR  = $9F27

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

; Game constants
PLAYER_SPEED    = 3
PLAYER_RADIUS   = 16
BOT_SPEED       = 3
BOT_RADIUS      = 16
BALL_RADIUS     = 8
SCENE_LEFT      = 8
SCENE_RIGHT     = 640-8
SCENE_TOP       = 8
SCENE_BOTTOM    = 480
BARRIER_LEFT    = 320-8
BARRIER_RIGHT   = 320
BARRIER_TOP     = 480-8*10
GRAVITY         = 12

; Kernal API
kernal_clock_get_date_time = $FF50
kernal_stop_key            = $FFE1
kernal_joystick_get        = $FF56

