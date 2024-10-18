
import
  std/osproc,
  std/os,
  ./chunk,
  ./chunk_section,
  ./blocks,
  ../core/constants


type
  MapDataFileHeader* = object
    version*: uint32
    width*: uint64
    height*: uint64
  ChunkDataEntry* = object
    sections*: array[16, ChunkSection]
  MapDataFile* = ref object
    header*: MapDataFileHeader
    chunks*: seq[ChunkDataEntry]
    filePath*: string


template maxChunkIndex*(file: MapDataFile): uint64 =
  file.header.width * file.header.height


proc chunkIndex*(file: MapDataFile, pos: ChunkPosition): int =
  result = pos.x.int64*CHUNK_MAP_WIDTH + pos.z.int64

  if result > file.maxChunkIndex.int:
    raise newException(ValueError, "chunk index is larger than max chunk index")


proc initMapDataFile*(path: string = DEFAULT_GAME_MAP_PATH): MapDataFile =
  result = MapDataFile(
    filePath: path,
    header: MapDataFileHeader(
      version: MAP_DATA_ENGINE_VERSION,
      width: CHUNK_MAP_WIDTH,
      height: CHUNK_MAP_WIDTH
    ),
    chunks: newSeq[ChunkDataEntry](CHUNK_MAP_WIDTH*CHUNK_MAP_WIDTH)
  )
  if fileExists(path):
    var file = open(path, fmRead)

    discard file.readBuffer(addr result.header, sizeof(MapDataFileHeader))
    discard file.readBuffer(addr result.chunks, sizeof(result.chunks))

    file.close()


proc `[]`*(file: MapDataFile, pos: ChunkPosition): Chunk =
  let index = file.chunkIndex(pos)
  if index < 0:
    raise newException(ValueError, "chunk index can't be less than 0")
  
  result = Chunk(pos: pos)
  for i in 0..<16:
    result.sections[i] = file.chunks[index].sections[i]


proc `[]=`*(file: MapDataFile, pos: ChunkPosition, chunk: Chunk) =
  let index = file.chunkIndex(pos)
  if index < 0:
    raise newException(ValueError, "chunk index can't be less than 0")
  
  for i in 0..<16:
    file.chunks[index].sections[i] = chunk.sections[i]
