#? stdtmpl
#func getData*(customerId: string, customerReadyToCheckout: bool): string =
{
  "event": "customerReadyToCheckout",
  "payload": {
    "customerId": "$customerId",
    "customerReadyToCheckout": "$customerReadyToCheckout"
    }
  }
}
