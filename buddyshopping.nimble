# Package

version       = "1.0.1"
author        = "Konstantin Molchanov"
description   = "BuddyShopping backend."
license       = "MIT"
srcDir        = "src"
bin           = @["buddyshopping"]


# Dependencies

requires "nim >= 0.19.0", "websocket", "hashids"

task docs, "Generate and upload API docs":
  exec "nim doc src/buddyshopping.nim"
  exec "ghp-import -np src"
