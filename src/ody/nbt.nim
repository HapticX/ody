## Provides working with NBTs

import
  ./proto


type
  NbtType* {.pure, size: sizeof(uint8).} = enum
    End,
    Byte,
    Short,
    Int,
    Long,
    Float,
    Double,
    ByteArray,
    String,
    List,
    Compound,
    IntArray,
    LongArray
  Nbt* = ref object
    hasName*: bool
    name*: string
    case kind*: NbtType
    of End:
      discard
    of Byte:
      bval*: byte
    of Short:
      sval*: int16
    of Int:
      ival*: int32
    of Long:
      lval*: int64
    of Float:
      fval*: float32
    of Double:
      dval*: float64
    of ByteArray:
      barr*: seq[byte]
    of String:
      str*: string
    of List:
      arr*: seq[Nbt]
    of Compound:
      carr*: seq[Nbt]
    of IntArray:
      iarr*: seq[int32]
    of LongArray:
      larr*: seq[int64]


proc write*(buf: Buffer, nbt: Nbt) =
  ## Writes NBT Tag into Buffer
  buf.writeNum[:uint8](nbt.kind.uint8)

  if nbt.hasName:
    buf.writeStringU16(nbt.name)
  
  case nbt.kind
  of End:
    discard
  of Byte:
    buf.writeByte(nbt.bval)
  of Short:
    buf.writeNum[:int16](nbt.sval)
  of Int:
    buf.writeNum[:int32](nbt.ival)
  of Long:
    buf.writeNum[:int64](nbt.lval)
  of Float:
    buf.writeNum[:float32](nbt.fval)
  of Double:
    buf.writeNum[:float64](nbt.dval)
  of ByteArray:
    for bval in nbt.barr:
      buf.writeByte(bval)
  of String:
    buf.writeStringU16(nbt.str)
  of List:
    buf.writeNum[:int32](nbt.arr.len.int32)
    for n in nbt.arr:
      n.hasName = false
      buf.write(n)
  of Compound:
    for n in nbt.carr:
      buf.write(n)
    buf.writeNum[:int8](0x00)  # tag End
  of IntArray:
    buf.writeNum[:int32](nbt.iarr.len.int32)
    for i in nbt.iarr:
      buf.writeNum[:int32](i)
  of LongArray:
    buf.writeNum[:int32](nbt.larr.len.int32)
    for l in nbt.larr:
      buf.writeNum[:int64](l)

