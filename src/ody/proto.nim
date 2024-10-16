## Provides minecraft protocol and buffer realisation
import
  std/asyncdispatch,
  std/asyncnet,
  std/strutils,
  ./core/types,
  ./core/endians

export
  types


const SEGMENT_BITS* = 0x7F
const CONTINUE_BIT* = 0x80


type Buffer* = ref object
  data*: seq[byte]
  pos*: int


proc makeBuffer*(socket: AsyncSocket): Future[Buffer] {.async.} =
  ## Receive all data from socket and write it into buffer
  if not socket.isNil and not socket.isClosed():
    var
      arr = newSeq[byte](4096)
      res = await asyncdispatch.recvInto(socket.getFd().AsyncFD, addr arr[0], 4096, {SocketFlag.SafeDisconn})
    if res != 0:
      return Buffer(data: arr, pos: 0)


func newBuffer*(data: openarray[byte] = newSeq[byte]()): Buffer =
  ## Creates a new buffer
  Buffer(data: @data, pos: 0)


func len*(buf: Buffer): int =
  ## Returns buffer data size
  buf.data.len


func free*(buf: Buffer) =
  buf.pos = 0
  buf.data.setLen(0)


func writeByte*(buf: Buffer, val: byte) =
  ## Writes one byte into buffer and increase position
  buf.data.add(val)
  inc buf.pos


func deposit[T: SomeNumber | bool | char](value: T, oa: var openArray[byte]) {.raises: [ValueError].} =
  if oa.len < sizeof(T):
    raise newException(ValueError, "The buffer was to small to deposit a " & $T & '!')

  let res = cast[unsignedSize(T)](value).toBytesBE()

  for i in 0..<sizeof(T):
    oa[i] = res[i]


func extract*[T: SomeNumber | bool | char](oa: openArray[byte], _: typedesc[T]): T {.raises: [ValueError].} =
  if oa.len < sizeof(T):
    raise newException(ValueError, "The buffer was to small to extract a " & $T & '!')

  elif oa.len > sizeof(T):
    raise newException(ValueError, "The buffer was to big to extract a " & $T & '!')

  cast[T](unsignedSize(T).fromBytesBE(oa.toOpenArray(0, sizeof(T) - 1)))


func writeNum*[T: SomeNumber | bool | char](b: Buffer, value: T) {.raises: [ValueError].} =
  ## Writes any numeric type or boolean to a buffer
  if (b.pos + sizeof(T)) > b.len:
    b.data.setLen(b.pos + sizeof(T))

  deposit(value, b.data.toOpenArray(b.pos, b.pos + sizeof(T) - 1))

  b.pos += sizeof(T)


func writeVar*[T: int32 | int64](b: Buffer, value: T) {.raises: [ValueError].} =
  ## Writes a VarInt or a VarLong to a buffer
  var val = value
  while true:
    if (val and (not SegmentBits)) == 0:
      b.writeNum(cast[uint8](val))
      break
    b.writeNum(cast[uint8]((val and SegmentBits) or ContinueBit))
    val = val shr 7


func writeUUID*(b: Buffer, uuid: UUID) =
  ## Writes a UUID to a buffer
  b.writeNum[:int64](uuid.mostSigBits())
  b.writeNum[:int64](uuid.leastSigBits())


proc writeString*(b: Buffer, s: string) =
  ## Writes a string to a buffer
  b.writeVar[:int32](s.len.int32)
  if (b.pos + s.len) > b.data.len:
    b.data.setLen(b.pos + s.len)

  b.data[b.pos..<(b.pos+s.len)] = cast[seq[byte]](s)
  b.pos += s.len


proc writeStringU16*(b: Buffer, s: string) =
  ## Writes a string to a buffer
  b.writeNum[:uint16](s.len.uint16)
  if (b.pos + s.len) > b.data.len:
    b.data.setLen(b.pos + s.len)

  b.data[b.pos..<(b.pos+s.len)] = cast[seq[byte]](s)
  b.pos += s.len


template writeIdentifier*(b: Buffer, i: Identifier) =
  ## Writes an identifier to a buffer
  b.writeString($i)


template writePosition*(b: Buffer, p: Position, format = XZY) =
  ## Writes a Position to a buffer using the specified encoding format
  s.writeNum[:int64](toPos(p, format))



func readByte*(buf: Buffer): byte =
  ## Reads one byte from buffer and increase position
  result = buf.data[buf.pos]
  inc buf.pos


func readNum*[T: SomeNumber | bool | char](b: Buffer): T {.raises: [ValueError].} =
  ## Reads any numeric type or boolean from a buffer
  if (b.pos + sizeof(T)) > b.data.len:
    raise newException(ValueError, "Reached the end of the buffer while trying to read a " & $T & '!')

  result = b.data.toOpenArray(b.pos, b.pos + sizeof(T) - 1).extract(T)

  b.pos += sizeof(T)


func readVar*[T: int32 | int64](b: Buffer): T {.raises: [ValueError].} =
  ## Reads a VarInt or a VarLong from a buffer
  var
    position: int8 = 0
    currentByte: int8

  while true:
    currentByte = b.readNum[:int8]()
    result = result or ((currentByte.T and SegmentBits) shl position)

    if (currentByte and ContinueBit) == 0:
      break

    position += 7

    when T is int32:
      if position >= 32:
        raise newException(ValueError, "VarInt is too big!")

    elif T is int64:
      if position >= 64:
        raise newException(ValueError, "VarLong is too big!")

    else:
      {.error: "Deserialisation of `" & $T & "` is not implemented!".}


func readStr*(b: Buffer, maxLength = 32767): string {.raises: [ValueError].} =
  ## Reads a string from a buffer
  let length = b.readVar[:int32]()

  if length > maxLength * 3:
    raise newException(ValueError, "String is too long!")

  result.setLen(length)

  let data = b.data[b.pos..<(b.pos+length)]
  result = cast[string](data)

  if result.len > maxLength:
    raise newException(ValueError, "String is too long!")

  b.pos += length


func readStrU16*(b: Buffer, maxLength = 32767): string {.raises: [ValueError].} =
  ## Reads a string from a buffer
  let length = b.readNum[:uint16]()

  result.setLen(length)

  let data = b.data[b.pos..<(b.pos+length.int)]
  result = cast[string](data)

  if result.len > maxLength:
    raise newException(ValueError, "String is too long!")

  b.pos += length.int


func readUUID*(buf: Buffer): UUID =
  initUUID(buf.readVar[:int64](), buf.readVar[:int64]())


func readIdentifier*(buf: Buffer): Identifier =
  let str = buf.readStr().split(':')
  Identifier(namespace: str[0], value: str[1])


func `$`*(buf: Buffer): string =
  result = ""
  for i in buf.data:
    result &= "0x" & $(i.toHex()) & " "
