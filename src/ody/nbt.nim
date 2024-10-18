## This module provides functionality for working with Named Binary Tags (NBT) data format, 
## commonly used in Minecraft to store structured data. It allows reading, writing, and 
## manipulating NBTs in various formats, such as integers, strings, arrays, and compound objects.

import
  std/macros,
  std/strformat,
  std/strutils,
  std/typetraits,
  std/json,
  ./proto


export
  typetraits


type
  NbtType* {.pure, size: sizeof(uint8).} = enum
    End  ## Represents the end of a compound or list in NBT format (tag 0x00).
    Byte  ## A single signed byte (tag 0x01).
    Short  ## A signed short (16-bit integer, tag 0x02).
    Int  ## A signed integer (32-bit, tag 0x03).
    Long  ## A signed long (64-bit integer, tag 0x04).
    Float  ## A 32-bit floating point number (tag 0x05).
    Double  ## A 64-bit floating point number (tag 0x06).
    ByteArray  ## A sequence of bytes (tag 0x07).
    String  ## A UTF-8 string (tag 0x08).
    List  ## A list of other NBT elements (tag 0x09).
    Compound  ## A compound structure, essentially a key-value map of NBT elements (tag 0x0a).
    IntArray  ## An array of signed integers (tag 0x0b).
    LongArray  ## An array of signed long integers (tag 0x0c).
  Nbt* = ref object  ## The Nbt type represents an NBT tag, which can hold various data types based on its kind.
    hasName*: bool
    name*: string
    case kind*: NbtType
    of End: discard
    of Byte: bval*: byte
    of Short: sval*: int16
    of Int: ival*: int32
    of Long: lval*: int64
    of Float: fval*: float32
    of Double: dval*: float64
    of ByteArray: barr*: seq[byte]
    of String: str*: string
    of List: arr*: seq[Nbt]
    of Compound: carr*: seq[Nbt]
    of IntArray: iarr*: seq[int32]
    of LongArray: larr*: seq[int64]
  
  ## NbtTypes is a shorthand alias for all the types that can be used in NBT tags.
  NbtTypes* = byte | int16 | int32 | int64 | float32 | float64 | seq[byte] | string | seq[Nbt] | seq[int32] | seq[int64]


proc `$`*(this: Nbt): string =
  ## Converts an NBT object into a string representation.
  let name =
    if this.hasName:
      ", '" & this.name & "'"
    else:
      ""
  result =
    case this.kind
    of End: "NbtEnd"
    of Byte: fmt"byte({this.bval})"
    of Short: fmt"short({this.sval})"
    of Int: fmt"{this.ival}"
    of Long: fmt"long({this.lval})"
    of Float: fmt"{this.fval}"
    of Double: fmt"double({this.dval})"
    of ByteArray: fmt"ByteArray{this.barr}"
    of String: fmt"'{this.str}'"
    of List: fmt"{this.arr}"
    of Compound:
      var val = "{ "
      for i in 0..<this.carr.len:
        if i == this.carr.len-1:
          val &= fmt"'{this.carr[i].name}': {this.carr[i]}"
        else:
          val &= fmt"'{this.carr[i].name}': {this.carr[i]}, "
      val &= fmt"{name} }}"
      val
    of IntArray: fmt"IntArray{this.iarr}"
    of LongArray: fmt"LongArray{this.larr}"


