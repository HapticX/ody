import
  std/asyncdispatch,
  std/asyncnet,
  std/logging,
  std/strformat,
  std/strutils,
  std/terminal,
  std/os,
  std/osproc,
  ./proto,
  ./packets,
  ./core/types,
  ./configuration,
  ./utils,
  ./states,
  ./world,
  ./map/map_manager


var consoleLogger = newConsoleLogger(
  lvlDebug,
  ansiForegroundColorCode(fgYellow) & "[$date at $time] - $levelname: " & ansiResetCode
)
addHandler(consoleLogger)


var players: seq[Player] = @[]


proc `[]`*(self: seq[Player], key: AsyncSocket): Player =
  for p in players:
    if p.socket == key:
      return p


proc processRequest*(socket: AsyncSocket) {.async.} =
  var
    state = PlayerState.Handshake
    player: Player
  try:
    while not socket.isNil and not socket.isClosed():
      var buf = await socket.makeBuffer()
      if buf.isNil:
        continue
      let packet = parsePacket(buf)

      if packet.length < 0 or buf.len == 0:
        # no packet available, client was closed
        continue
      debug fmt"packet 0x{packet.id.byte.toHex()} with {packet.length} length"

      case state
      of PlayerState.Handshake:
        handshakeState()
      of PlayerState.Status:
        statusState()
      of PlayerState.Login:
        loginState()
      of PlayerState.Play:
        discard
        # debug fmt"packet 0x{packet.id.byte.toHex()} with {packet.length} length"
      of PlayerState.Transfer:
        discard
      # # Custom Report Details
      # of 0x7A:
      #   let details = packet.toDisconnectDetails()
      #   echo "player disconnect details: ", details.details
      # else:
      # debug fmt"Unknown packet ID - {packet.id.byte.toHex()}"
  except:
    echo getStackTrace()
  for i in 0..<players.len:
    if players[i] == player:
      players.del(i)
      break


proc runServer*() {.async.} =
  ## Launches server
  
  # Configuration
  if checkServerIsCreated():
    info("Load configuration ...")
    currentConfig = parseFile(CONFIG_NAME)
    if not PROTOCOLS.hasKey(currentConfig["version"].getStr):
      error(fmt"""Version {currentConfig["version"]} is not exists!""")
      return
    info("Success!")
  else:
    info("Create configuration ...")
    var f = open(CONFIG_NAME, fmWrite)
    f.write(currentConfig.pretty())
    f.close()
    info("Success!")
  
  var map: MapManager

  if not currentConfig.hasKey("game_map") or not fileExists(currentConfig["game_map"].str):
    info("Game map not found. Creating new ...")
    map = initGameMap(currentConfig["game_map"].str)
    info("Game map was initialized.")
  else:
    info("Game map was found. Load game map ...")
    map = initGameMap(currentConfig["game_map"].str)
    info("Game map was loaded.")


  # Setup server
  var server = newAsyncSocket()
  server.setSockOpt(OptReuseAddr, true)
  server.bindAddr(Port(currentConfig["port"].num), currentConfig["host"].str)
  server.listen()

  info fmt"""Server started at {currentConfig["host"].getStr}:{currentConfig["port"]}"""

  # Listen clients
  while true:
    let socket = await server.accept()
    asyncCheck processRequest(socket)
