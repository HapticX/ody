
import
  ./blocks,
  ./chunk,
  ./chunk_section,
  ./chunk_manager,
  ./map_data_file,
  ../core/constants


type
  MapManager* = object
    file*: MapDataFile
    chunkManager*: ChunkManager


proc initGameMap*(path: string = DEFAULT_GAME_MAP_PATH): MapManager =
  MapManager(
    file: initMapDataFile(path),
    chunkManager: ChunkManager(map: chunkMap())
  )
