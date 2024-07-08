.include "consts.inc"
.include "header.inc"
.include "reset.inc"
.include "utils.inc"

.segment "ZEROPAGE"
Frame:             .res 1
Clock60:           .res 1
BackgroundPointer: .res 2
Buttons:           .res 1
XPos:              .res 1
YPos:              .res 1

.segment "CODE"

.proc ReadControllers
  LDA #1
  STA Buttons

  STA JOYPAD1
  LSR
  STA JOYPAD1

  LOOP_BUTTONS:
    LDA JOYPAD1

    LSR
    ROL Buttons

    BCC LOOP_BUTTONS

  RTS
.endproc

.proc LoadPalette
  PPU_SETADDR $3F00

  LDY #0

  LOOPPALETTE:
    LDA PaletteData,Y
    STA PPU_DATA
    INY
    CPY #32
    BNE LOOPPALETTE

  RTS
.endproc

.proc LoadBackground
  LDA #<BackgroundData
  STA BackgroundPointer
  LDA #>BackgroundData
  STA BackgroundPointer+1

  PPU_SETADDR $2000

  LDX #$00
  LDY #$00

  OUTER_LOOP:
    INNER_LOOP:
      LDA (BackgroundPointer),y
      STA PPU_DATA
      INY
      CPY #0
      BEQ INCREASE_HI_BYTE
      JMP INNER_LOOP
    INCREASE_HI_BYTE:
      INC BackgroundPointer+1
      INX
      CPX #4
      BNE OUTER_LOOP
  RTS
.endproc

.proc LoadSprites
  LDX #0

  LOOP_SPRITES:
    LDA MarioData,X
    STA $0200,X
    INX
    CPX #16
    BNE LOOP_SPRITES
  LDX #0
  LOOP_GOOMBA:
    LDA GoombaData,X
    STA $0210,X
    INX
    CPX #16
    BNE LOOP_GOOMBA
  RTS
.endproc

  RESET:
    INIT_NES

    LDA #0
    STA Frame
    STA Clock60
    
    LDX #0
    LDA MarioData,x
    STA YPos
    INX
    INX
    INX
    LDA MarioData,x
    STA XPos
    MAIN:
      JSR LoadPalette
      JSR LoadBackground
      JSR LoadSprites

    ENABLE_PPU_RENDERING:
      LDA #%10010000
      STA PPU_CTRL

      LDA #0
      STA PPU_SCROLL
      STA PPU_SCROLL

      LDA #%00011110
      STA PPU_MASK

    LOOPFOREVER:
      JMP LOOPFOREVER

  NMI:
    INC Frame
    LDA #$02
    STA PPU_OAM_DMA

    JSR ReadControllers
   
    CHECK_RIGHT_BUTTON:
      LDA Buttons
      AND #BUTTON_RIGHT
      BEQ CHECK_LEFT_BUTTON
      INC XPos
    CHECK_LEFT_BUTTON:
      LDA Buttons
      AND #BUTTON_LEFT
      BEQ CHECK_DOWN_BUTTON
      DEC XPos
    CHECK_DOWN_BUTTON:
      LDA Buttons
      AND #BUTTON_DOWN
      BEQ CHECK_UP_BUTTON
      INC YPos
    CHECK_UP_BUTTON:
      LDA Buttons
      AND #BUTTON_UP
      BEQ :+
      DEC YPos
:

    UPDATE_SPRITE_POSITION:
      LDA XPos
      STA $0203
      STA $020B
      CLC
      ADC #8
      STA $0207
      STA $020F

      LDA YPos
      STA $0200
      STA $0204
      CLC
      ADC #8
      STA $0208
      STA $020C

    LDA Frame
    CMP #60
    BNE NMI_RETURN
    INC Clock60
    LDA #0
    STA Frame
    NMI_RETURN:
      RTI
  IRQ:
    RTI

PaletteData:
  .byte $22,$29,$1A,$0F, $22,$36,$17,$0F, $22,$30,$21,$0F, $22,$27,$17,$0F
  .byte $22,$16,$27,$18, $22,$1A,$30,$27, $22,$16,$30,$27, $22,$0F,$36,$17

BackgroundData:
  .incbin "background.nam"

MarioData:
  .byte $10, $3A, %00000000, $10
  .byte $10, $37, %00000000, $18
  .byte $18, $4F, %00000000, $10
  .byte $18, $4F, %01000000, $18

GoombaData:
  .byte $30, $70, %00100011, $30
  .byte $30, $70, %01100011, $38
  .byte $38, $72, %00100011, $30
  .byte $38, $72, %01100011, $38

.segment "CHARS"
.incbin "mario.chr"

.segment "VECTORS"
  .word NMI
  .word RESET
  .word IRQ

