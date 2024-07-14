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

.macro PUSH_REGISTERS
  PHA
  TXA
  PHA
  TYA
  PHA
  PHP
.endmacro

.macro PULL_REGISTERS
  PLP
  PLA
  TAY
  PLA
  TAX
  PLA
.endmacro
