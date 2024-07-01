.include "../consts.inc"
.include "../header.inc"
.include "../reset.inc"

.segment "CODE"
  .org $8000

.proc LoadPalette
  LDY #0

  LOOPPALETTE:
    LDA PaletteData,Y
    STA PPU_DATA
    INY
    CPY #32
    BNE LOOPPALETTE

  RTS
.endproc

  RESET:
    INIT_NES

    MAIN:
      BIT PPU_STATUS
      LDX #$3F
      STX PPU_ADDR
      LDX #$00
      STX PPU_ADDR

      JSR LoadPalette

      LDA #%00011110
      STA PPU_MASK

    LOOPFOREVER:
      JMP LOOPFOREVER

    RTI
  NMI:
    RTI
  IRQ:
    RTI

PaletteData:
  .byte $0F,$2A,$0C,$3A, $0F,$2A,$0C,$3A, $0F,$2A,$0C,$3A, $0F,$2A,$0C,$3A
  .byte $0F,$10,$00,$26, $0F,$10,$00,$26, $0F,$10,$00,$26, $0F,$10,$00,$26

.segment "VECTORS"
  .org $FFFA
  .word NMI
  .word RESET
  .word IRQ


