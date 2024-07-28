.include "../consts.inc"
.include "header.inc"
.include "../reset.inc"
.include "../utils.inc"
.include "state.inc"
.include "actor.inc"

.segment "ZEROPAGE"
  PreviousButtons:   .res 1
  Buttons:           .res 1

  XPos:              .res 1 ; fixed point, hi byte is INT part
  YPos:              .res 1

  XVel:              .res 1 ; pixels per 256 frames
  YVel:              .res 1

  PreviousSubmarine: .res 1
  PreviousAirplane:  .res 1
  Frame:             .res 1
  Clock60:           .res 1
  IsDrawComplete:    .res 1
  BackgroundPointer: .res 2
  SpritePointer:     .res 2

  XScroll:           .res 1
  CurrentNametable:  .res 1
  Column:            .res 1
  NewColumnAddress:  .res 2
  SourceAddress:     .res 2
  AttributeColumn:   .res 1

  ActorsArray:       .res MAX_ACTORS * .sizeof(Actor)

  ParamType:         .res 1
  ParamXPos:         .res 1
  ParamYPos:         .res 1
  ParamTileIndex:    .res 1
  ParamNumberTiles:  .res 1
  ParamAttributes:   .res 1

  PreviousOAMBytes:  .res 1

  Seed:              .res 2

  Collision:         .res 1

  ParamRectX1:       .res 1
  ParamRectX2:       .res 1
  ParamRectY1:       .res 1
  ParamRectY2:       .res 1

  Score:             .res 4

  BufferPointer:     .res 2
  
  GameState:         .res 1

  MenuItem:          .res 1
  PalettePointer:    .res 2

  Offset:            .res 2
.segment "CODE"

.define FAMISTUDIO_CA65_ZP_SEGMENT   ZEROPAGE
.define FAMISTUDIO_CA65_RAM_SEGMENT  RAM
.define FAMISTUDIO_CA65_CODE_SEGMENT CODE

FAMISTUDIO_CFG_EXTERNAL       = 1
FAMISTUDIO_CFG_DPCM_SUPPORT   = 1
FAMISTUDIO_CFG_SFX_SUPPORT    = 1
FAMISTUDIO_CFG_SFX_STREAMS    = 2
FAMISTUDIO_CFG_EQUALIZER      = 1
FAMISTUDIO_USE_VOLUME_TRACK   = 1
FAMISTUDIO_USE_PITCH_TRACK    = 1
FAMISTUDIO_USE_SLIDE_NOTES    = 1
FAMISTUDIO_USE_VIBRATO        = 1
FAMISTUDIO_USE_ARPEGGIO       = 1
FAMISTUDIO_CFG_SMOOTH_VIBRATO = 1
FAMISTUDIO_USE_RELEASE_NOTES  = 1
FAMISTUDIO_DPCM_OFF           = $E000

.include "audioengine.asm"

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

  LDA MenuItem
  BEQ SET_PALETTE_CLEAR
  CMP #1
  BEQ SET_PALETTE_CLOUDY
  CMP #2
  BEQ SET_PALETTE_NIGHT

  SET_PALETTE_CLEAR:
    LDA #<PaletteDataClear
    STA PalettePointer
    LDA #>PaletteDataClear
    STA PalettePointer+1 
    JMP START_PALETTE_LOAD

  SET_PALETTE_CLOUDY:
    LDA #<PaletteDataCloudy
    STA PalettePointer
    LDA #>PaletteDataCloudy
    STA PalettePointer+1 
    JMP START_PALETTE_LOAD

  SET_PALETTE_NIGHT:
    LDA #<PaletteDataNight
    STA PalettePointer
    LDA #>PaletteDataNight
    STA PalettePointer+1 

  START_PALETTE_LOAD:
    PPU_SETADDR $3F00
    LDY #0
    LOOPPALETTE:
      LDA (PalettePointer),Y
      STA PPU_DATA
      INY
      CPY #32
      BNE LOOPPALETTE

  LDA XScroll
  STA PPU_SCROLL
  LDA #0
  STA PPU_SCROLL
  RTS
.endproc

.proc DrawScore
  LDA #$07
  STA BufferPointer+1
  LDA #$00
  STA BufferPointer

  LDY #0

  LDA #3
  STA (BufferPointer),Y
  INY

  LDA #$20
  STA (BufferPointer),Y
  INY
  LDA #$52
  STA (BufferPointer),Y
  INY

  LDA Score+2
  STA (BufferPointer),Y
  INY
  LDA Score+1
  STA (BufferPointer),Y
  INY
  LDA Score+0
  STA (BufferPointer),Y
  INY

  LDA #0
  STA (BufferPointer),Y
  INY

  RTS
.endproc

.proc DrawNewColumn
  ; destination
  LDA XScroll
  LSR
  LSR
  LSR
  STA NewColumnAddress

  LDA CurrentNametable
  EOR #1
  ASL
  ASL
  CLC
  ADC #$20
  STA NewColumnAddress+1

  ; Source 
  LDA Column
  ASL
  ASL
  ASL
  ASL
  ASL
  STA SourceAddress

  LDA Column
  LSR
  LSR
  LSR
  STA SourceAddress+1

  LDA SourceAddress
  CLC
  ADC #<BackgroundData
  STA SourceAddress

  LDA SourceAddress+1
  ADC #>BackgroundData
  STA SourceAddress+1

  DRAW_NEW_COLUMN:
    LDA #%00000100
    STA PPU_CTRL

    LDA PPU_STATUS
    LDA NewColumnAddress+1
    STA PPU_ADDR
    LDA NewColumnAddress
    STA PPU_ADDR

    LDX #30
    LDY #0
    DRAW_NEW_COLUMN_LOOP:
      LDA (SourceAddress),Y
      STA PPU_DATA
      INY
      DEX
      BNE DRAW_NEW_COLUMN_LOOP
  
  RTS
