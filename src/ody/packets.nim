import
  std/asyncdispatch,
  std/asyncnet,
  std/logging,
  std/strformat,
  std/strutils,
  ./proto,
  ./core/types


type
  BasePacket* = object
    id*: int
    length*: int
    buf*: Buffer
  HandshakePacket* = object
    base*: BasePacket
    protocolVersion*: int
    serverAddress*: string
    serverPort*: uint16
    nextState*: int
  LoginPacket* = object
    base*: BasePacket
    username*: string
    uuid*: UUID
  DisconnectDetails* = object
    base*: BasePacket
    details*: seq[tuple[title: string, description: string]]


proc sendPacket*(socket: AsyncSocket, buf: Buffer): Future[void] {.async.} =
  var tmpBuf = newBuffer()
  tmpBuf.writeVar[:int32](buf.data.len.int32)
  tmpBuf.data = tmpBuf.data & buf.data
  await socket.send(addr tmpBuf.data[0], tmpBuf.data.len)
  tmpBuf.free()


func parsePacket*(buf: Buffer): BasePacket =
  ## Parses AsyncSocket client connection and return base packet information
  let
    packetLength = buf.readVar[:int32]()
    packetId = buf.readVar[:int32]()
  buf.data.setLen(packetLength+64)
  BasePacket(id: packetId, length: packetLength, buf: buf)


func toHandshake*(packet: BasePacket): HandshakePacket =
  ## Reads packet buffer as Handshake packet
  if packet.length >= 16:
    let
      protocolVersion = packet.buf.readVar[:int32]()
      serverAddress = packet.buf.readStr()
      serverPort = packet.buf.readNum[:uint16]()
      nextState = packet.buf.readVar[:int32]()
    return HandshakePacket(
      base: packet, protocolVersion: protocolVersion,
      serverAddress: serverAddress, serverPort: serverPort,
      nextState: nextState
    )


proc toLogin*(packet: BasePacket, client: Client): LoginPacket =
  ## Reads packet buffer as Login packet
  # <= v1.18.2
  if client.protocolVersion <= 758:
    let username = packet.buf.readStr()
    LoginPacket(base: packet, username: username, uuid: genUUID())
  # v1.19.3 - 1.20.1
  elif client.protocolVersion >= 761 and client.protocolVersion <= 763:
    let
      username = packet.buf.readStr()
      hasUUID = packet.buf.readNum[:bool]()
      uuid =
        if hasUUID:
          packet.buf.readUUID()
        else:
          genUUID()
    LoginPacket(base: packet, username: username, uuid: uuid)
  # v1.20.2+
  elif client.protocolVersion >= 764:
    let
      username = packet.buf.readStr()
      uuid = packet.buf.readUUID()
    LoginPacket(base: packet, username: username, uuid: uuid)
  else:
    let
      username = packet.buf.readStr()
    LoginPacket(base: packet, username: username, uuid: genUUID())


func toDisconnectDetails*(packet: BasePacket): DisconnectDetails =
  ## Reads packet buffer as Login packet
  var
    detailsLength = packet.buf.readVar[:int32]()
    details: seq[tuple[title: string, description: string]] = @[]
  while detailsLength > 0:
    details.add((
      title: packet.buf.readStr(),
      description: packet.buf.readStr(),
    ))
    dec detailsLength
  DisconnectDetails(base: packet, details: details)


proc ping*(socket: AsyncSocket, packet: BasePacket): Future[void] {.async.} =
  ## Reads packet buffer as Ping packet and responds data to socket
  var buf = newBuffer()
  buf.writeVar[:int32](0x01)
  buf.writeNum[:int64](packet.buf.readNum[:int64]())
  await socket.sendPacket(buf)
  buf.free()


proc sendServerStatus*(socket: AsyncSocket, data: JsonNode): Future[void] {.async.} =
  ## Responds server status
  var buf = newBuffer()
  buf.writeVar[:int32](0x00)
  buf.writeString($data)
  await socket.sendPacket(buf)
  buf.free()


proc sendLoggedIn*(client: Client): Future[void] {.async.} =
  ## Responds server status
  # Version older than 1.18.2
  if client.protocolVersion < 758:
    # Old login success
    var buf = newBuffer()
    buf.writeVar[:int32](0x02)
    buf.writeString($client.uuid)
    buf.writeString(client.username)
    await client.socket.sendPacket(buf)
    buf.free()
    info fmt"{client.username} logged in to the server"
  else:
    # New login success
    discard
