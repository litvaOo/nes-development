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
    sei
    cld
    ldx #$FF
    txs

    inx

    txa
    MemLoop:
      sta $0000,x
      sta $0100,x
      sta $0200,x
      sta $0300,x
      sta $0400,x
      sta $0500,x
      sta $0600,x
      sta $0700,x
      inx
      bne MemLoop
    rti
NMI:
    rti
  IRQ:
    rti

.segment "VECTORS"
  .org $FFFA
  .word NMI
  .word RESET
  .word IRQ