.endproc

.proc DrawAttributesColumn
  ; Destination
  LDA AttributeColumn
  AND #%00000111
  CLC
  ADC #$C0
  STA NewColumnAddress

  LDA CurrentNametable
  EOR #1
  ASL
  ASL
  CLC
  ADC #$23
  STA NewColumnAddress+1

  ; Source
  LDA AttributeColumn
  ASL
  ASL
  ASL
  STA SourceAddress

  LDA AttributeColumn
  LSR
  LSR
  LSR
  LSR
  LSR
  STA SourceAddress+1

  LDA SourceAddress
  CLC
  ADC #<AttributeData
  STA SourceAddress

  LDA SourceAddress+1
  ADC #>AttributeData
  STA SourceAddress+1

  DRAW_NEW_ATTRIBUTE_COLUMN:
    LDA #%00000000
    STA PPU_CTRL

    LDA PPU_STATUS
    LDA NewColumnAddress+1
    STA PPU_ADDR
    LDA NewColumnAddress
    STA PPU_ADDR

    LDX #8
    LDY #0
    DRAW_NEW_ATTRIBUTE_COLUMN_LOOP:
      LDA (SourceAddress),Y
      STA PPU_DATA
      INY
      LDA PPU_STATUS
      LDA NewColumnAddress+1
      STA PPU_ADDR
      LDA NewColumnAddress
      CLC
      ADC #8
      STA NewColumnAddress
      STA PPU_ADDR
      DEX
      BNE DRAW_NEW_ATTRIBUTE_COLUMN_LOOP

  LDA AttributeColumn
  CLC
  ADC #1
  CMP #32
  BNE ATTRIBUTE_DRAW_RETURN
    LDA #0
  ATTRIBUTE_DRAW_RETURN:
  STA AttributeColumn
  RTS
.endproc

.proc IsPointInsideBoundingBox
  LDA ParamXPos
  CMP ParamRectX1
  BCC :+

  CMP ParamRectX2
  BCS :+

  LDA ParamYPos
  CMP ParamRectY1
  BCC :+

  CMP ParamRectY2
  BCS :+
    LDA #1
    STA Collision
  :
  RTS
.endproc


.proc CheckCollisionWithEnemies
  TXA
  PHA

  LDX #0
  STX Collision

  ENEMY_COLLISION_LOOP:
    CPX #MAX_ACTORS * .sizeof(Actor)
    BEQ FINISH_COLLISION_CHECK
      LDA ActorsArray + Actor::Type,X
      CMP #ActorType::AIRPLANE
      BNE NEXT_ENEMY
      
      LDA ActorsArray + Actor::XPos,X
      STA ParamRectX1
      LDA ActorsArray + Actor::YPos,X
      STA ParamRectY1

      LDA ActorsArray + Actor::XPos,X
      CLC
      ADC #22
      STA ParamRectX2
      LDA ActorsArray + Actor::YPos,X
      CLC
      ADC #8
      STA ParamRectY2

      JSR IsPointInsideBoundingBox

      LDA Collision
      BEQ NEXT_ENEMY
        LDA #ActorType::NULL
        STA ActorsArray+Actor::Type,X
        JMP FINISH_COLLISION_CHECK
  NEXT_ENEMY:
    TXA
    CLC
    ADC #.sizeof(Actor)
    TAX
    JMP ENEMY_COLLISION_LOOP

  FINISH_COLLISION_CHECK:
  PLA
  TAX

  RTS
.endproc

.proc UpdateActors
  LDX #0
  UPDATE_ACTORS_LOOP:
    LDA ActorsArray + Actor::Type,X

    CMP #ActorType::MISSILE
    BNE :+
      LDA ActorsArray + Actor::YPos,X
      SEC
      SBC #3
      STA ActorsArray + Actor::YPos,X
      CMP #45
      BCS CHECK_COLLISION
        LDA #ActorType::NULL
        STA ActorsArray + Actor::Type,X
      
      CHECK_COLLISION:
        LDA ActorsArray + Actor::XPos,X
        CLC
        ADC #3
        STA ParamXPos

        LDA ActorsArray + Actor::YPos,X
        CLC
        ADC #1
        STA ParamYPos
        JSR CheckCollisionWithEnemies

        LDA Collision
        BEQ :+
          JSR IncrementScore
          JSR DrawScore

          LDA #ActorType::NULL
          STA ActorsArray + Actor::Type,X
 
          PUSH_REGISTERS
          LDA #1
          LDX #FAMISTUDIO_SFX_CH1
          JSR famistudio_sfx_play
          PULL_REGISTERS
    :

    CMP #ActorType::SUBMARINE
    BNE :+
      LDA ActorsArray + Actor::XPos,X
      SEC
      SBC #1
      STA ActorsArray + Actor::XPos,X
      BCS :+
        LDA #ActorType::NULL
        STA ActorsArray + Actor::Type,X
    :

    CMP #ActorType::AIRPLANE
    BNE :+
      LDA ActorsArray + Actor::XPos,X
      SEC
      SBC #2
      STA ActorsArray + Actor::XPos,X
      BCS :+
        LDA #ActorType::NULL
        STA ActorsArray + Actor::Type,X
    :

    NEXT_UPDATE_ACTOR:
      TXA
      CLC
      ADC #.sizeof(Actor)
      TAX
      CMP #MAX_ACTORS * .sizeof(Actor)
      BNE UPDATE_ACTORS_LOOP
  RTS
.endproc

.proc IncrementScore
  INCREMENT_ONES:
    LDA Score+0
    CLC
    ADC #1
    STA Score+0
    CMP #$A
    BNE :+
  INCREMENT_TENS:
    LDA #0
    STA Score+0
    LDA Score+1
    CLC
    ADC #1
    STA Score+1
    CMP #$A
    BNE :+
  INCREMENT_HUNDREDS:
    LDA #0
    STA Score+1
    LDA Score+2
    CLC
    ADC #1
    STA Score+2
    CMP #$A
    BNE :+
  INCREMENT_THOUSANDS:
    LDA #0
    STA Score+2
    LDA Score+3
    CLC
    ADC #1
    STA Score+3
    CMP #$A
    BNE :+
      LDA #0
      STA Score+3
  :
  RTS
