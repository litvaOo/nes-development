.macro INIT_NES
    SEI
    CLD
    LDX #$40
    STX $4017
    LDX #$FF
    TXS

    INX

    STX PPU_CTRL
    STX PPU_MASK
    STX $4010

    bit PPU_STATUS

    VBLANKWAIT1:
      BIT PPU_STATUS
      BPL VBLANKWAIT1

    TXA
    MEMLOOP:
      STA $0000,X
      STA $0100,X
      STA $0200,X
      STA $0300,X
      STA $0400,X
      STA $0500,X
      STA $0600,X
      STA $0700,X
      INX
      BNE MEMLOOP

    VBLANKWAIT2:
      BIT PPU_STATUS
      BPL VBLANKWAIT2

.endmacro
