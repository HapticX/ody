
import
  std/math,
  ./blocks,
  ../proto,
  ../core/constants


type
  ChunkSection* = ref object
    blocks*: array[BLOCKS_COUNT, Block]


template `[]=`*(section: ChunkSection, idx: int, b: Block) =
  section.blocks[idx] = b


template `[]`*(section: ChunkSection, idx: int): untyped =
  section.blocks[idx]


func chunkSectionGetLongsCount*(bitsPerBlock: uint64): int32 =
  let totallyBitsForBlocks = BLOCKS_COUNT * bitsPerBlock
  ceil(totallyBitsForBlocks.int / 64).int32


func chunkSectionSizeInBytes*(bitsPerBlock: uint64): int =
  sizeof(uint16) + sizeof(uint8) + 2 + chunkSectionGetLongsCount(bitsPerBlock) * sizeof(uint64)


func nonAirBlocksCount*(section: ChunkSection): uint16 =
  result = 0
  for b in section.blocks:
    if b.palette > 0:
      inc result


func serialize*(section: ChunkSection, buf: Buffer) =
  buf.writeNum[:uint16](section.nonAirBlocksCount())
  buf.writeNum[:uint8](BITS_PER_BLOCK)

  let longsCount = chunkSectionGetLongsCount(BITS_PER_BLOCK)
  
  buf.writeVar[:int32](longsCount)

  var longs = newSeq[int64](longsCount)

  var b: Block
  for i in 0..<section.blocks.len:
    b = section.blocks[i]
    let
      beginOverlap = (i div BITS_PER_BLOCK) div 64
      off = (i * BITS_PER_BLOCK) mod 64
      endOverlap = ((i+1) * BITS_PER_BLOCK-1) div 64
      identity = b.palette
    
    longs[beginOverlap] = longs[beginOverlap] or (identity shl off).int64
    if beginOverlap != endOverlap:
      longs[endOverlap] = longs[beginOverlap] or (identity shr (64 - off)).int64
  
  for l in longs:
    buf.writeNum[:int64](l)


template blockRelativePositionToIndex*(x, y, z: int): int =
  ((y*16 + z) * 16) + x
