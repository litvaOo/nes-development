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

.proc LoadText
  ; BYTE - $36 = SPRITE_TABLE[2][pos]
  ; Except space, where BYTE = $20, but sprite is $24

  PPU_SETADDR $2100

  LDY $00
  
  LOAD_TEXT_LOOP:
    LDA TextMessage,Y
    BEQ LOAD_TEXT_RETURN
    INY
    CMP #$20
    BEQ DRAW_SPACE
 
    CLC
    SBC #$36
    JMP DRAW
    DRAW_SPACE:
      LDA #$24
    DRAW:
      STA PPU_DATA
    JMP LOAD_TEXT_LOOP
  LOAD_TEXT_RETURN:
    RTS
  
.endproc

  RESET:
    INIT_NES

    LDA #0
    STA Frame

    MAIN:
      JSR LoadPalette
      JSR LoadBackground
      JSR LoadText

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
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$36,$37,$36,$37,$36,$37,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$35,$25,$25,$25,$25,$25,$25,$38,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$36,$37,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$39,$3A,$3B,$3A,$3B,$3A,$3B,$3C,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$35,$25,$25,$38,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$39,$3A,$3B,$3C,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$53,$54,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$55,$56,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$53,$54,$24,$24,$24,$24,$24,$24,$24,$24,$45,$45,$53,$54,$45,$45,$53,$54,$45,$45,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$55,$56,$24,$24,$24,$24,$24,$24,$24,$24,$47,$47,$55,$56,$47,$47,$55,$56,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$60,$61,$62,$63,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$31,$32,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$64,$65,$66,$67,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$30,$26,$34,$33,$24,$24,$24,$24,$36,$37,$36,$37,$24,$24,$24,$24,$24,$24,$24,$68,$69,$26,$6A,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$30,$26,$26,$26,$26,$33,$24,$24,$35,$25,$25,$25,$25,$38,$24,$24,$24,$24,$24,$24,$68,$69,$26,$6A,$24,$24,$24,$24
  .byte $B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5
  .byte $B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7
  .byte $B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B6
  .byte $B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7
  .byte $B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5
  .byte $B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7

AttributeData:
  .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .byte %00000000, %10101010, %10101010, %00000000, %00000000, %00000000, %10101010, %00000000
  .byte %00000000, %00000000, %00000000, %00000000, %11111111, %00000000, %00000000, %00000000
  .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .byte %11111111, %00000000, %00000000, %00001111, %00001111, %00000011, %00000000, %00000000
  .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .byte %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111
  .byte %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111

TextMessage:
  .byte "HELLO WORLD",$0

.segment "CHARS"
.incbin "mario.chr"

.segment "VECTORS"
  .word NMI
  .word RESET
  .word IRQ



