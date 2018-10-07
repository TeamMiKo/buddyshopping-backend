import os, strutils, json, sequtils, tables, times, oids
import asynchttpserver, asyncnet, asyncdispatch, websocket


type
  Customer* = object
    id: string
    name: string
    ws: AsyncWebSocket
    isHost: bool
    isReadyToCheckout: bool

  Cart* = object
    owner: Customer
    content: JsonNode

  Session* = Table[string, Cart]

  State* = Table[string, Session]


proc initCustomer*(name: string, ws: AsyncWebSocket, isHost=false): Customer =
  ## Create a ``Customer`` instance. ``id`` is an oid.

  result.id = $genOid()
  result.name = name
  result.ws = ws
  result.isHost = isHost

func initCart*(owner: Customer): Cart =
  ## Create a ``Cart`` instance with the given owner. Default content is an empty JSON object.

  result.owner = owner
  result.content = newJObject()

func initSession*(): Session = initTable[string, Cart]()
  ## Create a session as an empty table of strings to `Cart <#Cart>`__\ s.

func initState*(): State = initTable[string, Session]()
  ## Create a state as an empty table of strings to `Session <#Session>`__\ s.

func multicart*(session: Session): JsonNode =
  ## Generate *multicart*, which is  an entire session's state in JSON form.

  result = newJArray()
  for cart in session.values:
    result.add %*{
      "owner": {
        "id": cart.owner.id,
        "name": cart.owner.name,
        "isHost": cart.owner.isHost,
        "isReadyToCheckout": cart.owner.isReadyToCheckout
      },
      "content": cart.content
    }

proc broadcast*(session: Session, message: string) {.async.} =
  ## Send ``message`` to all customers in ``session``.

  for cart in session.values:
    await cart.owner.ws.sendText message

proc cleanup*(state: var State) =
  ## Remove disconnected websockets from sessions and empty sessions from the state.

  var initState = initState()

  for sessionId, session in state:
    var initSession = initSession()

    for ownerId, cart in session:
      if not cart.owner.ws.sock.isClosed:
        initSession[ownerId] = cart

    if len(initSession) > 0:
      initState[sessionId] = initSession

  state = initState


proc main() =
  let protocol = getEnv("PROTOCOL")
  var state = initState()

  echo "Server is ready"

  proc cb(request: Request) {.async.} =
    try:
      let
        sessionId = request.url.path.strip(chars={'/'})
        (ws, error) = await verifyWebsocketRequest(request, protocol)

      if ws.isNil:
        await request.respond(Http400, error)
        request.client.close()
        return

      echo "Client connected to session $#" % sessionId

      while true:
        let (opcode, data) =
          try:
            await ws.readData()
          except:
            (Opcode.Close, "")

        case opcode
        of Opcode.Close:
          asyncCheck ws.close()
          echo "Connection to session $# closed" % sessionId
          break

        of Opcode.Text:
          let
            parsedData = parseJson(data)
            event = getStr(parsedData["event"])
            payload = parsedData["payload"]

          case event
          of "startSession":
            let customer = initCustomer(getStr(payload["customerName"]), ws, isHost=true)

            state[sessionId] = initSession()
            state[sessionId][customer.id] = initCart(customer)

            await customer.ws.sendText $(%*{"event": event, "payload": {"customerId": customer.id}})

          of "joinSession":
            let customer = initCustomer(getStr(payload["customerName"]), ws)

            state[sessionId][customer.id] = initCart(customer)

            await customer.ws.sendText $(%*{"event": event, "payload": {"customerId": customer.id}})

          of "updateCart":
            let customerId = getStr(payload["customerId"])

            state[sessionId][customerId].content = payload["cartContent"]

          of "customerReadyToCheckout":
            let
              customerId = getStr(payload["customerId"])
              customerReadyToCheckout = getBool(payload["customerReadyToCheckout"])

            state[sessionId][customerId].owner.isReadyToCheckout = customerReadyToCheckout

          else: discard

          state.cleanup()

          let multicartPayload = %*{
                                    "event": "multicartUpdate",
                                    "payload": {
                                      "multicartContent": state[sessionId].multicart
                                    }
                                  }

          await state[sessionId].broadcast($multicartPayload)

        else: discard

    except: discard

  waitFor newAsyncHttpServer().serve(Port 8080, cb)

when isMainModule:
  main()
