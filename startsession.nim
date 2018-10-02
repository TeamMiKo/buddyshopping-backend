import websocket, asyncnet, asyncdispatch, os, strutils, json
import testUpdateCart

let
  host = paramStr(1).split(':')[0]
  port = Port parseInt(paramStr(1).split(':')[1])
  sessionId = paramStr(2)

let ws = waitFor newAsyncWebsocketClient(host, port, "/" & sessionId, protocols = @["secret"])

var customerId: string


proc startSession() {.async.} =
  let data = parseFile "testStartSession.json"
  waitFor ws.sendText $data

proc updateCart() {.async.} =
  while true:
    await sleepAsync(5000)
    if len(customerId) > 0:
      let data = parseJson getData(customerId)
      waitFor ws.sendText $data
      return

proc read() {.async.} =
  while true:
    let
      (opcode, data) = await ws.readData()
      parsedData = parseJson data
      event = parsedData["event"].getStr()
      payload = parsedData["payload"]

    echo payload

    if event == "startSession":
      customerId = payload["customerId"].getStr()


asyncCheck read()
asyncCheck startSession()
asyncCheck updateCart()
runForever()