func pretty*(nbt: Nbt, lvl: int = 0): string =
  ## Generates a pretty-printed string of an NBT object with indentation based on the level.
  let name =
    if nbt.hasName:
      fmt"'{nbt.name}'"
    else:
      "None"
  let space = "  ".repeat(lvl)
  case nbt.kind
  of NbtType.End: fmt"{space}TAG_End({name})"
  of NbtType.Byte: fmt"{space}TAG_Byte({name}): {nbt.bval.toHex()}"
  of NbtType.Short: fmt"{space}TAG_Short({name}): {nbt.sval}"
  of NbtType.Int: fmt"{space}TAG_Int({name}): {nbt.ival}"
  of NbtType.Long: fmt"{space}TAG_Long({name}): {nbt.lval}"
  of NbtType.Float: fmt"{space}TAG_Float({name}): {nbt.fval}"
  of NbtType.Double: fmt"{space}TAG_Double({name}): {nbt.dval}"
  of NbtType.ByteArray:
    var strings: seq[string] = @[]
    for i in nbt.barr:
      strings.add(i.toHex())
    fmt"""{space}TAG_ByteArray({name}): [{strings.join(" ")}]"""
  of NbtType.String: fmt"{space}TAG_String({name}): '{nbt.str}'"
  of NbtType.List:
    var res =
      if nbt.arr.len > 0:
        fmt"{space}TAG_List({name}, {nbt.arr[0].kind}): {nbt.arr.len} entries"
      else:
        fmt"{space}TAG_List({name}, End): 0 entries"
    if nbt.arr.len > 0:
      res &= "\n" & space & "{\n"
      for i in 0..<nbt.arr.len:
        res &= nbt.arr[i].pretty(lvl+1)
        if i < nbt.arr.len-1:
          res &= "\n"
      res &= "\n" & space & "}"
    res
  of NbtType.Compound:
    var res =
      if nbt.carr.len > 0:
        fmt"{space}TAG_Compund({name}): {nbt.carr.len} entries"
      else:
        fmt"{space}TAG_Compund({name}): 0 entries"
    if nbt.carr.len > 0:
      res &= "\n" & space & "{\n"
      for i in 0..<nbt.carr.len:
        res &= nbt.carr[i].pretty(lvl+1)
        if i < nbt.carr.len-1:
          res &= "\n"
      res &= "\n" & space & "}"
    res
  of NbtType.IntArray:
    fmt"""{space}TAG_IntArray({name}): [{nbt.iarr.join(", ")}]"""
  of NbtType.LongArray:
    fmt"""{space}TAG_LongArray({name}): [{nbt.iarr.join(", ")}]"""


proc create*[T: NbtTypes](nbtType: NbtType, value: T, hasName: bool = false, name: string = ""): Nbt =
  ## Creates a new NBT tag of the specified type and assigns a value to it.
  result = Nbt(kind: nbtType, hasName: hasName, name: name)

  case nbtType
  of End: discard
  of Byte:
    when value is byte:
      result.bval = value
    else:
      raise newException(ValueError, "value should be byte")
  of Short:
    when value is int16:
      result.sval = value
    else:
      raise newException(ValueError, "value should be int16")
  of Int:
    when value is int32:
      result.ival = value
    else:
      raise newException(ValueError, "value should be int32")
  of Long:
    when value is int64:
      result.lval = value
    else:
      raise newException(ValueError, "value should be int64")
  of Float:
    when value is float32:
      result.fval = value
    else:
      raise newException(ValueError, "value should be float32")
  of Double:
    when value is float64:
      result.dval = value
    else:
      raise newException(ValueError, "value should be float64")
  of ByteArray:
    when value is seq[byte]:
      result.barr = value
    else:
      raise newException(ValueError, "value should be seq[byte]")
  of String:
    when value is string:
      result.str = value
    else:
      raise newException(ValueError, "value should be string")
  of List:
    when value is seq[Nbt]:
      result.arr = value
    else:
      raise newException(ValueError, "value should be seq[Nbt]")
  of Compound:
    when value is seq[Nbt]:
      result.carr = value
    else:
      raise newException(ValueError, "value should be seq[Nbt]")
  of IntArray:
    when value is seq[int32]:
      result.iarr = value
    else:
      raise newException(ValueError, "value should be seq[int32]")
  of LongArray:
    when value is seq[int64]:
      result.larr = value
    else:
      raise newException(ValueError, "value should be seq[int64]")


# ---=== I/O Operations ===--- #


proc write*(buf: Buffer, nbt: Nbt) =
  ## Writes an NBT tag to the provided buffer.
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
    buf.writeNum[:int32](nbt.arr.len.int32)
    for bval in nbt.barr:
      buf.writeByte(bval)
  of String:
    buf.writeStringU16(nbt.str)
  of List:
    if nbt.arr.len == 0:
      buf.writeNum[:uint8](0x00)  # End
    else:
      buf.writeNum[:uint8](nbt.arr[0].kind.uint8)
    buf.writeNum[:int32](nbt.arr.len.int32)
    for n in nbt.arr:
      n.hasName = false
      n.name = ""
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


