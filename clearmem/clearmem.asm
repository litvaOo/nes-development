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
    txs  ;Initialize stack

    lda #0
    inx
    MemLoop:
      sta $0,x
      dex
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
