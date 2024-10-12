import
  std/asyncdispatch,
  ./ody/server,
  ./ody/core/types


when isMainModule:
  var settings = Settings(host: "127.0.0.1", port: 25565)
  waitFor settings.serve()
