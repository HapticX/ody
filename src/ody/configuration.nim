## Setup and read config
import
  std/json,
  std/os,
  ./core/constants


export
  constants


var
  currentConfig* = DEFAULT_CONFIG


proc checkServerIsCreated*(): bool =
  fileExists(CONFIG_NAME)
