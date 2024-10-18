import
  ./blocks,
  ./chunk_section,
  ../proto,
  ../nbt,
  ../core/constants


type
  ChunkPosition* = object
    x*, z*: int32
  ChunkChanged* = proc(chunk: Chunk, b: Block)
  Chunk* = object
    pos*: ChunkPosition
    sections*: array[16, ChunkSection]
    onChanged*: ChunkChanged


template `[]=`*(chunk: Chunk, idx: int, b: ChunkSection) =
  chunk.sections[idx] = b


template `[]`*(chunk: Chunk, idx: int): untyped =
  chunk.sections[idx]


proc serialize*(chunk: Chunk, buf: Buffer) =
  var motionBlocks = NbtType.LongArray.create(newSeq[int64](), true, "MOTION_BLOCKS")

  for i in 0..<36:
    motionBlocks.add 0'i64
  
  var testHeightMap = NbtType.Compound.create(@[motionBlocks])

  buf.writeNum[:int32](chunk.pos.x)
  buf.writeNum[:int32](chunk.pos.z)
  buf.writeBool(true)

  buf.writeVar[:int32](0b1111111111111111)

  buf.write(testHeightMap)

  buf.writeVar[:int32](
    int32(chunkSectionSizeInBytes(BITS_PER_BLOCK) * chunk.sections.len + 256 * sizeof(uint32))
  )

  for section in chunk.sections:
    section.serialize(buf)
  
  # no block entities on chunk synchronization
  buf.writeVar[:int32](0)

  # TODO: Biome data
  for i in 0..<256:
    buf.writeNum[:int32](0)


proc `[]=`*(chunk: Chunk, x, y, z: int, b: Block) =
  if y >= 256:
    return

  let section = chunk.sections[y div 16]
  let blockIdx = blockRelativePositionToIndex(x, y, z)
  section[blockIdx] = b

  if not chunk.onChanged.isNil:
    chunk.onChanged(chunk, b)


proc `[]`*(chunk: Chunk, x, y, z: int): Block =
  if y >= 256:
    return AIR_BLOCK

  let section = chunk.sections[y div 16]
  section[blockRelativePositionToIndex(x, y, z)]


proc entitiesInside*(chunk: Chunk): seq[int] =
  discard
