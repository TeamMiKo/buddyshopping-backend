#? stdtmpl
#func getData*(customerId: string): string =
{
  "event": "updateCart",
  "payload": {
    "customerId": "$customerId",
    "cartContent": {
      "items": ["foo", "bar", "baz"],
      "productsQuantity": 3,
      "orderId": 1488,
      "couponName": null,
      "weight": 1.23,
      "paymentMethod": null,
      "shippingMethod": null,
      "cartId": "qwe-123-asd-456-zxc-789"
    }
  }
}