.endproc

.proc AddNewActor
  LDX #0
  ADD_ACTOR_LOOP:
    CPX #MAX_ACTORS * .sizeof(Actor)
    BEQ END_ROUTINE
    LDA ActorsArray+Actor::Type,X
    CMP #ActorType::NULL
    BEQ ADD_NEW_ACTOR
    NEXT_ACTOR:
      TXA
      CLC
      ADC #.sizeof(Actor)
      TAX
      JMP ADD_ACTOR_LOOP

  ADD_NEW_ACTOR:
    LDA ParamType
    STA ActorsArray+Actor::Type,X
    LDA ParamXPos
    STA ActorsArray+Actor::XPos,X
    LDA ParamYPos
    STA ActorsArray+Actor::YPos,X
  END_ROUTINE:
    RTS
.endproc

.proc RenderActors
  LDA #$02
  STA SpritePointer+1
  LDA #$00
  STA SpritePointer

  LDY #0
  LDX #0
  RENDER_ACTORS_LOOP:
    LDA ActorsArray+Actor::Type,X

    CMP #ActorType::PLAYER
    BNE :+
      LDA ActorsArray+Actor::XPos,X
      STA ParamXPos
      LDA ActorsArray+Actor::YPos,X
      STA ParamYPos
      LDA #$60
      STA ParamTileIndex
      LDA #%00000000
      STA ParamAttributes
      LDA #4
      STA ParamNumberTiles

      JSR DrawSprite
      JMP NEXT_RENDER_ACTOR
    :

    CMP #ActorType::MISSILE
    BNE :+
      LDA ActorsArray+Actor::XPos,X
      STA ParamXPos
      LDA ActorsArray+Actor::YPos,X
      STA ParamYPos
      LDA #$50
      STA ParamTileIndex
      LDA #%00000001
      STA ParamAttributes
      LDA #1
      STA ParamNumberTiles

      JSR DrawSprite
      JMP NEXT_RENDER_ACTOR
    :

    CMP #ActorType::SPRITE0
    BNE :+
      LDA ActorsArray+Actor::XPos,X
      STA ParamXPos
      LDA ActorsArray+Actor::YPos,X
      STA ParamYPos
      LDA #$70
      STA ParamTileIndex
      LDA #%00100000
      STA ParamAttributes
      LDA #1
      STA ParamNumberTiles

      JSR DrawSprite
      JMP NEXT_RENDER_ACTOR
    :
    
    CMP #ActorType::SUBMARINE
    BNE :+
      LDA ActorsArray+Actor::XPos,X
      STA ParamXPos
      LDA ActorsArray+Actor::YPos,X
      STA ParamYPos
      LDA #$04
      STA ParamTileIndex
      LDA #%00100000
      STA ParamAttributes
      LDA #4
      STA ParamNumberTiles

      JSR DrawSprite
      JMP NEXT_RENDER_ACTOR
    :

    CMP #ActorType::AIRPLANE
    BNE :+
      LDA ActorsArray+Actor::XPos,X
      STA ParamXPos
      LDA ActorsArray+Actor::YPos,X
      STA ParamYPos
      LDA #$10
      STA ParamTileIndex
      LDA #%00000011
      STA ParamAttributes
      LDA #3
      STA ParamNumberTiles

      JSR DrawSprite
      JMP NEXT_RENDER_ACTOR
    :

    NEXT_RENDER_ACTOR:
      TXA
      CLC
      ADC #.sizeof(Actor)
      TAX
      CMP #MAX_ACTORS*.sizeof(Actor)
      BEQ :+
        JMP RENDER_ACTORS_LOOP
      :

  TYA
  PHA
  CLEAR_TAIL:
    CPY PreviousOAMBytes
    BCS :+
      LDA #$FF
      STA(SpritePointer),Y
      INY
      STA(SpritePointer),Y
      INY
      STA(SpritePointer),Y
      INY
      STA(SpritePointer),Y
      INY
      JMP CLEAR_TAIL
    :
  PLA
  STA PreviousOAMBytes
  RTS
.endproc

.proc DrawSprite
  TXA
  PHA
  LDX #0

  TILE_LOOP:
    LDA ParamYPos
    STA (SpritePointer),Y
    INY

    LDA ParamTileIndex
    STA (SpritePointer),Y
    INC ParamTileIndex
    INY

    LDA ParamAttributes
    STA (SpritePointer),Y
    INY

    LDA ParamXPos
    STA (SpritePointer),Y
    INY
    CLC
    ADC #8
    STA ParamXPos

    INX
    CPX ParamNumberTiles
    BNE TILE_LOOP

  PLA
  TAX

  RTS
.endproc

.proc GetRandomNumber
  LDY #0
  LDA Seed+0
  :
    ASL
    ROL Seed+1
    BCC :+
      EOR #$39
    :
    DEY
  BNE :--
  STA Seed+0
  CMP #0
  RTS
.endproc

.proc SpawnActors
  ; SPAWN_SUBMARINE:
  ;   LDA Clock60
  ;   SEC
  ;   SBC PreviousSubmarine
  ;   CMP #3
  ;   BNE :+
  ;     LDA #ActorType::SUBMARINE
  ;     STA ParamType
  ;     LDA #223
  ;     STA ParamXPos
  ;     JSR GetRandomNumber
  ;     LSR
  ;     LSR
  ;     LSR
  ;     CLC
  ;     ADC #180
  ;     STA ParamYPos
  ;
  ;     JSR AddNewActor
  ;
  ;     LDA Clock60
  ;     STA PreviousSubmarine
  ;   :
  SPAWN_AIRPLANE:
    LDA Clock60
    SEC
    SBC PreviousAirplane
    CMP #1
    BNE :+
      LDA #ActorType::AIRPLANE
      STA ParamType
      LDA #235
      STA ParamXPos
      JSR GetRandomNumber
      LSR
      LSR
      CLC
      ADC #40
      STA ParamYPos

      JSR AddNewActor

      LDA Clock60
      STA PreviousAirplane
    :
  RTS
