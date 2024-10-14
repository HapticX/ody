import
  std/asyncdispatch,
  std/strformat,
  std/asyncnet,
  std/logging,
  std/times,
  std/os,
  ./core/types


type
  World* = ref object
    isActive*: bool
    tickRate*: int
    players*: seq[Player]
    name*: string


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

    sleep(1000 / w.tickRate)

    # finish = epochTime()
    if epochTime() - start >= 1.0:
      tps = 0
      start = epochTime()
      debug fmt""