proc readNbt*(buf: Buffer, hasNbtName: bool = false): Nbt =
  ## Reads an NBT tag from the buffer, with an optional flag for handling named tags.
  result = Nbt(kind: NbtType(buf.readNum[:uint8]()), hasName: hasNbtName)

  if hasNbtName:
    result.name = buf.readStrU16()
  
  case result.kind
  of End:
    discard
  of Byte:
    result.bval = buf.readByte()
  of Short:
    result.sval = buf.readNum[:int16]()
  of Int:
    result.ival = buf.readNum[:int32]()
  of Long:
    result.lval = buf.readNum[:int64]()
  of Float:
    result.fval = buf.readNum[:float32]()
  of Double:
    result.dval = buf.readNum[:float64]()
  of ByteArray:
    result.barr = newSeq[byte](buf.readNum[:int32]())
    for i in 0..<result.barr.len:
      result.barr[i] = buf.readByte()
  of String:
    result.str = buf.readStrU16()
  of List:
    let typeOfElement = NbtType(buf.readNum[:int8]())
    result.arr = newSeq[Nbt](buf.readNum[:int32]())
    for i in 0..<result.arr.len:
      result.arr[i] = buf.readNbt(false)
  of Compound:
    result.carr = @[]
    while true:
      result.carr.add(buf.readNbt(true))
      if buf.readNum[:int8]() == 0x00: # tag End
        break
      dec buf.pos
  of IntArray:
    result.iarr = newSeq[int32](buf.readNum[:int32]())
    for i in 0..<result.iarr.len:
      result.iarr[i] = buf.readNum[:int32]()
  of LongArray:
    result.larr = newSeq[int64](buf.readNum[:int32]())
    for i in 0..<result.larr.len:
      result.larr[i] = buf.readNum[:int64]()


# ---=== Operators ===--- #


proc equals*(this, other: Nbt): bool =
  if this.kind != other.kind:
    return false

  if this.hasName != other.hasName:
    return false

  if this.hasName and this.name != other.name:
    return false
  
  case this.kind
  of End:
    return true
  of Byte:
    return this.bval == other.bval
  of Short:
    return this.sval == other.sval
  of Int:
    return this.ival == other.ival
  of Long:
    return this.lval == other.lval
  of Float:
    return this.fval == other.fval
  of Double:
    return this.dval == other.dval
  of ByteArray:
    return this.barr == other.barr
  of String:
    return this.str == other.str
  of List:
    return this.arr == other.arr
  of Compound:
    return this.carr == other.carr
  of IntArray:
    return this.iarr == other.iarr
  of LongArray:
    return this.larr == other.larr


proc `&`*(this, other: Nbt): Nbt =
  ## Adds `other` to `this`.
  ## Creates a new NBT Tag.
  if this.kind != other.kind:
    raise newException(ValueError, fmt"Can't add {other.kind} to {this.kind}")

  case this.kind
  of String:
    return NbtType.String.create(this.str & other.str)
  of List:
    return NbtType.List.create(this.arr & other.arr)
  of ByteArray:
    return NbtType.List.create(this.barr & other.barr)
  of IntArray:
    return NbtType.List.create(this.iarr & other.iarr)
  of LongArray:
    return NbtType.List.create(this.larr & other.larr)
  else:
    raise newException(ValueError, fmt"Can't add {other.kind} to {this.kind}")