.endproc

.proc SwitchCHRBank
  STA $8000
  RTS
.endproc


.proc LoadTitleScreenRLE
  LDA #<TitleScreenData
  STA BackgroundPointer
  LDA #>TitleScreenData
  STA BackgroundPointer+1

  PPU_SETADDR $2000

  LDY #$00

  LENGTH_LOOP:
    LDA (BackgroundPointer),Y
    BEQ END_ROUTINE
      INY

      BNE :+
        INC BackgroundPointer+1
      :
      TAX
      LDA (BackgroundPointer),Y
      INY
      BNE :+
        INC BackgroundPointer+1
      :

      TILE_LOOP:
        STA PPU_DATA
        DEX
        BNE TILE_LOOP
      JMP LENGTH_LOOP

  END_ROUTINE:
  RTS
.endproc

  RESET:
    INIT_NES

    ; LDA #%00000001
    ; STA APU_FLAGS

    TITLE_SCREEN:
      LDA #1
      JSR SwitchCHRBank

      LDA #State::TITLESCREEN
      STA GameState

      JSR LoadPalette
      JSR LoadTitleScreenRLE

      AUDIO_ENGINE_INIT:
        LDX #<music_data_titan
        LDY #>music_data_titan
        LDA #1
        JSR famistudio_init

        LDA #0
        JSR famistudio_music_play

      DRAW_MENU_ARROW:
        LDA #92
        STA $0200
        LDA #$23
        STA $0201
        LDA #%00000001
        STA $0202      
        LDA #95
        STA $0203

      ENABLE_NMI:
        LDA #%10010000
        STA PPU_CTRL
        LDA #%00011110
        STA PPU_MASK

      TITLE_SCREEN_LOOP:
        JSR ReadControllers
        CHECK_START_BUTTON:
        LDA Buttons
        AND #BUTTON_START
        BEQ :+
          JMP GAMEPLAY
        :
        LDA Buttons
        AND #BUTTON_DOWN
        BEQ :+
          LDA Buttons
          CMP PreviousButtons
          BEQ :+
            LDA MenuItem
            CMP #2
            BEQ :+
              LDA $0200
              CLC
              ADC #16
              STA $0200
              INC MenuItem
              JSR LoadPalette
        :

        LDA Buttons
        AND #BUTTON_UP
        BEQ :+
          LDA Buttons
          CMP PreviousButtons
          BEQ :+
            LDA MenuItem
            CMP #0
            BEQ :+
              LDA $0200
              SEC
              SBC #16
              STA $0200
              DEC MenuItem
              JSR LoadPalette
        :

        LDA Buttons
        STA PreviousButtons
        WAIT_FOR_VBLANK_TITLE:
          LDA IsDrawComplete
          BEQ WAIT_FOR_VBLANK_TITLE

        LDA #0
        STA IsDrawComplete

        JMP TITLE_SCREEN_LOOP 
    
    GAMEPLAY:
    LDA #0
    JSR SwitchCHRBank

    LDA #State::PLAYING
    STA GameState
    
    LDA #0
    STA PPU_CTRL
    STA PPU_MASK
    
    LDA #0
    STA Frame
    STA Clock60
    STA XScroll
    STA Column
    STA AttributeColumn
    LDA #113
    STA XPos
    LDA #165
    STA YPos
    LDA #$10
    STA Seed+0
    STA Seed+1

    JSR famistudio_music_stop
    LDX #<music_data_maritime
    LDY #>music_data_maritime

    LDA #1
    JSR famistudio_init

    LDA #0
    JSR famistudio_music_play

    LDX #<sounds
    LDA #>sounds

    JSR famistudio_sfx_init

    MAIN:
      JSR LoadPalette
    
    ADD_SPRITE_0:
      LDA #ActorType::SPRITE0
      STA ParamType
      LDA #0
      STA ParamXPos
      LDA #27
      STA ParamYPos
      JSR AddNewActor

    ADD_PLAYER:
      LDA #ActorType::PLAYER
      STA ParamType
      LDA XPos
      STA ParamXPos
      LDA YPos
      STA ParamYPos
      JSR AddNewActor

    LOAD_NAMETABLE_0:
      LDA #1
      STA CurrentNametable

      LOAD_NAMETABLE_0_LOOP:
        JSR DrawNewColumn
        LDA XScroll
        AND #%00011111
        BNE :+
          JSR DrawAttributesColumn
        :
        INC Column
        LDA XScroll
        CLC
        ADC #8
        STA XScroll
        LDA Column
        CMP #32
        BNE LOAD_NAMETABLE_0_LOOP

      LDA #0
      STA CurrentNametable
      STA XScroll

    ENABLE_PPU_RENDERING:
      LDA #%10010000
      STA PPU_CTRL

      LDA #0
      STA PPU_SCROLL
      STA PPU_SCROLL

      LDA #%00011110
      STA PPU_MASK

    GAME_LOOP:
      LDA Buttons
      STA PreviousButtons

      JSR ReadControllers

      CHECK_A_BUTTON:
        LDA Buttons
        AND #BUTTON_A
        BEQ :+
          LDA Buttons
          CMP PreviousButtons
          BEQ :+
            LDA #ActorType::MISSILE
            STA ParamType
            LDA XPos
            STA ParamXPos
            LDA YPos
            SEC
            SBC #8
            STA ParamYPos
            JSR AddNewActor

            LDA #0
            LDX #FAMISTUDIO_SFX_CH0
            JSR famistudio_sfx_play
        :

      CHECK_SELECT:
        LDA Buttons
        AND #BUTTON_SELECT
        BEQ :+
          LDA #1
          JSR SwitchCHRBank
        :

      JSR SpawnActors
      JSR UpdateActors
      JSR RenderActors

      WAIT_FOR_VBLANK:
        LDA IsDrawComplete
        BEQ WAIT_FOR_VBLANK

      LDA #0
      STA IsDrawComplete

      JMP GAME_LOOP

  NMI:
    PUSH_REGISTERS

    INC Frame

    OAM_COPY:
      LDA #$02
      STA PPU_OAM_DMA
   
    SKIP_SCROLLING:
      LDA GameState
      CMP #State::PLAYING
      BNE REFRESH_RENDERING

    BACKGROUND_BUFFER_RENDER:
      LDA #$00
      STA BufferPointer
      LDA #$07
      STA BufferPointer+1

      LDY #$0
      BACKGROUND_BUFFER_LOOP:
        LDA (BufferPointer),Y
        BEQ NEW_COLUMN_CHECK

        TAX

        INY
        LDA (BufferPointer),Y
        STA PPU_ADDR
        INY
        LDA (BufferPointer),Y
        STA PPU_ADDR
        INY
        DATA_LOOP:
          LDA (BufferPointer),Y
          CLC
          ADC #$60
          STA PPU_DATA
          INY
          DEX
          BNE DATA_LOOP
        JMP BACKGROUND_BUFFER_LOOP
    
    NEW_COLUMN_CHECK:
      LDA XScroll
      AND #%00000111
      BNE NEW_ATTRIBUTES_COLUMN_CHECK
        JSR DrawNewColumn
        CLAMP_128_COLUMNS:
          LDA Column
          CLC
          ADC #1
          AND #%01111111
          STA Column

    NEW_ATTRIBUTES_COLUMN_CHECK:
      LDA XScroll
      AND #%00011111
      BNE SET_PPU_NO_SCROLL
        JSR DrawAttributesColumn

    SET_PPU_NO_SCROLL:
      LDA #0
      STA PPU_SCROLL
      STA PPU_SCROLL

    ENABLE_PPU_SPRITE_0:
      LDA #%10010000
      STA PPU_CTRL
      LDA #%00011110
      STA PPU_MASK

    WAIT_FOR_NO_SPRITE_0:
      LDA PPU_STATUS
      AND #%01000000
      BNE WAIT_FOR_NO_SPRITE_0

    WAIT_FOR_SPRITE_0:
      LDA PPU_STATUS
      AND #%01000000
      BEQ WAIT_FOR_SPRITE_0

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
      

    SET_GAME_CLOCK:
      LDA Frame
      CMP #60
      BNE SET_DRAW_COMPLETE
      INC Clock60
      LDA #0
      STA Frame

    JSR DrawScore
    SET_DRAW_COMPLETE:
      LDA #1
      STA IsDrawComplete

    JSR famistudio_update
    ; JSR LoadPalette
    PULL_REGISTERS
    RTI
  IRQ:
    RTI

