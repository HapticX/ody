import
  std/math,
  ./types


export
  math


func initVector*(x, y, z: float): Vector =
  ## Initializes a 3D vector with the given coordinates `x`, `y`, `z`.
  Vector(x: x, y: y, z: z)


template initVector*(): Vector =
  ## Initializes a 3D vector with default coordinates (0, 0, 0).
  initVector(0.0, 0.0, 0.0)


template dotProduct*(a, b: Vector): untyped {.dirty.} =
  ## Calculates the dot product between two vectors `a` and `b`.
  a.x*b.x + a.y*b.y + a.z*b.z


template len*(a: Vector): untyped {.dirty.} =
  ## Returns the length (magnitude) of vector `a`.
  sqrt(a.dotProduct(a))


func normalized*(a: Vector): Vector =
  ## Returns the normalized (unit) vector of `a`.
  let length = a.len
  Vector(x: a.x / length, y: a.y / length, z: a.z / length)


template `==`*(a, b: Vector): untyped {.dirty.} =
  ## Compares two vectors `a` and `b` for equality.
  a.x == b.x and a.y == b.y and a.z == b.z


template `!=`*(a, b: Vector): untyped {.dirty.} =
  ## Compares two vectors `a` and `b` for inquality.
  a.x != b.x and a.y != b.y and a.z != b.z


template `>`*(a, b: Vector): untyped {.dirty.} =
  ## Compares two vectors based on their length.
  ## Returns true if vector `a` is longer than vector `b`.
  a.len > b.len


template `<`*(a, b: Vector): untyped {.dirty.} =
  ## Compares two vectors based on their length.
  ## Returns true if vector `a` is shorter than vector `b`.
  a.len < b.len


template `>=`*(a, b: Vector): untyped {.dirty.} =
  ## Compares two vectors based on their length.
  ## Returns true if vector `a` is longer than or equal to vector `b`.
  a.len >= b.len


template `<=`*(a, b: Vector): untyped {.dirty.} =
  ## Compares two vectors based on their length.
  ## Returns true if vector `a` is shorter than or equal to vector `b`.
  a.len <= b.len


template `+`*(a, b: Vector): untyped {.dirty.} =
  ## Adds two vectors `a` and `b`.
  Vector(x: a.x + b.x, y: a.y + b.y, z: a.z + b.z)


template `-`*(a, b: Vector): untyped {.dirty.} =
  ## Subtracts vector `b` from vector `a`.
  Vector(x: a.x - b.x, y: a.y - b.y, z: a.z - b.z)


template `*`*(a, b: Vector): untyped {.dirty.} =
  ## Multiplies two vectors `a` and `b` element-wise.
  Vector(x: a.x * b.x, y: a.y * b.y, z: a.z * b.z)


template `/`*(a, b: Vector): untyped {.dirty.} =
  ## Divides vector `a` by vector `b` element-wise.
  Vector(x: a.x / b.x, y: a.y / b.y, z: a.z / b.z)


template distance*(a, b: Vector): untyped {.dirty.} =
  ## Computes the distance between two vectors `a` and `b`.
  (a - b).len


template angleBetween*(a, b: Vector): untyped {.dirty.} =
  ## Computes the angle between two vectors `a` and `b` in radians.
  arccos(a.normalized().dotProduct(b.normalized()))
