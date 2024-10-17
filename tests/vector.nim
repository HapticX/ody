import
  std/unittest,
  ../src/ody/core/types,
  ../src/ody/core/vector


suite "Working with vectors":
  test "basic operations":
    let
      a = initVector(1, 2, 3)
      b = initVector(10, 5, 0)
    
    assert a.dotProduct(b) == 20.0
    echo a.len()
    echo a.normalized()

    echo a.angleBetween(b)

    assert a + b == initVector(11, 7, 3)
    assert b > a
    assert a <= b
