import os, sequtils, strutils, logging
import tables, json
import hashids
import asynchttpserver, asyncnet, asyncdispatch
import websocket


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


func initCustomer*(hashids: Hashids, name: string, ws: AsyncWebSocket, isHost=false): Customer =
  ## Create a ``Customer`` instance. ``id`` is a hashid created by the given ``Hashids`` instance from the customer's name.

  result.id = hashids.encodeHex(name.toHex)
  result.name = name
  result.ws = ws
  result.isHost = isHost

func initCart*(owner: Customer): Cart =
  ## Create a ``Cart`` instance with the given owner. Default content is an empty JSON object.

  result.owner = owner
  result.content = newJObject()

func initSession*(): Session = initTable[string, Cart]()
  ## Create a session as an empty table of strings to Carts.

func initState*(): State = initTable[string, Session]()
  ## Create a state as an empty table of strings to Sessions.

func multicart*(session: Session): JsonNode =
  ## Generate multicart, which is  an entire session's state in JSON form.

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

  var newState = initState()

  for sessionId, session in state:
    var newSession = initSession()

    for ownerId, cart in session:
      if not cart.owner.ws.sock.isClosed:
        newSession[ownerId] = cart

    if len(newSession) > 0:
      newState[sessionId] = newSession

  state = newState


proc main() =
  let
    protocol = getEnv("PROTOCOL")
    consoleLogger = newConsoleLogger(when defined(release): lvlInfo else: lvlAll)

  echo "Protocol ", protocol

  var state = initState()

  addHandler(consoleLogger)

  info "Server is ready"

  proc requestHandler(request: Request) {.async.} =
    try:
      let
        sessionId = request.url.path.strip(chars={'/'})
        hashids = createHashids(sessionId)
        (ws, error) = await verifyWebsocketRequest(request, protocol)

      if ws.isNil:
        await request.respond(Http400, error)
        request.client.close()
        return

      info "Client connected to session ", sessionId

      while true:
        let (opcode, data) =
          try:
            await ws.readData()
          except:
            debug "Lost connection to session ", sessionId
            (Opcode.Close, "")

        case opcode
        of Opcode.Close:
          asyncCheck ws.close()
          info "Closed connection to session ", sessionId
          break

        of Opcode.Text:
          let
            parsedData = parseJson(data)
            event = getStr(parsedData["event"])
            payload = parsedData["payload"]

          case event
          of "startSession":
            let customer = hashids.initCustomer(getStr(payload["customerName"]), ws, isHost=true)

            state[sessionId] = initSession()
            state[sessionId][customer.id] = initCart(customer)

            await customer.ws.sendText $(%*{"event": event, "payload": {"customerId": customer.id}})

          of "joinSession":
            let customer = hashids.initCustomer(getStr(payload["customerName"]), ws)

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

          else:
            warn "Invalid event: ", event

          state.cleanup()

          let multicartPayload = %*{
                                    "event": "multicartUpdate",
                                    "payload": {
                                      "multicartContent": state[sessionId].multicart
                                    }
                                  }

          await state[sessionId].broadcast($multicartPayload)

        else:
          warn "Invalid opcode: ", opcode

    except:
      error getCurrentExceptionMsg()

  waitFor newAsyncHttpServer().serve(Port 8080, requestHandler)


when isMainModule:
  main()
