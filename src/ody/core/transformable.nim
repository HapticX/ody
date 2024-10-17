
import
  ./types,
  ../utils


export
  types


const
  TF_X* = 0x01
  TF_Y* = 0x02
  TF_Z* = 0x04
  TF_Y_ROT* = 0x08
  TF_X_ROT* = 0x10


proc acquirePosition*(t: Transformable, pos: Vector) =
  if pos.x != 0:
    t.transformationFlags.setBit(TF_X)
  if pos.y != 0:
    t.transformationFlags.setBit(TF_Y)
  if pos.z != 0:
    t.transformationFlags.setBit(TF_Z)


proc acquireRotation*(t: Transformable, angle: Angle) =
  if angle.pitch != 0:
    t.transformationFlags.setBit(TF_X_ROT)
  if angle.yaw != 0:
    t.transformationFlags.setBit(TF_Y_ROT)


proc setRotation*(t: Transformable, pitch, yaw: float) =
  t.rotation.pitch = pitch
  t.rotation.yaw = yaw

  t.acquireRotation(Angle(pitch: pitch, yaw: yaw))


proc setPosition*(t: Transformable, x, y, z: float) =
  t.position.x = x
  t.position.y = y
  t.position.z = z

  t.acquirePosition(Vector(x: x, y: y, z: z))


proc rotate*(t: Transformable, pitch, yaw: float) =
  t.setRotation(t.rotation.pitch + pitch, t.rotation.yaw + yaw)


proc move*(t: Transformable, x, y, z: float) =
  t.setPosition(t.position.x + x, t.position.y + y, t.position.z + z)


proc apply*(t: Transformable): uint8 =
  result = t.transformationFlags
  t.transformationFlags = 0'u8