PaletteDataCloudy:
  .byte $1C,$0F,$22,$1C, $1C,$37,$3D,$0F, $1C,$37,$3D,$30, $1C,$0F,$3D,$30
  .byte $1C,$0F,$2D,$10, $1C,$0F,$20,$27, $1C,$2D,$38,$18, $1C,$0F,$1A,$32
PaletteDataClear:
  .byte $1C,$0F,$22,$1C, $1C,$36,$21,$0B, $1C,$36,$21,$30, $1C,$0F,$3D,$30
  .byte $1C,$0F,$2D,$10, $1C,$0F,$20,$27, $1C,$2D,$38,$18, $1C,$0F,$1A,$32
PaletteDataNight:
  .byte $0C,$0F,$1C,$0C, $0C,$26,$0C,$0F, $0C,$26,$0C,$2D, $0C,$36,$07,$2D
  .byte $0C,$0F,$1D,$2D, $0C,$0F,$20,$27, $0C,$2D,$38,$18, $0C,$0F,$1A,$21

BackgroundData:
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$23,$33,$15,$21,$12,$00,$31,$31,$31,$55,$56,$00,$00
  .byte $13,$13,$75,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$42,$21,$21,$21,$24,$34,$15,$15,$12,$00,$31,$31,$53,$56,$56,$00,$00
  .byte $13,$13,$6e,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$43,$21,$21,$21,$14,$11,$3e,$15,$12,$00,$00,$00,$31,$52,$56,$00,$00
  .byte $13,$13,$7f,$13,$20,$21,$21,$21,$21,$21,$21,$21,$42,$21,$21,$44,$21,$21,$21,$14,$11,$3f,$15,$12,$00,$00,$00,$31,$5a,$56,$00,$00
  .byte $13,$13,$6e,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$45,$21,$21,$21,$22,$32,$15,$15,$12,$00,$00,$00,$31,$58,$56,$00,$00
  .byte $13,$13,$75,$13,$20,$21,$21,$21,$21,$21,$21,$21,$45,$21,$21,$46,$21,$21,$21,$26,$36,$15,$15,$12,$00,$00,$00,$51,$5c,$56,$00,$00
  .byte $13,$13,$84,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$27,$37,$15,$15,$12,$00,$00,$00,$00,$58,$56,$00,$00
  .byte $13,$13,$61,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$28,$38,$15,$15,$12,$00,$00,$00,$00,$5c,$56,$00,$00
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$57,$56,$00,$00
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$47,$21,$21,$21,$48,$21,$21,$22,$32,$3e,$15,$12,$00,$00,$00,$00,$58,$56,$00,$00
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$42,$21,$21,$21,$4a,$21,$21,$23,$33,$4e,$15,$12,$00,$00,$00,$00,$59,$56,$00,$00
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$43,$21,$21,$21,$21,$21,$21,$24,$34,$3f,$15,$12,$00,$00,$00,$00,$58,$56,$00,$00
  .byte $13,$13,$7c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$57,$56,$00,$00
  .byte $13,$13,$6c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$45,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$59,$56,$00,$00
  .byte $13,$13,$78,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$15,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$58,$56,$00,$00
  .byte $13,$13,$7b,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$15,$15,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$53,$56,$00,$00
  .byte $13,$13,$6e,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$21,$15,$21,$21,$25,$35,$15,$15,$12,$00,$00,$00,$00,$54,$56,$00,$00
  .byte $13,$13,$84,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$21,$26,$36,$15,$15,$12,$00,$00,$00,$00,$58,$56,$00,$00
  .byte $13,$13,$60,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$27,$37,$15,$15,$12,$00,$00,$00,$00,$58,$56,$00,$00
  .byte $13,$13,$60,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$48,$21,$21,$15,$27,$37,$15,$15,$12,$00,$00,$00,$00,$5d,$56,$00,$00
  .byte $13,$13,$60,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$49,$21,$21,$21,$28,$38,$3e,$21,$12,$00,$00,$00,$00,$58,$56,$00,$00
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$49,$21,$21,$21,$22,$35,$3f,$21,$12,$00,$00,$00,$00,$58,$56,$00,$00
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$49,$21,$21,$21,$26,$36,$3f,$21,$12,$00,$00,$00,$00,$57,$56,$00,$00
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$4a,$21,$21,$21,$27,$37,$21,$15,$12,$00,$00,$00,$00,$58,$56,$00,$00
  .byte $13,$13,$76,$13,$20,$21,$21,$21,$21,$21,$21,$21,$42,$21,$21,$21,$21,$21,$21,$28,$38,$15,$15,$12,$00,$00,$00,$00,$58,$56,$00,$00
  .byte $13,$13,$72,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$21,$21,$21,$21,$14,$11,$3e,$21,$12,$00,$00,$00,$00,$59,$56,$00,$00
  .byte $13,$13,$7c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$43,$21,$21,$21,$21,$21,$21,$14,$11,$4e,$21,$12,$00,$00,$00,$51,$59,$56,$00,$00
  .byte $13,$13,$7c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$21,$21,$21,$21,$14,$11,$3f,$15,$12,$00,$00,$00,$00,$5c,$56,$00,$00
  .byte $13,$13,$75,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$21,$21,$21,$21,$29,$39,$21,$21,$12,$00,$00,$00,$00,$55,$56,$00,$00
  .byte $13,$13,$84,$13,$20,$21,$21,$21,$21,$21,$21,$21,$45,$21,$21,$21,$48,$21,$2c,$2a,$3a,$3c,$21,$12,$00,$00,$00,$54,$56,$56,$00,$00
  .byte $13,$13,$65,$13,$20,$21,$21,$21,$21,$21,$21,$21,$46,$21,$21,$21,$4a,$21,$2d,$2a,$3a,$3d,$15,$12,$00,$00,$00,$00,$52,$56,$00,$00
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$2b,$3b,$15,$15,$12,$00,$00,$00,$00,$57,$56,$00,$00

  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$15,$21,$12,$00,$31,$31,$31,$55,$56,$ff,$9a
  .byte $13,$13,$75,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$21,$15,$21,$14,$11,$15,$15,$12,$00,$31,$31,$53,$56,$56,$ff,$5a
  .byte $13,$13,$6e,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$15,$15,$21,$14,$11,$3e,$15,$12,$00,$00,$00,$31,$52,$56,$ff,$5a
  .byte $13,$13,$7f,$13,$20,$21,$21,$21,$21,$21,$21,$21,$42,$21,$21,$15,$15,$15,$21,$14,$11,$3f,$15,$12,$00,$00,$00,$31,$5a,$56,$ff,$56
  .byte $13,$13,$6e,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$15,$15,$15,$21,$14,$11,$15,$15,$12,$00,$00,$00,$31,$58,$56,$ff,$59
  .byte $13,$13,$75,$13,$20,$21,$21,$21,$21,$21,$21,$21,$45,$21,$21,$15,$15,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$51,$5c,$56,$ff,$5a
  .byte $13,$13,$84,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$15,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$58,$56,$ff,$5a
  .byte $13,$13,$61,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$5c,$56,$ff,$5a
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$57,$56,$aa,$00
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$47,$21,$21,$21,$48,$21,$21,$14,$11,$3e,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$42,$21,$21,$21,$4a,$21,$21,$14,$11,$4e,$15,$12,$00,$00,$00,$00,$59,$56,$aa,$00
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$43,$21,$21,$21,$21,$21,$21,$25,$35,$3f,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$7c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$21,$21,$21,$21,$26,$36,$15,$15,$12,$00,$00,$00,$00,$57,$56,$aa,$00
  .byte $13,$13,$6c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$45,$21,$21,$21,$21,$21,$21,$27,$37,$15,$15,$12,$00,$00,$00,$00,$59,$56,$aa,$00
  .byte $13,$13,$78,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$15,$21,$21,$21,$28,$38,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$7b,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$15,$15,$21,$21,$29,$39,$15,$15,$12,$00,$00,$00,$00,$53,$56,$aa,$00
  .byte $13,$13,$6e,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$21,$15,$21,$1f,$2a,$3a,$3c,$15,$12,$00,$00,$00,$00,$54,$56,$aa,$00
  .byte $13,$13,$84,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$21,$28,$3b,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$60,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$14,$11,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$60,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$48,$21,$21,$15,$14,$11,$15,$15,$12,$00,$00,$00,$00,$5d,$56,$aa,$00
  .byte $13,$13,$60,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$49,$21,$21,$21,$14,$11,$3e,$21,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$49,$21,$21,$21,$14,$11,$3f,$21,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$49,$21,$21,$21,$14,$11,$3f,$21,$12,$00,$00,$00,$00,$57,$56,$aa,$00
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$4a,$21,$21,$21,$14,$11,$21,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$76,$13,$20,$21,$21,$21,$21,$21,$21,$21,$42,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$58,$56,$5a,$00
  .byte $13,$13,$72,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$21,$21,$21,$21,$14,$11,$3e,$21,$12,$00,$00,$00,$00,$59,$56,$9a,$00
  .byte $13,$13,$7c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$43,$21,$21,$21,$21,$21,$21,$22,$32,$4e,$21,$12,$00,$00,$00,$51,$59,$56,$aa,$00
  .byte $13,$13,$7c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$21,$21,$21,$21,$23,$33,$3f,$15,$12,$00,$00,$00,$00,$5c,$56,$6a,$00
  .byte $13,$13,$75,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$21,$21,$21,$21,$24,$34,$21,$21,$12,$00,$00,$00,$00,$55,$56,$9a,$00
  .byte $13,$13,$84,$13,$20,$21,$21,$21,$21,$21,$21,$21,$45,$21,$21,$21,$48,$15,$15,$14,$11,$15,$21,$12,$00,$00,$00,$54,$56,$56,$aa,$00
  .byte $13,$13,$65,$13,$20,$21,$21,$21,$21,$21,$21,$21,$46,$21,$21,$21,$4a,$21,$15,$14,$11,$15,$15,$12,$00,$00,$00,$00,$52,$56,$aa,$00
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$57,$56,$aa,$00

  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$15,$21,$12,$00,$31,$31,$31,$58,$56,$ff,$9a
  .byte $13,$13,$75,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$42,$21,$21,$21,$14,$11,$15,$15,$12,$00,$31,$31,$00,$5d,$56,$ff,$5a
  .byte $13,$13,$6e,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$43,$21,$21,$21,$14,$11,$3e,$15,$12,$00,$00,$00,$31,$58,$56,$ff,$5a
  .byte $13,$13,$7f,$13,$20,$21,$21,$21,$21,$21,$21,$21,$42,$21,$21,$44,$21,$21,$21,$14,$11,$3f,$15,$12,$00,$00,$00,$31,$58,$56,$ff,$aa
  .byte $13,$13,$6e,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$45,$21,$21,$21,$22,$32,$15,$15,$12,$00,$00,$00,$31,$58,$56,$ff,$56
  .byte $13,$13,$75,$13,$20,$21,$21,$21,$21,$21,$21,$21,$45,$21,$21,$46,$21,$21,$21,$26,$36,$15,$15,$12,$00,$00,$00,$51,$58,$56,$ff,$9a
  .byte $13,$13,$84,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$27,$37,$15,$15,$12,$00,$00,$00,$00,$58,$56,$ff,$59
  .byte $13,$13,$61,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$28,$38,$15,$15,$12,$00,$00,$00,$00,$55,$56,$ff,$5a
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$57,$56,$56,$aa,$00
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$47,$21,$21,$21,$48,$21,$21,$22,$32,$3e,$15,$12,$00,$00,$00,$00,$52,$56,$aa,$00
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$42,$21,$21,$21,$4a,$21,$21,$23,$33,$4e,$15,$12,$00,$00,$00,$00,$53,$56,$aa,$00
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$43,$21,$21,$21,$21,$21,$21,$24,$34,$3f,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$7c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$6c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$45,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$78,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$7b,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$59,$56,$aa,$00
  .byte $13,$13,$6e,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$84,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$29,$39,$15,$15,$12,$00,$00,$00,$00,$59,$56,$aa,$00
  .byte $13,$13,$60,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$1f,$2a,$3a,$3d,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$60,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$48,$21,$15,$2d,$2a,$3a,$3c,$15,$12,$00,$00,$00,$00,$5b,$56,$aa,$00
  .byte $13,$13,$60,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$49,$21,$21,$2f,$2a,$3a,$3d,$21,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$49,$21,$21,$21,$28,$3b,$3e,$21,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$49,$21,$21,$21,$14,$11,$4e,$21,$12,$00,$00,$00,$51,$58,$56,$aa,$00
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$4a,$21,$21,$21,$14,$11,$21,$15,$12,$00,$00,$00,$51,$58,$56,$aa,$00
  .byte $13,$13,$76,$13,$20,$21,$21,$21,$21,$21,$21,$21,$42,$21,$21,$21,$21,$21,$15,$29,$39,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$72,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$21,$21,$15,$2c,$2a,$3a,$3e,$21,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$7c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$43,$21,$21,$21,$21,$21,$2e,$2a,$3a,$4e,$21,$12,$00,$00,$00,$51,$58,$56,$aa,$00
  .byte $13,$13,$7c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$21,$21,$21,$1f,$2a,$3a,$3f,$15,$12,$00,$00,$00,$00,$5d,$56,$aa,$00
  .byte $13,$13,$75,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$21,$21,$21,$15,$28,$3b,$3f,$21,$12,$00,$00,$00,$00,$57,$56,$aa,$00
  .byte $13,$13,$84,$13,$20,$21,$21,$21,$21,$21,$21,$21,$45,$21,$21,$21,$48,$21,$15,$14,$11,$15,$21,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$65,$13,$20,$21,$21,$21,$21,$21,$21,$21,$46,$21,$21,$21,$4a,$21,$15,$14,$11,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00

  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$15,$21,$12,$00,$31,$31,$31,$58,$56,$ff,$9a
  .byte $13,$13,$75,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$21,$14,$11,$15,$15,$12,$00,$31,$31,$00,$58,$56,$ff,$5a
  .byte $13,$13,$6e,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$31,$58,$56,$ff,$5a
  .byte $13,$13,$7f,$13,$20,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$15,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$31,$54,$56,$ff,$59
  .byte $13,$13,$6e,$13,$20,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$15,$21,$21,$21,$14,$11,$3e,$15,$12,$00,$00,$00,$31,$54,$56,$ff,$56
  .byte $13,$13,$75,$13,$20,$21,$21,$21,$21,$21,$21,$42,$15,$21,$21,$15,$21,$21,$21,$14,$11,$4e,$15,$12,$00,$00,$00,$51,$58,$56,$ff,$5a
  .byte $13,$13,$84,$13,$20,$21,$21,$21,$21,$21,$21,$43,$21,$21,$21,$21,$21,$21,$21,$14,$11,$4e,$15,$12,$00,$00,$00,$00,$58,$56,$ff,$59
  .byte $13,$13,$61,$13,$20,$21,$21,$21,$21,$21,$21,$44,$21,$21,$21,$21,$21,$21,$21,$14,$11,$3f,$15,$12,$00,$00,$00,$00,$58,$56,$ff,$5a
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$45,$21,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$47,$15,$21,$21,$21,$15,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$53,$56,$aa,$00
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$21,$15,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$57,$56,$aa,$00
  .byte $13,$13,$7c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$21,$21,$21,$21,$29,$39,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$6c,$13,$20,$21,$21,$21,$21,$21,$48,$21,$15,$21,$21,$21,$21,$1d,$1e,$2a,$3a,$3c,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$78,$13,$20,$21,$21,$21,$21,$21,$49,$21,$21,$21,$21,$21,$21,$21,$21,$2b,$3b,$3e,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$7b,$13,$20,$21,$21,$21,$21,$21,$4a,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$4e,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$6e,$13,$20,$21,$21,$21,$21,$15,$48,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$4e,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$84,$13,$20,$21,$21,$21,$21,$21,$49,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$3f,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$60,$13,$20,$21,$21,$21,$21,$21,$4a,$21,$21,$21,$21,$21,$21,$15,$15,$14,$11,$15,$15,$12,$00,$00,$00,$00,$59,$56,$aa,$00
  .byte $13,$13,$60,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$21,$15,$15,$14,$11,$15,$15,$12,$00,$00,$00,$00,$59,$56,$aa,$00
  .byte $13,$13,$60,$13,$20,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$15,$21,$21,$15,$14,$11,$15,$21,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$42,$21,$21,$21,$15,$21,$21,$21,$29,$39,$15,$21,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$43,$21,$21,$21,$15,$21,$21,$2c,$2a,$3a,$3c,$21,$12,$00,$00,$00,$50,$58,$56,$aa,$00
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$44,$15,$21,$21,$15,$21,$21,$2d,$2a,$3a,$3e,$15,$12,$00,$00,$00,$50,$58,$56,$aa,$00
  .byte $13,$13,$76,$13,$20,$21,$21,$21,$21,$21,$21,$45,$15,$21,$21,$21,$21,$21,$15,$2b,$3b,$3f,$15,$12,$00,$00,$00,$00,$54,$56,$aa,$00
  .byte $13,$13,$72,$13,$20,$21,$21,$21,$21,$21,$21,$46,$15,$21,$21,$21,$21,$15,$15,$14,$11,$3f,$21,$12,$00,$00,$00,$00,$59,$56,$aa,$00
  .byte $13,$13,$7c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$21,$21,$21,$15,$14,$11,$15,$21,$12,$00,$00,$00,$51,$58,$56,$aa,$00
  .byte $13,$13,$7c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$21,$21,$21,$15,$14,$11,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$75,$13,$20,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$21,$21,$21,$15,$14,$11,$15,$21,$12,$00,$00,$00,$00,$5d,$56,$aa,$00
  .byte $13,$13,$84,$13,$20,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$21,$15,$21,$15,$14,$11,$15,$21,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$65,$13,$20,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$21,$15,$15,$15,$14,$11,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
  .byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$22,$32,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00

