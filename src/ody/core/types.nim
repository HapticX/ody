import
  std/json,
  std/asyncnet,
  uuids


export
  json,
  asyncnet,
  uuids



type
  PlayerState* {.pure, size: sizeof(uint8).} = enum
    Status
    Handshake
    Login
    Play
    Transfer
  PositionFormat* {.pure, size: sizeof(uint8).} = enum
    XYZ = 0'u8
    XZY
  Dimension* {.pure, size: sizeof(int8).} = enum
    Nether = -1
    Overworld = 0
    End = 1
  GameMode* {.pure, size: sizeof(uint8).} = enum
    Survival = 0
    Creative = 1
    Adventure = 2
    Spectator = 3
  ChatMessageType* {.pure, size: sizeof(uint8).} = enum
    ChatBox = 0
    System = 1
    GameInfo = 2
  Identifier* = object
    namespace*: string
    value*: string
  Position* = object
    format*: PositionFormat
    y*: int16
    x*: int32
    z*: int32
  World* = ref object
    isActive*: bool
    tickRate*: int
    entities*: seq[Entity]
    name*: string
  Entity* {.inheritable.} = ref object
    id*: int
    uuid*: UUID
    name*: string
  Player* = ref object of Entity
    socket*: AsyncSocket
    protocolVersion*: int
    host*: string
    port*: uint16
    username*: string


func `$`*(i: Identifier): string =
  ## Get an identifier as a string.
  i.namespace & ":" & i.value



func toPos*(val: int64, format = XZY): Position =
  ## Parses an int64 value to get the position, by default uses XZY,
  ## as that is what is used for modern MC versions (1.14+).
  Position(
    x: (val shr 38).int32,
    y:
      if format == XZY:
        (val shl 52 shr 52).int16
      else:
        ((val shl 26) and 0xFFF).int16,
    z:
      if format == XZY:
        (((val shl 26).int32).ashr 38).int32
      else:
        (val shl 38 shr 38).int32,
    format: format
  )



proc fromPos*(pos: Position, format = XZY): int64 =
  ## Returns an int64 from a `Position`, by default uses XZY,
  ## as that is what is used for modern MC versions (1.14+).
  if format == XZY:
    return ((pos.x.int64 and 0x3FFFFFF) shl 38) or ((pos.z.int64 and 0x3FFFFFF) shl 12) or (pos.y.int64 and 0xFFF)

  elif format == XYZ:
    return ((pos.x.int64 and 0x3FFFFFF) shl 38) or ((pos.y.int64 and 0xFFF) shl 26) or (pos.z.int64 and 0x3FFFFFF)


func fromJsonHook*(uuid: var UUID, node: JsonNode) =
  ## Converts a UUID from JSON.
  uuid = node.getStr().parseUUID()

func toJsonHook*(uuid: UUID): JsonNode =
  ## Converts a UUID to JSON.
  newJString($uuid)

template unsignedSize*(T: typedesc): typedesc =
  when sizeof(T) == 1:
    uint8
  elif sizeof(T) == 2:
    uint16
  elif sizeof(T) == 4:
    uint32
  elif sizeof(T) == 8:
    uint64
  else:
    {.error: "Deserialisation of `" & $T & "` is not implemented!".}
