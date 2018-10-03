import websocket, asyncnet, asyncdispatch, os, strutils, json
import testUpdateCart, testReadyToCheckout

let
  host = paramStr(1).split(':')[0]
  port = Port parseInt(paramStr(1).split(':')[1])
  sessionId = paramStr(2)

let ws = waitFor newAsyncWebsocketClient(host, port, "/" & sessionId,
                                          protocols = @["86aa6d449d3de20132e08d77b909547d"])

var
  customerId: string
  isReadyToCheckout: bool


proc joinSession() {.async.} =
  let data = parseFile "testJoinSession.json"
  waitFor ws.sendText $data

proc updateCart() {.async.} =
  while true:
    await sleepAsync(3000)
    if len(customerId) > 0:
      let data = parseJson testUpdateCart.getData(customerId)
      waitFor ws.sendText $data
      isReadyToCheckout = true
      return

proc readyToCheckout() {.async.} =
  while true:
    await sleepAsync(6000)
    if isReadyToCheckout:
      let data = parseJson testReadyToCheckout.getData(customerId, true)
      echo data
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

    if event == "joinSession":
      customerId = payload["customerId"].getStr()


asyncCheck read()
asyncCheck joinSession()
asyncCheck updateCart()
asyncCheck readyToCheckout()
runForever()
