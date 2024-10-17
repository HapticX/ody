import
  std/asyncdispatch,
  std/asyncnet,
  ./core/types


var
  entityIndexCounter* {.threadvar.}: int

entityIndexCounter = 0


method onMove*(entity: Entity, pos: Position) {.base.} =
  discard


method onNetSync*(entity: Entity) {.base.} =
  discard


method onTick*(entity: Entity) {.base.} =
  discard


method onCreate*(entity: Entity) {.base.} =
  discard


method isPlayer*(entity: Entity): bool {.base.} =
  not entity.Player.socket.isNil
