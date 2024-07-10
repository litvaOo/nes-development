.include "../consts.inc"
.include "../header.inc"
.include "../reset.inc"
.include "../utils.inc"

.segment "ZEROPAGE"
Frame:             .res 1
Clock60:           .res 1
BackgroundPointer: .res 2
Buttons:           .res 1

XPos:              .res 2 ; fixed point, hi byte is INT part
YPos:              .res 2

AnimFrame:         .res 1
TileOffset:        .res 1

XVel:              .res 1 ; pixels per 256 frames
YVel:              .res 1

XScroll:           .res 1

CurrentNametable:  .res 1

MAXSPEED = 120
ACCEL = 2
BRAKE = 2

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

.proc LoadNametable0
  LDA #<BackgroundData0
  STA BackgroundPointer
  LDA #>BackgroundData0
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

.proc LoadNametable1
  LDA #<BackgroundData1
  STA BackgroundPointer
  LDA #>BackgroundData1
  STA BackgroundPointer+1

  PPU_SETADDR $2400

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
    LDA TankData,X
    STA $0200,X
    INX
    CPX #16
    BNE LOOP_SPRITES
  RTS
.endproc

  RESET:
    INIT_NES

    LDA #0
    STA Frame
    STA Clock60
    STA AnimFrame
    STA TileOffset
    STA XScroll
    STA CurrentNametable

    LDX #0
    LDA TankData,x
    STA YPos+1
    INX
    INX
    INX
    LDA TankData,x
    STA XPos+1
    MAIN:
      JSR LoadPalette
      JSR LoadNametable0
      JSR LoadNametable1
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
    OAM_COPY:
      LDA #$02
      STA PPU_OAM_DMA

    SCROLL_BACKGROUND:
      INC XScroll

      LDA XScroll
      BNE :+
        LDA CurrentNametable
        EOR #1
        STA CurrentNametable
      :

      LDA XScroll
      STA PPU_SCROLL
      LDA #0
      STA PPU_SCROLL

    REFRESH_RENDERING:
      LDA #%10010000
      ORA CurrentNametable
      STA PPU_CTRL
      LDA #%00011110
      STA PPU_MASK

    SET_ANIMATION_FRAME:
      LDA #0
      STA TileOffset
      
      LDA XScroll
      AND #%00000001
      BEQ :+
        LDA #4
        STA TileOffset
      :

    SET_SPRITE_TILES:
      LDA #$18
      CLC
      ADC TileOffset
      STA $201

      LDA #$1A
      CLC
      ADC TileOffset
      STA $205

      LDA #$19
      CLC
      ADC TileOffset
      STA $209

      LDA #$1B
      CLC
      ADC TileOffset
      STA $20D

    SET_GAME_CLOCK:
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
  .byte $1D,$10,$20,$21, $1D,$1D,$2D,$24, $1D,$0C,$19,$1D, $1D,$06,$17,$07
  .byte $0F,$1D,$19,$29, $0F,$08,$18,$38, $0F,$0C,$1C,$3C, $0F,$2D,$10,$30

BackgroundData0:
  .incbin "nametable0.nam"

BackgroundData1:
  .incbin "nametable1.nam"

TankData:
  .byte  $80,$18,%00000000,$10
  .byte  $80,$1A,%00000000,$18
  .byte  $88,$19,%00000000,$10
  .byte  $88,$1B,%00000000,$18

GoombaData:
  .byte $30, $70, %00100011, $30
  .byte $30, $70, %01100011, $38
  .byte $38, $72, %00100011, $30
  .byte $38, $72, %01100011, $38

.segment "CHARS"
.incbin "battle.chr"

.segment "VECTORS"
  .word NMI
  .word RESET
  .word IRQ


