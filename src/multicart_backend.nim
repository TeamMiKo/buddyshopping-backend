import strutils, strformat, json, options, tables, sequtils, sugar
import websocket, asynchttpserver, asyncnet, asyncdispatch


type
  Cart = object
    content: JsonNode
    clients: seq[AsyncWebSocket]

  State = Table[int, Cart]

proc newCart(): Cart =
  result.content = newJObject()
  result.clients = @[]

proc newState(): State = initTable[int, Cart]()

proc updateContent(cart: var Cart, newContent: JsonNode) = cart.content = newContent

proc addClient(cart: var Cart, newClient: AsyncWebSocket) =
  cart.clients = deduplicate(cart.clients & newClient)

proc removeDisconnectedClients(cart: var Cart) =
  cart.clients.keepItIf(not it.sock.isClosed)

proc main() =
  var state = newState()

  echo "Server is ready"

  proc cb(request: Request) {.async.} =
    let
      id = parseInt(request.url.path.strip(chars={'/'}))
      (ws, error) = await verifyWebsocketRequest(request, "multicart")

    if ws.isNil:
      await request.respond(Http400, error)
      request.client.close()
      return

    echo &"Client connected to session {id}"

    while true:
      let (opcode, data) =
        try:
          await ws.readData()
        except:
          (Opcode.Close, "")

      case opcode
      of Opcode.Close:
        asyncCheck ws.close()
        echo &"Connection to session {id} closed"
        break

      of Opcode.Text:
        let payload = parseJson(data)

        var cart = state.mgetOrPut(id, newCart())

        cart.updateContent(payload)
        cart.addClient(ws)
        cart.removeDisconnectedClients()

        state[id] = cart

        waitFor all cart.clients.mapIt(it.sendText $cart.content)

      else: discard

  waitFor newAsyncHttpServer().serve(Port 8080, cb)

when isMainModule:
  main()
