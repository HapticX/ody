import
  std/asyncdispatch,
  std/asyncnet,
  ./core/types


type
  MetadataType* {.pure, size: sizeof(uint8).} = enum
    Byte = 0
    VarInt = 1
    VarLong = 2
    Float = 3
    String = 4
    TextComponent = 5
    OptTextComponent = 6
    Slot = 7
    Boolean = 8
    Rotation = 9
    Position = 10
    OptPosition = 11
    Direction = 12
    OptUuid = 13
    BlockState = 14
    OptBlockState = 15
    Nbt = 16
    Particle = 17
    VillagerData = 18
    OptVarInt = 19
    Pose = 20
    CatVariant = 21
    FrogVariant = 22
    OptGlobalPosition = 23
    PaintingVariant = 24
    ShifferState = 25
    Vector3 = 26
    Quaternion = 27
  BaseMetadataIndex* {.pure, size: sizeof(uint8).} = enum
    StateBitmask = 0
    Air = 1
    CustomName = 2
    IsCustomNameVisible = 3
    IsSilent = 4
    NoGravity = 5


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
