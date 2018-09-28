import websocket, asyncnet, asyncdispatch, os, strutils, json

let
  host = paramStr(1).split(':')[0]
  port = Port parseInt(paramStr(1).split(':')[1])
  id = parseInt(paramStr(2))
  data = parseFile paramStr(3)

let ws = waitFor newAsyncWebsocketClient(host, port,
  path = "/" & $id, protocols = @["multicart"])

proc ping() {.async.} =
  while true:
    await sleepAsync(1000)
    await ws.sendText $data

proc read() {.async.} =
  while true:
    let (opcode, data) = await ws.readData()
    echo "(opcode: ", opcode, ", data length: ", parseJson(data).len, ")"

asyncCheck read()
asyncCheck ping()
runForever()
