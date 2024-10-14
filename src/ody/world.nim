import
  std/asyncdispatch,
  std/strformat,
  std/asyncnet,
  std/logging,
  std/times,
  std/os,
  ./core/types,
  ./entities,
  ./nbt


proc tick*(w: World) =
  discard


proc run*(w: World) =
  var
    start = epochTime()
    # finish = epochTime()
    tps = 0
  while w.isActive:
    w.tick()
    inc tps

    sleep(int(1000 / w.tickRate))

    # finish = epochTime()
    if epochTime() - start >= 1.0:
      tps = 0
      start = epochTime()
      # debug fmt""
