import os, strutils, strformat, json, sequtils, sugar, oids, tables
import websocket, asynchttpserver, asyncnet, asyncdispatch


type
  Customer = object
    id: string
    name: string
    ws: AsyncWebSocket
    isHost: bool
    isReadyToCheckout: bool

  Cart = object
    owner: Customer
    content: JsonNode

  Session = Table[string, Cart]

  State = Table[string, Session]


proc newCustomer(name: string, ws: AsyncWebSocket, isHost=false): Customer =
  result.id = $genOid()
  result.name = name
  result.ws = ws
  result.isHost = isHost

func newCart(owner: Customer): Cart =
  result.owner = owner
  result.content = newJObject()

func newSession(): Session = initTable[string, Cart]()

func newState(): State = initTable[string, Session]()

func multicart(session: Session): JsonNode =
  result = newJArray()
  for cart in session.values:
    result.add %*{
      "owner": {"id": cart.owner.id, "name": cart.owner.name},
      "content": cart.content
    }

proc broadcast(session: Session, message: string) {.async.} =
  for cart in session.values:
    await cart.owner.ws.sendText message

proc cleanup(state: var State) =
  var newState = newState()

  for sessionId, session in state:
    var newSession = newSession()

    for ownerId, cart in session:
      if not cart.owner.ws.sock.isClosed:
        newSession[ownerId] = cart

    if len(newSession) > 0:
      newState[sessionId] = newSession

  state = newState


proc main() =
  var state = newState()

  echo "Server is ready"

  proc cb(request: Request) {.async.} =
    try:
      let
        sessionId = request.url.path.strip(chars={'/'})
        (ws, error) = await verifyWebsocketRequest(request, getEnv("MC_PROTOCOL", "secret"))

      if ws.isNil:
        await request.respond(Http400, error)
        request.client.close()
        return

      echo &"Client connected to session {sessionId}"

      while true:
        let (opcode, data) =
          try:
            await ws.readData()
          except:
            (Opcode.Close, "")

        case opcode
        of Opcode.Close:
          asyncCheck ws.close()
          echo &"Connection to session {sessionId} closed"
          break

        of Opcode.Text:
          let
            parsedData = parseJson(data)
            event = getStr(parsedData["event"])
            payload = parsedData["payload"]

          case event
          of "startSession":
            let customer = newCustomer(getStr(payload["customerName"]), ws, isHost=true)

            state[sessionId] = newSession()
            state[sessionId][customer.id] = newCart(customer)

            await customer.ws.sendText $(%*{"event": event, "payload": {"customerId": customer.id}})

          of "joinSession":
            let customer = newCustomer(getStr(payload["customerName"]), ws)

            state[sessionId][customer.id] = newCart(customer)

            await customer.ws.sendText $(%*{"event": event, "payload": {"customerId": customer.id}})

          of "updateCart":
            let customerId = getStr(payload["customerId"])

            state[sessionId][customerId].content = payload["cartContent"]

          of "customerReadyToCheckout":
            discard

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

  waitFor newAsyncHttpServer().serve(Port 8841, cb)

when isMainModule:
  main()
