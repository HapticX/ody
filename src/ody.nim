import
  std/asyncdispatch,
  ./ody/server,
  ./ody/core/types


when isMainModule:
  waitFor runServer()
