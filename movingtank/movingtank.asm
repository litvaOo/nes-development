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
    LDA TankData,X
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
    STA Clock60
    STA AnimFrame
    STA TileOffset

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
    STA PPU_OAM_DMA

    JSR ReadControllers
   
    CHECK_RIGHT_BUTTON:
      LDA Buttons
      AND #BUTTON_RIGHT
      BEQ NOT_RIGHT
        LDA XVel
        BMI NOT_RIGHT
          CLC
          ADC #ACCEL
          CMP #MAXSPEED
          BCC :+
            LDA #MAXSPEED
          :
          STA XVel
          JMP CHECK_LEFT_BUTTON
      NOT_RIGHT:
        LDA XVel
        BMI CHECK_LEFT_BUTTON
          CMP #BRAKE
          BCS :+
            LDA #BRAKE+1
          :
          SBC #BRAKE
          STA XVel
    CHECK_LEFT_BUTTON:
      LDA Buttons
      AND #BUTTON_LEFT
      BEQ NOT_LEFT
        LDA XVel
        BEQ :+
          BPL NOT_LEFT
        :
        SEC
        SBC #ACCEL
        CMP #256-MAXSPEED
        BCS :+
          LDA #256-MAXSPEED
        :
        STA XVel
        JMP CHECK_DOWN_BUTTON
      NOT_LEFT:
        LDA XVel
        BPL CHECK_DOWN_BUTTON
        CMP #256-BRAKE
        BCC :+
          LDA #256-BRAKE
        :
        ADC #BRAKE
        STA XVel
    CHECK_DOWN_BUTTON:
      LDA Buttons
      AND #BUTTON_DOWN
      BEQ CHECK_UP_BUTTON
      INC YPos
    CHECK_UP_BUTTON:
      LDA Buttons
      AND #BUTTON_UP
      BEQ :+
      DEC YPos
:

    UPDATE_SPRITE_POSITION:
      LDA XVel
      BPL :+
        DEC XPos+1
      :
      CLC
      ADC XPos
      STA XPos
      LDA #0
      ADC XPos+1
      STA XPos+1

    DRAW_SPRITE:
      LDA XPos+1
      STA $0203
      STA $020B
      CLC
      ADC #8
      STA $0207
      STA $020F

      LDA YPos+1
      STA $0200
      STA $0204
      CLC
      ADC #8
      STA $0208
      STA $020C

      LDA #0
      STA TileOffset
      LDA XPos+1
      AND #%00000001
      BEQ :+
        LDA #4
        STA TileOffset
      :

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
  .byte $1D,$10,$20,$2D, $1D,$1D,$2D,$10, $1D,$0C,$19,$1D, $1D,$06,$17,$07
  .byte $0F,$1D,$19,$29, $0F,$08,$18,$38, $0F,$0C,$1C,$3C, $0F,$2D,$10,$30

BackgroundData:
  .incbin "background.nam"

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