template numberOperator(op, w: untyped): untyped {.dirty.} =
  ## Provides number operations
  proc `op`*(this: Nbt, other: Nbt | int64 | int32 | int16 | float32 | float64): Nbt =
    ## Creates a new NBT Tag.
    const word = w
    when other is Nbt:
      if this.kind != other.kind:
        raise newException(ValueError, fmt"Can't {word} {other.kind} and {this.kind}")

    case this.kind
    of Short:
      when other is Nbt:
        return NbtType.Short.create(`op`(this.sval, other.sval))
      elif other is int16:
        return NbtType.Short.create(`op`(this.sval, other))
      else:
        raise newException(ValueError, fmt"Can't {word} {this.kind} and {name(typeof(other))}")
    of Int:
      when other is Nbt:
        return NbtType.Int.create(`op`(this.ival, other.ival))
      elif other is int32 or other is int:
        return NbtType.Int.create(`op`(this.ival, other.int32))
      else:
        raise newException(ValueError, fmt"Can't {word} {this.kind} and {name(typeof(other))}")
    of Long:
      when other is Nbt:
        return NbtType.Long.create(`op`(this.lval, other.lval))
      elif other is int64:
        return NbtType.Long.create(`op`(this.lval, other))
      else:
        raise newException(ValueError, fmt"Can't {word} {this.kind} and {name(typeof(other))}")
    of Float:
      when other is Nbt:
        return NbtType.Float.create(`op`(this.fval, other.fval))
      elif other is float32:
        return NbtType.Float.create(`op`(this.fval, other))
      else:
        raise newException(ValueError, fmt"Can't {word} {this.kind} and {name(typeof(other))}")
    of Double:
      when other is Nbt:
        return NbtType.Double.create(`op`(this.dval, other.dval))
      elif other is float64 or other is float:
        return NbtType.Double.create(`op`(this.dval, other.float64))
      else:
        raise newException(ValueError, fmt"Can't {word} {this.kind} and {name(typeof(other))}")
    else:
      when other is Nbt:
        raise newException(ValueError, fmt"Can't {word} {this.kind} and {other.kind}")
      else:
        raise newException(ValueError, fmt"Can't {word} {this.kind} and {name(typeof(other))}")


numberOperator(`+`, "add")
numberOperator(`-`, "substract")
numberOperator(`*`, "multiply")
numberOperator(`/`, "divide")


func `==`*(this, other: Nbt): bool =
  ## Compares two NBT objects for equality.
  return this.equals(other)

func `!=`*(this, other: Nbt): bool =
  ## Compares two NBT objects for inequality.
  return not (this == other)

func `&=`*(this: var Nbt, other: Nbt) =
  this = this & other

func `+=`*(this: var Nbt, other: Nbt) =
  ## Adds two NBT objects and assigns the result to the first one.
  this = this + other

func `-=`*(this: var Nbt, other: Nbt) =
  ## Subtracts one NBT object from another and assigns the result.
  this = this - other

func `*=`*(this: var Nbt, other: Nbt) =
  ## Multiplies two NBT objects and assigns the result to the first one.
  this = this * other

func `/=`*(this: var Nbt, other: Nbt) =
  ## Divides the first NBT object by the second and assigns the result.
  this = this / other


func `[]`*(nbt: Nbt, key: int | string): Nbt | byte | int32 | int64 =
  ## Retrieves a value by index or key from an NBT tag.
  ## For `Compound` tags, retrieves by string key; for array types, retrieves by integer index.
  when key is string:
    if nbt.kind != NbtType.Compound:
      raise newException(KeyError, "nbt " & $nbt.kind & " isn't Compound")
    for n in nbt.carr:
      if n.name == key:
        return n
  else:
    case nbt.kind
    of NbtType.ByteArray:
      return nbt.barr[key]
    of NbtType.IntArray:
      return nbt.iarr[key]
    of NbtType.LongArray:
      return nbt.larr[key]
    of NbtType.List:
      return nbt.arr[key]
    else:
      raise newException(KeyError, "nbt " & $nbt.kind & " isn't iterable")


