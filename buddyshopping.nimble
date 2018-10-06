# Package

version       = "1.0.0"
author        = "Konstantin Molchanov"
description   = "BuddyShopping backend."
license       = "MIT"
srcDir        = "src"
bin           = @["buddyshopping"]


# Dependencies

requires "nim >= 0.19.0", "websocket"

task docs, "Generate API docs":
  exec "nim doc src/buddyshopping.nim"
