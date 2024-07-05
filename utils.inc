.macro PPU_SETADDR addr
  BIT PPU_STATUS
  LDA #>addr
  STA PPU_ADDR
  LDA #<addr
  STA PPU_ADDR
.endmacro

.macro PPU_SETDATA val
  LDA val
  STA PPU_DATA
.endmacro
