import
  std/json,
  ./configuration,
  ./core/types


func `%`(uuid: UUID): JsonNode =
  %($uuid)


proc buildServerStatus*(config: JsonNode, onlinePlayers: seq[ServerPlayer]): JsonNode =
  ## Creates a status JSON response for Java Edition servers.
  ##
  ## The `description` field is a Chat object, but is not currently handled as such.
  ##
  ## The `ext` field is an optional field used for passing other fields not specified,
  ## such as `modinfo` for Forge clients.
  # var f = open("nim.txt", fmRead)
  # let data = f.readAll()
  # f.close()
  result = %*{
    "version": {
      "name": config["version"],
      "protocol": PROTOCOLS[config["version"].getStr]
    },
    "players": {
      "max": config["max_players"],
      "online": onlinePlayers.len,
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
