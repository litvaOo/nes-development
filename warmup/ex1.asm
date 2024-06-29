.segment "HEADER"
  .org $7FF0
  .byte $4E,$45,$53,$1A
  .byte $02
  .byte $01
  .byte %00000000
  .byte %00000000
  .byte $00
  .byte $00
  .byte $00
  .byte $00,$00,$00,$00,$00

.segment "CODE"
  .org $8000
    
  RESET:
    LDA #$82
    LDX #82
    LDY $82
    RTI
  NMI:
    RTI
  IRQ:
    RTI

.segment "VECTORS"
  .org $FFFA
  .word NMI
  .word RESET
  .word IRQ

