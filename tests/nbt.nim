import
  std/unittest,
  ../src/ody/nbt,
  ../src/ody/proto


suite "Nbt":
  test "create raw NBT":
    var
      integer = Nbt(kind: NbtType.Int, ival: 64)
      real = Nbt(kind: NbtType.Double, dval: 123.456)
  test "write into buffer":
    var
      integer = Nbt(kind: NbtType.Int, ival: 64)
      buf = newBuffer()
    
    buf.write(integer)
    assert buf.len == 5
    assert buf.data[0].uint8 == integer.kind.uint8