func `[]=`*[T: Nbt | byte | int32 | int64](nbt: Nbt, key: int | string, value: T) =
  ## Sets a value by index or key in an NBT tag.
  ## For `Compound` tags, sets by string key; for array types, sets by integer index.
  when key is string:
    if nbt.kind != NbtType.Compound:
      raise newException(KeyError, "nbt " & $nbt.kind & " isn't Compound")
    if value is not Nbt:
      raise newException(ValueError, "you can set only NBT for Compound tag")
    value.hasName = true
    value.name = key
    for i in 0..<nbt.carr.len:
      if nbt.carr[i].name == key:
        nbt.carr[i] = value
        return
    nbt.carr.add(value)
  else:
    case nbt.kind
    of NbtType.ByteArray:
      if value is not byte:
        raise newException(ValueError, "you can set only byte for ByteArray tag")
      if nbt.barr.len <= key:
        raise newException(KeyError, fmt"index {key} is not in 0..<{nbt.arr.len}")
      nbt.barr[key] = value
    of NbtType.IntArray:
      if value is not int32:
        raise newException(ValueError, "you can set only int32 for IntArray tag")
      if nbt.iarr.len <= key:
        raise newException(KeyError, fmt"index {key} is not in 0..<{nbt.arr.len}")
      nbt.iarr[key] = value
    of NbtType.LongArray:
      if value is not int64:
        raise newException(ValueError, "you can set only int64 for LongArray tag")
      if nbt.larr.len <= key:
        raise newException(KeyError, fmt"index {key} is not in 0..<{nbt.arr.len}")
      nbt.larr[key] = value
    of NbtType.List:
      if value is not Nbt:
        raise newException(ValueError, "you can set only Nbt for List tag")
      if nbt.arr.len <= key:
        raise newException(KeyError, fmt"index {key} is not in 0..<{nbt.arr.len}")
      if nbt.arr[0].kind != value.kind:
        raise newException(ValueError, fmt"value type should be {nbt.arr[0].kind}")
      nbt.arr[key] = value
    else:
      raise newException(KeyError, fmt"nbt {nbt.kind} isn't iterable")


# ---=== Functions ===--- #


func add*(nbt: Nbt, value: Nbt | byte | int32 | int64) =
  ## Adds `value` into `nbt` if the tag supports addition.
  ## Applicable to `ByteArray`, `IntArray`, `LongArray`, and `List` NBT types.
  case nbt.kind
  of NbtType.ByteArray:
    if value is not byte:
      raise newException(ValueError, "you can set only byte for ByteArray tag")
    when value is byte:
      nbt.barr.add value
  of NbtType.IntArray:
    if value is not int32:
      raise newException(ValueError, "you can set only int32 for IntArray tag")
    when value is int32:
      nbt.iarr.add value
  of NbtType.LongArray:
    if value is not int64:
      raise newException(ValueError, "you can set only int64 for LongArray tag")
    when value is int64:
      nbt.larr.add value
  of NbtType.List:
    if value is not Nbt:
      raise newException(ValueError, "you can set only Nbt for List tag")
    when value is Nbt:
      if nbt.arr.len > 0 and nbt.arr[0].kind != value.kind:
        raise newException(ValueError, fmt"value type should be {nbt.arr[0].kind}")
      nbt.arr.add value
  else:
    raise newException(KeyError, fmt"nbt {nbt.kind} isn't iterable")


func clear*(nbt: Nbt) =
  ## Removes all elements from array-like NBT tags (`ByteArray`, `IntArray`, `LongArray`, `List`, `Compound`).
  case nbt.kind
  of NbtType.ByteArray:
    nbt.barr.setLen(0)
  of NbtType.IntArray:
    nbt.iarr.setLen(0)
  of NbtType.LongArray:
    nbt.larr.setLen(0)
  of NbtType.List:
    nbt.arr.setLen(0)
  of NbtType.Compound:
    nbt.carr.setLen(0)
  else:
    raise newException(KeyError, fmt"nbt {nbt.kind} isn't iterable")


func del*(nbt: Nbt, key: string | int) =
  ## Deletes an element by `key` (either `string` for `Compound` tags or `int` for array-like tags) from the NBT in O(1).
  when key is string:
    if nbt.kind != NbtType.Compound:
      raise newException(ValueError, fmt"Can't delete item at {key} from NBT of type {nbt.kind}")
    
    for i in 0..<nbt.carr.len:
      if nbt.carr[i].name == key:
        nbt.carr.del(i)
        break
  else:
    case nbt.kind
    of NbtType.ByteArray:
      nbt.barr.del(key)
    of NbtType.IntArray:
      nbt.iarr.del(key)
    of NbtType.LongArray:
      nbt.larr.del(key)
    of NbtType.List:
      nbt.arr.del(key)
    else:
      raise newException(KeyError, fmt"nbt {nbt.kind} isn't iterable")


