{
  total: 1,
  count: 1,
  offset: 0,
  limit: 100,
  items: [
    {
      // Basic information
      cartId: "6626E60A-A6F9-4CD5-8230-43D5F162E0CD",
      tax: 1.79,
      subtotal: 29.95,
      total: 37.39,
      usdTotal: 37.39,
      paymentMethod: "Purchase order",

      // Additional information
      refererUrl: "http://mysuperstore.ecwid.com/",
      globalReferer: "",
      createDate: "2014-09-20 19:59:43 +0000",
      updateDate: "2014-09-21 00:00:12 +0000",
      createTimestamp: 1427268654,
      updateTimestamp: 1427272209,
      hidden: false,
      orderComments: "Test order comments",

      // Basic customer information
      email: "johnsmith@example.com",
      ipAddress: "83.217.8.241",
      customerId: 15319410,
      customerGroupId: 12345,
      customerGroup: "Gold",
      customerTaxExempt: false,
      customerTaxId: "",
      customerTaxIdValid: false,
      reversedTaxApplied: false,

      // Discounts in order
      membershipBasedDiscount: 0,
      totalAndMembershipBasedDiscount: 2.85,
      couponDiscount: 1.5,
      discount: 2.85,
      volumeDiscount: 0,
      discountCoupon: {
        name: "Coupon # 3",
        code: "5PERCENTOFF",
        discountType: "PERCENT",
        status: "ACTIVE",
        discount: 5,
        launchDate: "2014-06-06 00:00:00 +0000",
        usesLimit: "UNLIMITED",
        repeatCustomerOnly: false,
        creationDate: "2014-09-20 19:58:49 +0000",
        orderCount: 0
      },
      discountInfo: [
        {
          value: 10,
          type: "PERCENT",
          base: "ON_TOTAL_AND_MEMBERSHIP",
          orderTotal: 15
        },
        {
          value: 2,
          type: "ABSOLUTE",
          base: "CUSTOM",
          description: "Buy more than 3 cherries and get $2 off!"
        }
      ],

      // Order items details
      items: [
        {
          id: 40989227,
          productId: 37208342,
          categoryId: 9691094,
          price: 5.99,
          productPrice: 5.99,
          weight: 0.32,
          sku: "00004",
          quantity: 5,
          shortDescription:
            "Cherry\nThe word cherry refers to a fleshy fruit (drupe) that contains a single stony seed. The cherry belongs to the fa...",
          tax: 1.79,
          shipping: 10,
          quantityInStock: 1981,
          name: "Cherry",
          isShippingRequired: true,
          trackQuantity: true,
          fixedShippingRateOnly: false,
          imageUrl: "http://app.ecwid.com/default-store/00006-sq.jpg",
          fixedShippingRate: 1,
          digital: true,
          productAvailable: true,
          couponApplied: false,
          files: [
            {
              productFileId: 7215101,
              maxDownloads: 0,
              remainingDownloads: 0,
              expire: "2014-10-26 20:34:34 +0000",
              name: "myfile.jpg",
              description: "Sunflower",
              size: 54492,
              adminUrl:
                "https://app.ecwid.com/api/v3/4870020/products/37208340/files/7215101?token=123123123",
              customerUrl:
                "http://mysuperstore.ecwid.com/download/4870020/a2678e7d1d1c557c804c37e4/myfile.jpg"
            }
          ],
          selectedOptions: [
            {
              name: "Size",
              value: "Big",
              valuesArray: ["Big"],
              selections: [
                {
                  selectionTitle: "Big",
                  selectionModifier: 4,
                  selectionModifierType: "PERCENT"
                }
              ],
              type: "CHOICE"
            },
            {
              name: "Attach a file",
              type: "FILES",
              files: [
                {
                  id: 5973037,
                  name: "makfruit_ava_sunnyflower_200_200.jpg",
                  size: 54492,
                  url:
                    "https://app.ecwid.com/orderfile/4870020/5973037/54492/makfruit_ava_sunnyflower_200_200.jpg"
                }
              ]
            },
            {
              name: "Choose date",
              value: "2014-09-10",
              type: "DATE"
            },
            {
              name: "Any text",
              value: "Test text",
              type: "TEXT"
            }
          ],
          taxes: [
            {
              name: "Tax X",
              value: 7,
              total: 1.79,
              taxOnDiscountedSubtotal: 1.79,
              taxOnShipping: 0,
              includeInPrice: false
            }
          ],
          dimensions: {
            length: 34,
            width: 3,
            height: 22
          },
          couponAmount: 2.3,
          discounts: [
            {
              discountInfo: {
                value: 4,
                type: "ABS",
                base: "ON_TOTAL",
                orderTotal: 1
              },
              total: 2.19
            }
          ]
        }
      ],

      // Customer addresses
      billingPerson: {
        name: "John Smith",
        companyName: "Unreal Company",
        street: "W 3d st",
        city: "New York",
        countryCode: "US",
        countryName: "United States",
        postalCode: "10001",
        stateOrProvinceCode: "NY",
        stateOrProvinceName: "New York",
        phone: "+1234567890"
      },
      shippingPerson: {
        name: "John Smith",
        companyName: "Unreal Company",
        street: "W 3d st",
        city: "New York",
        countryCode: "US",
        countryName: "United States",
        postalCode: "10001",
        stateOrProvinceCode: "NY",
        stateOrProvinceName: "New York",
        phone: "+1234567890"
      },

      // Shipping information
      shippingOption: {
        shippingMethodName: "2nd day delivery",
        shippingRate: 10,
        estimatedTransitTime: "5",
        isPickup: false,
        pickupInstruction: ""
      },
      handlingFee: {
        name: "Wrapping",
        value: 2,
        description: "Silk paper wrapping"
      },

      // Other information
      additionalInfo: {},
      paymentParams: {
        "Company name": "Unreal Company",
        "Job position": "Manager",
        "PO number": "123abcd",
        "Buyer's full name": "John Smith"
      },
      recoveredOrderId: 223,
      recoveryEmailSentTimestamp: "2017-12-14 13:33:15 +0000",
      taxesOnShipping: [
        {
          name: "Tax X",
          value: 20,
          total: 2.86
        }
      ]
    }
  ]
};