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
  ./utils


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
      # let line = await client.recvLine()
      var buf = await socket.makeBuffer()
      let packet = parsePacket(buf)

      if packet.length < 0:
        # no packet available, client was closed
        return

      # debug(fmt"Get new packet with ID {packet.id} [{packet.length}]")
      case packet.id
      # Handshake state
      of 0x00:
        case state
        of ClientState.Handshake:
          let handshake = packet.toHandshake()
          case handshake.nextState:
            of 1:
              await socket.sendServerStatus(buildServerStatus(currentConfig, serverPlayers))
            of 2:
              client = Client(
                host: handshake.serverAddress,
                port: handshake.serverPort,
                protocolVersion: handshake.protocolVersion,
                socket: socket,
                username: ""
              )
              clients.add(client)
              state = ClientState.Login
            else:
              discard
        of ClientState.Login:
          var login = packet.toLogin()
          client.username = login.username
          client.uuid = login.uuid
          await client.sendLoggedIn()
          state = ClientState.Play
          # serverPlayers.add(ServerPlayer(username: login.username, uuid: $login.uuid))
        else:
          discard
      # Ping-Pong state
      of 0x01:
        echo "pong"
        await ping(socket, packet)
      # Custom Report Details
      # TODO
      of 0x7A:
        let details = packet.toDisconnectDetails()
        echo "player disconnect details: ", details.details
      else:
        discard
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
