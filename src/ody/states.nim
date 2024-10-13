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
        client = Client(
          host: handshake.serverAddress,
          port: handshake.serverPort,
          protocolVersion: handshake.protocolVersion,
          socket: socket,
          username: ""
        )
        state = ClientState.Status
      of 2:
        client = Client(
          host: handshake.serverAddress,
          port: handshake.serverPort,
          protocolVersion: handshake.protocolVersion,
          socket: socket,
          username: ""
        )
        state = ClientState.Login
      of 3:
        state = ClientState.Transfer
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
      currentConfig, clients.len, client
    ))
    state = ClientState.Handshake
  # Ping-Pong state
  of 0x01:
    await ping(socket, packet)
  else:
    discard


template loginState*() {.dirty.} =
  case packet.id
  of 0x00:
    var login = packet.toLogin(client)
    client.username = login.username
    client.uuid = login.uuid
    clients.add(client)
    await client.sendLoggedIn()
    state = ClientState.Play
  else:
    discard