AttributeData:
  .byte $ff,$aa,$aa,$aa,$9a,$00,$00,$00
  .byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00
  .byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00
  .byte $ff,$aa,$aa,$6a,$a6,$00,$00,$00
  .byte $ff,$aa,$aa,$9a,$59,$00,$00,$00
  .byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00
  .byte $ff,$aa,$aa,$aa,$9a,$00,$00,$00
  .byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00

  .byte $ff,$aa,$aa,$5a,$9a,$00,$00,$00
  .byte $ff,$aa,$aa,$9a,$5a,$00,$00,$00
  .byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00
  .byte $ff,$aa,$aa,$6a,$56,$00,$00,$00
  .byte $ff,$aa,$aa,$9a,$59,$00,$00,$00
  .byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00
  .byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00
  .byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00

  .byte $ff,$aa,$aa,$aa,$9a,$00,$00,$00
  .byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00
  .byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00
  .byte $ff,$aa,$aa,$aa,$aa,$00,$00,$00
  .byte $ff,$aa,$aa,$aa,$56,$00,$00,$00
  .byte $ff,$aa,$aa,$aa,$9a,$00,$00,$00
  .byte $ff,$aa,$aa,$aa,$59,$00,$00,$00
  .byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00

  .byte $ff,$aa,$aa,$aa,$9a,$00,$00,$00
  .byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00
  .byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00
  .byte $ff,$aa,$aa,$aa,$59,$00,$00,$00
  .byte $ff,$aa,$aa,$aa,$56,$00,$00,$00
  .byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00
  .byte $ff,$aa,$aa,$aa,$59,$00,$00,$00
  .byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00

TitleScreenData:
  .incbin "titlescreen.rle"

MusicData:
  .include "music/titan.asm"
  .include "music/maritime.asm"

SoundFXData:
  .include "sfx/sounds.asm"

.segment "CHARS1"
  .incbin "atlantico.chr"

.segment "CHARS2"
  .incbin "titlescreen.chr"

.segment "VECTORS"
  .word NMI
  .word RESET
  .word IRQ
