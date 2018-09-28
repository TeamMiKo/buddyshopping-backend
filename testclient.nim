import websocket, asyncnet, asyncdispatch, os, strutils, json

let id = parseInt(paramStr(1))

let ws = waitFor newAsyncWebsocketClient("localhost", Port(8080),
  path = "/" & $id, protocols = @["multicart"])

proc ping() {.async.} =
  let data = %*{"id": id}

  while true:
    await sleepAsync(1000)
    await ws.sendText $data

proc read() {.async.} =
  while true:
    let (opcode, data) = await ws.readData()
    echo "(opcode: ", opcode, ", data: ", data, ")"

asyncCheck read()
asyncCheck ping()
runForever()
