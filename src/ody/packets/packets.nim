import
  std/asyncdispatch,
  std/asyncnet,
  std/logging,
  std/strformat,
  std/strutils,
  ../proto,
  ../core/types


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


proc sendBuffer*(socket: AsyncSocket, buf: Buffer): Future[void] {.async.} =
  var tmpBuf = newBuffer()
  tmpBuf.writeVar[:int32](buf.data.len.int32)
  tmpBuf.data = tmpBuf.data & buf.data
  await socket.send(addr tmpBuf.data[0], tmpBuf.data.len)
  tmpBuf.free()


proc parsePacket*(buf: Buffer): BasePacket =
  ## Parses AsyncSocket client connection and return base packet information
  let
    packetLength = buf.readVar[:int32]()
    packetId = buf.readVar[:int32]()
  buf.data.setLen(packetLength+4)
  BasePacket(id: packetId, length: packetLength, buf: buf)


proc ping*(socket: AsyncSocket, packet: BasePacket): Future[void] {.async.} =
  ## Reads packet buffer as Ping packet and responds data to socket
  var buf = newBuffer()
  buf.writeVar[:int32](0x01)
  buf.writeVar[:int64](packet.buf.readVar[:int64]())
  await socket.send(cast[string](buf.data))
  buf.free()


proc toHandshake*(packet: BasePacket): HandshakePacket =
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


proc toLogin*(packet: BasePacket): LoginPacket =
  ## Reads packet buffer as Login packet
  let
    username = packet.buf.readStr()
    uuid = packet.buf.readUUID()
  LoginPacket(base: packet, username: username, uuid: uuid)


proc toDisconnectDetails*(packet: BasePacket): DisconnectDetails =
  ## Reads packet buffer as Login packet
  let detailsLength = packet.buf.readVar[:int32]()
  var details: seq[tuple[title: string, description: string]] = @[]
  for i in 0..<detailsLength:
    details.add((
      title: packet.buf.readStr(),
      description: packet.buf.readStr(),
    ))
  DisconnectDetails(base: packet, details: details)


proc sendServerStatus*(socket: AsyncSocket, data: JsonNode): Future[void] {.async.} =
  ## Responds server status
  var buf = newBuffer()
  buf.writeVar[:int32](0x00)
  buf.writeString($data)
  await socket.sendBuffer(buf)
  buf.free()


proc sendLoggedIn*(client: Client): Future[void] {.async.} =
  ## Responds server status
  if client.protocolVersion < 735:
    # Old login success
    var buf = newBuffer()
    buf.writeNum[:int32](0x02)
    # buf.writeUUID(client.uuid)
    buf.writeString($client.uuid)
    buf.writeString(client.username)
    buf.writeVar[:int32](0x00)  # Number of properties
    await client.socket.sendBuffer(buf)
    buf.free()
    info fmt"User {client.username} is logged!"
  else:
    # New login success
    discard
