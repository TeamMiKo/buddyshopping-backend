# Real-Time Collab Shopping and Split the Bill by BuddyShopping

_BuddyShopping_ is an Ecwid app that helps customers shop together in real time.

Say, you're planning a party. You like pizza, Alice likes Chinese, and Ali is all about shawarma. There's an online shop that has all the required foods and offers delivery, but since you're not in the same room, you can't just sit together and pick the food. Also, there's a hundred varieties of pizza, Chinese food, and shawarmas, so just playing with the options and making the order for three will take a lot of time.

What do you do? How do you let three people order their own stuff and have it all in the same shopping cart, split by person, so that you could split the bill afterward?

Luckily, there's _BuddyShopping_ app for Ecwid. If it's installed, any customer can share their shopping session with friends, letting them contribute to a shared shopping cart and helping the host split the bill.

Back to the party, here's what you do:

1.  Click “Shop with friends” button:

2.  Click “Copy invitation link”:

3.  Send it to your friends:

4.  Shop! Add items to cart like you normally do and see others do the same:

5.  When your friend is finished with their order, they click “Ready to checkout.” When all your friends have done so, click “Proceed to checkout”:

6.  Pay for the order as usual. If you want to split the bill, click “Split the bill” button and download the order slip:


## Developer Guide

The app consists of the client and the server. The client is a JS app running on the Ecwid storefront. The server is a Nim app running in the cloud.

This repo is the home of the server.


## Build Instructions

- Build in release mode:

  ```shell
  $ nimble install
  ```

  or

  ```shell
  $ docker build -t buddyshopping-backend .
  ```

- Build in development mode:

  ```shell
  $ nimble build
  ```

- Run tests:

  - Build the app.

  - Run the app:

    ```shell
    $ ./buddyshopping
    ```

  - Run in a separate tab:

    ```shell
    $ nimble test
    ```

- Generate [API docs](https://teammiko.github.io/buddyshopping-backend/buddyshopping.html):

  ```shell
  $ nimble docs
  ```

- Upload the docs to GitHub Pages (you need [ghp-import](https://github.com/davisp/ghp-import)):

  ```shell
  ghp-import -np src
  ```


## Messages

The client and the server communicate by exchanging messages in serialized JSON over WebSocket. The supported message types are listed below.


### startSession

To start a shared shopping session, the client on the host's storefront establishes connection with the server at wss://multicartbackend.now.sh/:sessionId, where `:sessionId` is a unique random string. Session ID is generated by the host's client and shared with the host's friends.

The initial message that starts the session is:

```json
{
  "event": "startSession",
  "payload": {
    "customerName": "Michael"
  }
}
```

`customerName` is entered by the customer. It's a regular human-readable name. like “John,” or “Alice.” It doesn't have to be unique.

In exchange for the data above, the server generates a unique customer ID and sends it to the client:

```json
{
  "event": "startSession",
  "payload": {
    "customerId": "1234567qwe0000001"
  }
}
```

The client should use the received `customerId` in future messages to identify the customer.


### joinSession

To join a running shared shopping session, the client on the guest's storefront establishes connection to the same session as the session's host; the session ID is extracted from the invitation URL generated for and sent by the host.

The message to join a session is:

```json
{
  "event": "joinSession",
  "payload": {
    "customerName": "Constantine"
  }
}
```

In exchange, the server generates a unique customer ID and sends it to the client:

```json
{
  "event": "joinSession",
  "payload": {
    "customerId": "1234567asd0000002"
  }
}
```


### updateCart

Whenever a customer updates the cart state on their storefront, e.g. adds items, removes items, changes the properties or quantities of the items, the client sends a message to inform the server about the change:

```json
{
  "event": "updateCart",
  "payload": {
    "customerId": "1234567asd0000002",
    "cartContent": {
      "items": [{...}, {...}, ...],
      "productsQuantity": 3,
      "orderId": 123,
      "couponName": null,
      "weight": 1.23,
      "paymentMethod": null,
      "shippingMethod": null,
      "cartId": "456asd"
    }
  }
}
```

The object at `cartContent` key is an Ecwid's [Cart Object](https://developers.ecwid.com/api-documentation/get-cart-details#cart-object). It is the new state of the shopping cart.

`customerId` is the unique ID the client received after starting or joining the session.


### customerReadyToCheckout

When a customer is ready to checkout, their client sends the following message:

```json
{
  "event": "customerReadyToCheckout",
  "payload": {
    "customerId": "1234567asd0000002",
    "customerReadyToCheckout": true
  }
}
```

If the customer cancels the their ready state, the same message but with `false` is sent:

```json
{
  "event": "customerReadyToCheckout",
  "payload": {
    "customerId": "1234567asd0000002",
    "customerReadyToCheckout": false
  }
}
```

The client should not allow the host to toggle ready to checkout state before all guests have set theirs to `true`.


### multicartUpdate

After any of the messages above is processed by the server, the server broadcasts the new state of the so called _multicart_ to all clients connected to the session:

```json
{
  "event": "multicartUpdate",
  "payload": {
    "multicartContent": [
      {
        "owner": {
          "id": "1234567qwe0000001",
          "name": "Michael",
          "isHost": true,
          "isReadyToCheckout": false
          },
        "content": {...}
      },
      {
        "owner": {
          "id": "1234567asd0000002",
          "name": "Constantine",
          "isHost": false,
          "isReadyToCheckout": true
          },
        "content": {...}
      },
    ]
  }
}
```

Multicart is an object that holds the state of all carts participating in the session.

`content` key points to a Cart Object from Ecwid's API.
