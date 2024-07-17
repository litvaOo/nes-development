.enum ActorType
  NULL = 0
  PLAYER = 1
  SUBMARINE = 2
  AIRPLANE = 3
  MISSILE = 4
  BOMB = 5
  SPRITE0 = 6
.endenum

.struct Actor
  Type .byte
  XPos .byte
  YPos .byte
  XVel .byte
  YVel .byte
.endstruct
