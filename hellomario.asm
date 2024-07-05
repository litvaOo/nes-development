.include "consts.inc"
.include "header.inc"
.include "reset.inc"
.include "utils.inc"

.segment "ZEROPAGE"
Frame:             .res 1
Clock60:           .res 1
BackgroundPointer: .res 2


.segment "CODE"

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
    STA $4014
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



