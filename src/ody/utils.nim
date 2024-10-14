import
  std/json,
  ./configuration,
  ./core/types


func `%`(uuid: UUID): JsonNode =
  %($uuid)


proc buildServerStatus*(config: JsonNode, onlinePlayers: int, player: Player): JsonNode =
  ## Creates a status JSON response for Java Edition servers.
  ##
  ## The `description` field is a Chat object, but is not currently handled as such.
  ##
  ## The `ext` field is an optional field used for passing other fields not specified,
  ## such as `modinfo` for Forge clients.
  # var f = open("nim.txt", fmRead)
  # let data = f.readAll()
  # f.close()
  var
    availableVersions: seq[string] = @[]
    availableProtocols: seq[int] = @[]
    idx = -1
  if config.hasKey("available_versions"):
    for v in config["available_versions"]:
      if PROTOCOLS.hasKey(v.str):
        if PROTOCOLS[v.str].num == player.protocolVersion:
          idx = availableProtocols.len
        availableProtocols.add(PROTOCOLS[v.str].num)
        availableVersions.add(v.str)
  %*{
    "version": {
      "name":
        if idx != -1:
          availableVersions[idx]
        else:
          config["version"].str,
      "protocol":
        if idx != -1:
          availableProtocols[idx]
        else:
          PROTOCOLS[config["version"].str].num
    },
    "players": {
      "max": config["max_players"],
      "online": onlinePlayers,
      "sample": []
    },
    # "favicon": data,
    "online": config["online_mode"],
    "description": {"text": config["description"]},
    "request": {
      "host": config["host"],
      "port": config["port"],
      "type": "java",
      "legacy": false
    }
  }
