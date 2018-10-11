import os, json, oids, sugar
import asyncnet, asyncdispatch, websocket
import unittest


suite "Shared shopping session: Alice is the host, Bob is a guest":
  const
    host = "localhost"
    port = Port 8080

  var
    aliceWs: AsyncWebSocket
    aliceCustomerId: string
    bobWs: AsyncWebSocket
    bobCustomerId: string

  let
    protocol = getEnv("PROTOCOL")
    sessionId = $genOid()

  template checkBroadcast(): untyped {.dirty.} =
    let
      (aliceOpcode, aliceData) = waitFor aliceWs.readData()
      alicePayload = parseJson(aliceData)["payload"]
      (bobOpcode, bobData) = waitFor bobWs.readData()
      bobPayload = parseJson(bobData)["payload"]

    check aliceOpcode == Opcode.Text
    check bobOpcode == Opcode.Text

    check alicePayload.hasKey "multicartContent"
    check bobPayload.hasKey "multicartContent"

    check alicePayload["multicartContent"] == bobPayload["multicartContent"]

  test "Alice and Bob establish connection":
    aliceWs = waitFor newAsyncWebsocketClient(host, port, "/" & sessionId, protocols = @[protocol])
    bobWs = waitFor newAsyncWebsocketClient(host, port, "/" & sessionId, protocols = @[protocol])

    require(not aliceWs.isNil)
    require(not bobWs.isNil)

  test "Alice starts session":
    let startSessionData = %*{
                                "event": "startSession",
                                "payload": {
                                  "customerName": "Alice"
                                }
                              }

    waitFor aliceWs.sendText($startSessionData)

    let
      (opcode, data) = waitFor aliceWs.readData()
      payload = parseJson(data)["payload"]

    check opcode == Opcode.Text
    check payload.hasKey "customerId"

    aliceCustomerId = getStr(payload["customerId"])

  test "Multicart update is sent to Alice after she start session":
    let
      (opcode, data) = waitFor aliceWs.readData()
      payload = parseJson(data)["payload"]

    check opcode == Opcode.Text
    check payload.hasKey "multicartContent"

    let multicartContent = payload["multicartContent"][0]

    check getStr(multicartContent["owner"]["id"]) == aliceCustomerId
    check getStr(multicartContent["owner"]["name"]) == "Alice"
    check getBool(multicartContent["owner"]["isHost"]) == true
    check getBool(multicartContent["owner"]["isReadyToCheckout"]) == false
    check multicartContent["content"] == newJObject()

  test "Bob joins session":
    let joinSessionData = %*{
                              "event": "joinSession",
                              "payload": {
                                "customerName": "Bob"
                              }
                            }

    waitFor bobWs.sendText($joinSessionData)

    let
      (opcode, data) = waitFor bobWs.readData()
      payload = parseJson(data)["payload"]

    check opcode == Opcode.Text
    check payload.hasKey "customerId"

    bobCustomerId = getStr(payload["customerId"])

    checkBroadcast()

  test "Alice adds products to cart":
    let updateCartData = %*{
                              "event": "updateCart",
                              "payload": {
                                "customerId": aliceCustomerId,
                                "cartContent": {
                                  "items": [
                                    {
                                      "quantity": 1,
                                      "product": [
                                        {
                                          "id": 123,
                                          "name": "Sleepers",
                                          "price": 2,
                                          "shortDescription": "Fluffy sleepers",
                                          "sku": "qwe456",
                                          "url": "https://exampleshop.com/sleepers",
                                          "weight": 3
                                        }
                                      ]
                                    }
                                  ],
                                  "productsQuantity": 1,
                                  "orderId": 456,
                                  "couponName": nil,
                                  "weight": 3,
                                  "paymentMethod": nil,
                                  "shippingMethod": nil,
                                  "cartId": "asd789"
                                }
                              }
                            }

    waitFor aliceWs.sendText($updateCartData)

    checkBroadcast()

    let multicartContent = alicePayload["multicartContent"]

    var updateCartDataInMulticartContent: bool

    for cart in multicartContent:
      if cart["content"] == updateCartData["payload"]["cartContent"]:
        updateCartDataInMulticartContent = true
        break

    check updateCartDataInMulticartContent

  test "Bob adds products to cart":
    let updateCartData = %*{
                              "event": "updateCart",
                              "payload": {
                                "customerId": bobCustomerId,
                                "cartContent": {
                                  "items": [
                                    {
                                      "quantity": 1,
                                      "product": [
                                        {
                                          "id": 321,
                                          "name": "T-Shirt",
                                          "price": 23,
                                          "shortDescription": "Fluffy sleepers",
                                          "sku": "654ewq",
                                          "url": "https://exampleshop.com/tshirt",
                                          "weight": 12
                                        }
                                      ]
                                    }
                                  ],
                                  "productsQuantity": 1,
                                  "orderId": 654,
                                  "couponName": nil,
                                  "weight": 12,
                                  "paymentMethod": nil,
                                  "shippingMethod": nil,
                                  "cartId": "987dsa"
                                }
                              }
                            }

    waitFor aliceWs.sendText($updateCartData)

    checkBroadcast()

    let multicartContent = bobPayload["multicartContent"]

    var updateCartDataInMulticartContent: bool

    for cart in multicartContent:
      if cart["content"] == updateCartData["payload"]["cartContent"]:
        updateCartDataInMulticartContent = true
        break

    check updateCartDataInMulticartContent

  test "Bob is ready to checkout":
    let customerReadyToCheckoutData = %*{
                                          "event": "customerReadyToCheckout",
                                          "payload": {
                                            "customerId": bobCustomerId,
                                            "customerReadyToCheckout": true
                                          }
                                        }

    waitFor bobWs.sendText($customerReadyToCheckoutData)

    checkBroadcast()

    let multicartContent = bobPayload["multicartContent"]

    var bobIsReadyToCheckout: bool

    for cart in multicartContent:
      if getStr(cart["owner"]["id"]) == bobCustomerId:
        bobIsReadyToCheckout = getBool(cart["owner"]["isReadyToCheckout"])
        break

    check bobIsReadyToCheckout

  test "Alice is ready to checkout":
    let customerReadyToCheckoutData = %*{
                                          "event": "customerReadyToCheckout",
                                          "payload": {
                                            "customerId": aliceCustomerId,
                                            "customerReadyToCheckout": true
                                          }
                                        }

    waitFor aliceWs.sendText($customerReadyToCheckoutData)

    checkBroadcast()

    let multicartContent = alicePayload["multicartContent"]

    var aliceIsReadyToCheckout: bool

    for cart in multicartContent:
      if getStr(cart["owner"]["id"]) == aliceCustomerId:
        aliceIsReadyToCheckout = getBool(cart["owner"]["isReadyToCheckout"])
        break

    check aliceIsReadyToCheckout