func delete*(nbt: Nbt, key: string | int) =
  ## An alternative to `del*`, removes an entry by `key` from the NBT in O(n), handling `Compound` or array-like tags.
  when key is string:
    if nbt.kind != NbtType.Compound:
      raise newException(ValueError, fmt"Can't delete item at {key} from NBT of type {nbt.kind}")
    
    for i in 0..<nbt.carr.len:
      if nbt.carr[i].name == key:
        nbt.carr.delete(i)
        break
  else:
    case nbt.kind
    of NbtType.ByteArray:
      nbt.barr.delete(key)
    of NbtType.IntArray:
      nbt.iarr.delete(key)
    of NbtType.LongArray:
      nbt.larr.delete(key)
    of NbtType.List:
      nbt.arr.delete(key)
    else:
      raise newException(KeyError, fmt"nbt {nbt.kind} isn't iterable")


iterator items*(nbt: Nbt): Nbt =
  ## Iterates over entries in a `List` or `Compound` NBT tag.
  case nbt.kind
  of NbtType.List:
    for item in nbt.arr:
      yield item
  of NbtType.Compound:
    for item in nbt.carr:
      yield item
  else:
    raise newException(ValueError, $nbt.kind & " isn't Nbt iterable")


iterator bytes*(nbt: Nbt): byte =
  ## Iterates over elements of a `ByteArray` NBT tag.
  case nbt.kind
  of NbtType.ByteArray:
    for item in nbt.barr:
      yield item
  else:
    raise newException(ValueError, $nbt.kind & " isn't ByteArray")


# ---=== Compile-Time syntax sugar ===--- #


proc makeNbt(node: NimNode): NimNode {.compileTime.} =
  ## Builds nbt tag creation at compile time
  case node.kind
  of nnkInt8Lit:
    return newCall("create", newDotExpr(ident"NbtType", ident"Byte"), newLit(node.intVal.int8))
  of nnkInt16Lit:
    return newCall("create", newDotExpr(ident"NbtType", ident"Short"), node)
  of nnkInt32Lit:
    return newCall("create", newDotExpr(ident"NbtType", ident"Int"), node)
  of nnkIntLit:
    return newCall("create", newDotExpr(ident"NbtType", ident"Int"), newLit(node.intVal.int32))
  of nnkInt64Lit:
    return newCall("create", newDotExpr(ident"NbtType", ident"Long"), node)
  of nnkFloat32Lit:
    return newCall("create", newDotExpr(ident"NbtType", ident"Float"), node)
  of nnkFloat64Lit:
    return newCall("create", newDotExpr(ident"NbtType", ident"Double"), node)
  of nnkFloatLit:
    return newCall("create", newDotExpr(ident"NbtType", ident"Double"), newLit(node.floatVal.float64))
  of nnkStrLit, nnkTripleStrLit:
    return newCall("create", newDotExpr(ident"NbtType", ident"String"), node)
  of nnkBracket:
    let
      res = newCall("create", newDotExpr(ident"NbtType", ident"List"), newCall("@"))
      arr = newNimNode(nnkBracket)
    for i in node.children:
      arr.add(i.makeNbt())
      arr[^1].add(newLit(false))
    if arr.len > 0:
      res[^1].add(arr)
    else:
      res[^1] = newCall(newNimNode(nnkBracketExpr).add(ident"newSeq", ident"Nbt"))
    return res
  of nnkTableConstr:
    let
      res = newCall("create", newDotExpr(ident"NbtType", ident"Compound"), newCall("@"))
      arr = newNimNode(nnkBracket)
    for i in node.children:
      let call = i[1].makeNbt()
      call.add(newLit(true), i[0])
      arr.add(call)
    res[^1].add(arr)
    return res
  of nnkCurly:
    return newCall(
      "create",
      newDotExpr(ident"NbtType", ident"Compound"),
      newCall(newNimNode(nnkBracketExpr).add(ident"newSeq", ident"Nbt"))
    )
  else:
    return node


macro `@$`*(body: untyped): untyped =
  ## Makes NBT creating easily
  result = makeNbt(body)


macro nbt*(body: untyped): untyped =
  ## Makes NBT creating easily
  result = makeNbt(body)


macro nbt*(name: static[string], body: untyped): untyped =
  ## Makes NBT creating easily
  result = makeNbt(body)
  result.add(newLit(true), newLit(name))
