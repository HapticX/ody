import
  std/tables,
  ./chunk,
  ./chunk_section,
  ./blocks,
  ./map_data_file,
  ../core/constants


type
  ChunkMap* = TableRef[int64, Chunk]
  ChunkManager* = object
    map*: ChunkMap


func chunkMap*(): ChunkMap =
  ChunkMap(newTable[int64, Chunk]())


template chunkId*(pos: ChunkPosition): int64 =
  pos.x.int64*CHUNK_MAP_WIDTH + pos.z.int64


template `[]`*(manager: ChunkManager, pos: ChunkPosition): int64 =
  manager.map[chunkId(pos)]


func disposeChunk*(manager: ChunkManager, pos: ChunkPosition) =
  manager.map.del(chunkId(pos))


proc loadChunkFromDisk*(manager: ChunkManager, pos: ChunkPosition, file: MapDataFile) =
  manager.map[chunkId(pos)] = file[pos]
