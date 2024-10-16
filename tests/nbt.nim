import
  std/unittest,
  ../src/ody/nbt,
  ../src/ody/proto


suite "Nbt":
  test "create raw NBT":
    var
      integer = Nbt(kind: NbtType.Int, ival: 64)
      real = Nbt(kind: NbtType.Double, dval: 123.456)

  test "read/write from/into buffer":
    var
      integer = Nbt(kind: NbtType.Int, ival: 64)
      buf = newBuffer()
    
    buf.write(integer)
    assert buf.len == 5
    assert buf.data[0].uint8 == integer.kind.uint8
    # read
    buf.pos = 0
    var readedInteger = buf.readNbt()
    assert readedInteger.kind == integer.kind
    assert readedInteger.ival == integer.ival

  test "basic functions":
    var arr = nbt("test_nbt", {
      "hello": "world",
      "dict": {
        "x": 5
      },
      "data": [1],
      "kkk": [
        0
      ],
      "x": [
        1, 2, 3, 4, 5
      ]
    })
    arr["x"].add(nbt 6)
    arr["x"].add(nbt 7)
    echo arr["hello"]
    echo arr
    assert $arr == "{ 'hello': 'world', 'dict': { 'x': 5, 'dict' }, 'data': @[1], 'kkk': @[0], 'x': @[1, 2, 3, 4, 5, 6, 7], 'test_nbt' }"

    var buf = newBuffer()
    buf.write(arr)
    echo buf.data

    buf.pos = 0
    arr = buf.readNbt(true)
    assert $arr == "{ 'hello': 'world', 'dict': { 'x': 5, 'dict' }, 'data': @[1], 'kkk': @[0], 'x': @[1, 2, 3, 4, 5, 6, 7], 'test_nbt' }"

    echo buf
    arr["strings"] = nbt(["hello", "world"])
    arr["x"].del(2)
    echo arr.pretty()

    var
      x = nbt 10
      y = nbt 5
    
    echo pretty(x + y)
    echo pretty(x * y)
    echo pretty(x * y + 10)

