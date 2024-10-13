import
  std/asyncdispatch,
  std/asyncnet,
  std/logging,
  std/strformat,
  std/strutils,
  std/terminal,
  ./proto,
  ./packets/packets,
  ./core/types,
  ./configuration,
  ./utils,
  ./states


var consoleLogger = newConsoleLogger(
  lvlDebug,
  ansiForegroundColorCode(fgYellow) & "[$date at $time] - $levelname: " & ansiResetCode
)
addHandler(consoleLogger)


var
  serverPlayers: seq[ServerPlayer] = @[]
  clients: seq[Client] = @[]


proc `[]`*(self: seq[Client], key: AsyncSocket): Client =
  for c in clients:
    if c.socket == key:
      return c


proc processRequest*(socket: AsyncSocket) {.async.} =
  var
    state = ClientState.Handshake
    client: Client
  try:
    while not socket.isNil and not socket.isClosed():
      var buf = await socket.makeBuffer()
      let packet = parsePacket(buf)

      if packet.length < 0 or buf.len == 0:
        # no packet available, client was closed
        continue
      # debug fmt"packet 0x{packet.id.byte.toHex()} with {packet.length} length"

      case state
      of ClientState.Handshake:
        handshakeState()
      of ClientState.Status:
        statusState()
      of ClientState.Login:
        loginState()
      of ClientState.Play:
        discard
      of ClientState.Transfer:
        discard
      # # Custom Report Details
      # of 0x7A:
      #   let details = packet.toDisconnectDetails()
      #   echo "player disconnect details: ", details.details
      # else:
      # debug fmt"Unknown packet ID - {packet.id.byte.toHex()}"
  except:
    echo getStackTrace()
  for i in 0..<clients.len:
    if clients[i] == client:
      clients.del(i)
      break


proc serve*(s: Settings) {.async.} =
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

  # Setup server
  var server = newAsyncSocket()
  server.setSockOpt(OptReuseAddr, true)
  server.bindAddr(Port(s.port), s.host)
  server.listen()

  info fmt"""Server started at {currentConfig["host"].getStr}:{currentConfig["port"]}"""

  # Listen clients
  while true:
    let socket = await server.accept()
    asyncCheck processRequest(socket)
