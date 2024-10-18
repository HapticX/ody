
type
  Block* = object
    palette*: int16


template initBlock*(plt: int16): Block =
  Block(palette: `plt`)


let
  AIR_BLOCK* = initBlock(0'i16)
