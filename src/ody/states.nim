import
  std/asyncdispatch,
  std/asyncnet,
  ./packets


template handshakeState*() {.dirty.} =
  case packet.id
  of 0x00:
    let handshake = packet.toHandshake()
    case handshake.nextState:
      of 1:
        player = Player(
          host: handshake.serverAddress,
          port: handshake.serverPort,
          protocolVersion: handshake.protocolVersion,
          socket: socket,
          username: ""
        )
        state = PlayerState.Status
      of 2:
        player = Player(
          host: handshake.serverAddress,
          port: handshake.serverPort,
          protocolVersion: handshake.protocolVersion,
          socket: socket,
          username: ""
        )
        state = PlayerState.Login
      of 3:
        state = PlayerState.Transfer
      else:
        discard
  # Ping-Pong state
  of 0x01:
    await ping(socket, packet)
  else:
    discard


template statusState*() {.dirty.} =
  case packet.id
  of 0x00:
    await socket.sendServerStatus(buildServerStatus(
      currentConfig, players.len, player
    ))
    state = PlayerState.Handshake
  # Ping-Pong state
  of 0x01:
    await ping(socket, packet)
  else:
    discard


template loginState*() {.dirty.} =
  case packet.id
  of 0x00:
    var login = packet.toLogin(player)
    player.username = login.username
    player.uuid = login.uuid
    players.add(player)
    await player.sendLoggedIn()
    state = PlayerState.Play
  else:
    discard


template playState*() {.dirty.} =
  case packet.id
  of 0x00:
    discard
  else:
    discard
