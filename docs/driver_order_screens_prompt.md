# Prompt: Giao diá»‡n ÄÆ¡n hÃ ng TÃ i xáº¿ (Driver Order Screens) â€” Luá»“ng Hoáº¡t Ä‘á»™ng ToÃ n diá»‡n

## 1. Tá»•ng quan

XÃ¢y dá»±ng toÃ n bá»™ mÃ n hÃ¬nh liÃªn quan Ä‘áº¿n **Ä‘Æ¡n hÃ ng dÃ nh cho tÃ i xáº¿ (Role 2)** trong á»©ng dá»¥ng giao Ä‘á»“ Äƒn **FoodGo**, sá»­ dá»¥ng **Flutter** cho mobile. Pháº¡m vi bao gá»“m: danh sÃ¡ch Ä‘Æ¡n kháº£ dá»¥ng, Ä‘Æ¡n Ä‘ang giao, chi tiáº¿t Ä‘Æ¡n, lá»‹ch sá»­, thá»‘ng kÃª, vÃ­ tÃ i xáº¿, rÃºt tiá»n, thÃ´ng bÃ¡o â€” kÃ¨m **luá»“ng hoáº¡t Ä‘á»™ng chi tiáº¿t tá»«ng bÆ°á»›c** cho má»i chá»©c nÄƒng.

> **NguyÃªn táº¯c thiáº¿t káº¿:** Mobile-first, thao tÃ¡c nhanh, thÃ´ng tin tá»‘i giáº£n, hÃ nh Ä‘á»™ng rÃµ rÃ ng. TÃ i xáº¿ cáº§n nhÃ¬n tháº¥y ngay Ä‘Æ¡n cáº§n giao mÃ  khÃ´ng cáº§n scroll nhiá»u.

---

## 2. Tá»•ng há»£p API Endpoints (Backend Spring Boot â€” Thá»±c táº¿)


**Auth:** Táº¥t cáº£ API Ä‘á»u yÃªu cáº§u `Authorization: Bearer <JWT>` trong header. `driverId` / `userId` Ä‘Æ°á»£c trÃ­ch tá»« JWT token Ä‘Ã£ Ä‘Äƒng nháº­p, **khÃ´ng truyá»n trong URL**.

### 2.1. Driver Profile & Status (`/api/drivers`)

| API | Method | Body | MÃ´ táº¯ | 
|---|---|---|---|
| `/profile` | GET | â€” | Láº¥y thÃ´ng tin há»“ sÆ¡ tÃ i xáº¿ |
| `/profile` | PUT | `DeliveryProfileRequest` | Cáº­p nháº­t há»“ sÆ¡ (há» tÃªn, SÄT, áº£nh) |
| `/status` | PUT | `DeliveryStatusRequest` | Toggle online/offline (báº­t pháº£i gá»­i GPS) |
| `/vehicle` | PUT | `DeliveryVehicleRequest` | Cáº­p nháº­t thÃ´ng tin phÆ°Æ¡ng tiá»‡n |
| `/location` | POST | `DeliveryLocationUpdateRequest` | Gá»­i vá»‹ trÃ­ GPS lÃªn Realtime Database |

### 2.2. Delivery Orders (`/api/drivers/orders`)

| API | Method | Body / Params | MÃ´ táº¯ |
|---|---|---|---|
| `/available` | GET | â€” | Danh sÃ¡ch Ä‘Æ¡n chá» tÃ i xáº¿ nháº­n (status=1, driverId=null) |
| `/{id}/accept` | POST | â€” | Nháº­n Ä‘Æ¡n hÃ ng (tá»± chá»n) |
| `/{id}/decline` | POST | â€” | Tá»« chá»‘i Ä‘Æ¡n hÃ ng (tá»± chá»n) |
| `/{id}/respond` | POST | `{ "action": "accept" \| "decline" }` | Accept/decline khi há»‡ thá»‘ng gÃ¡n tá»± Ä‘á»™ng |
| `/current` | GET | â€” | ÄÆ¡n hÃ ng Ä‘ang giao hiá»‡n táº¯ (status=2, driverId=current) |
| `/active` | GET | â—” | Táº¥t cáº£ Ä‘Æ¡n Ä‘ang hoáº¡t Ä‘á»™ng (status=2) |
| `/history` | GET | â€ţ | Lá»‹ch sá»­ Ä‘Æ¡n Ä‘Ã£ giao (status=3) |
| `/{id}/status` | PUT | `{ "status": 3 \| 4 }` | Cáº­p nháº­t tráº¡ng thÃ¡i: 3=HoÃ n thÃ nh, 4=Há»§y |

### 2.3. Notifications (`/api/drivers/notifications`)

| API | Method | Params | MÃ´ táº¯ |
|---|---|---|---|
| `?type=11\|12\|13` | GET | `?type=11` (tÃ¹y chá»n) | Danh sÃ¡ch thÃ´ng bÃ¡o |
| `/{id}/read` | PUT | â€ţ | ÄÃ¡nh dáº¥u 1 thÃ´ng bÃ¡o Ä‘Ã£ Ä‘á»c |
| `/read-all` | PUT | â€ţ | ÄÃ¡nh dáº¥u táº¥t cáº£ Ä‘Ã£ Ä‘á»c |
| `/{id}` | DELETE | â€ţ | XÃ³a 1 thÃ´ng bÃ¡o |

### 2.4. Wallet (`/api/drivers`)

| API | Method | Body / Params | MÃ´ táº¯ |
|---|---|---|---|
| `/wallet` | GET | â€ţ | ThÃ´ng tin vÃ­ (sá»‘ dÆ°, thu nháº­p, Ä‘Ã£ rÃºt, chá») |
| `/transactions` | GET | `?page=0&size=20` | Lá»‹ch sá»­ giao dá»‹ch (cÃ³ phÃ¢n trang) |
| `/withdraw` | POST | `{ "amount": 50000 }` | YÃªu cáº§u rÃºt tiá»n |

---

## 3. Chi tiáº¿t DTO â€" Táº¥t cáº£ objects tráº£ vá» tá»« API

### 3.1. DeliveryOrderDTO (ÄÆ¡n hÃ ng giao hÃ ng)

```dart
class DeliveryOrderDTO {
  String id;                    // ID Ä‘Æ¡n hÃ ng
  String userId;                // ID ngÆ°á»i Ä‘áº·t
  String storeId;               // ID cá»­a hÃ ng
  String storeName;             // TÃªn cá»­a hÃ ng
  String storeAddress;          // Äá»‹a chá»‰ cá»­a hÃ ng
  Double storeLat;               // VÄ© Ä‘á»™ cá»­a hÃ ng
  Double storeLng;              // Kinh Ä‘á»™ cá»­a hÃ ng
  List<OrderItemData> items;     // Danh sÃ¡ch mÃ³n Äƒn
  Double totalAmount;            // Tá»•ng tiá»n Ä‘Æ¡n (VND)
  Double deliveryFee;            // PhÃ­ giao hÃ ng (VND) â€" THU NHáº¬P tÃ i xáº¿
  Integer status;                // 0=Chá» xÃ¡c nháº­n, 1=Äang chuáº©n bá»‹, 2=Äang giao, 3=HoÃ n thÃ nh, 4=ÄÃ£ há»§y
  Integer paymentStatus;         // 1=ChÆ°a TT, 2=ÄÃ£ TT
  String deliveryAddress;        // Äá»‹a chá»‰ giao hÃ ng
  Double deliveryLat;            // VÄ© Ä‘á»™ giao hÃ ng
  Double deliveryLng;           // Kinh Ä‘á»™ giao hÃ ng
  int paymentMethod;            // 1=Tiá»n máº·t, 2=MoMo, 3=Zalo, 4=VNPay
  String driverId;              // ID tÃ i xáº¿ nháº­n Ä‘Æ¡n
  String driverName;            // TÃªn tÃ i xáº¿
  String driverPhone;           // SÄT tÃ i xáº¿
  String vehiclePlate;          // Biá»ƒn sá»‘ xe
  Instant createdAt;            // Thá»i gian táº¡o Ä‘Æ¡n
  Instant updatedAt;            // Thá»i gian cáº­p nháº­t gáº§n nháº¥t
  String note;                  // Ghi chÃº Ä‘Æ¡n hÃ ng

  // Nested: OrderItemData
  static class OrderItemData {
    String foodId;
    String name;                 // TÃªn mÃ³n
    Double price;                // ÄÆ¡n giÃ¡
    Integer quantity;            // Sá»‘ lÆ°á»£ng
    String imageUrl;             // URL áº£nh
    List<OptionData> options;    // CÃ¡c tÃ¹y chá»n
  }

  // Nested: OptionData
  static class OptionData {
    String name;                 // TÃªn tÃ¹y chá»n
    Double price;                // GiÃ¡ tÃ¹y chá»n
  }
}
```

### 3.2. NotificationDTO (ThÃ´ng bÃ¡o)

```dart
class NotificationDTO {
  String id;                     // ID thÃ´ng bÃ¡o
  Integer type;                  // 11=YÃªu cáº§u nháº­n Ä‘Æ¡n, 12=ThÃ´ng bÃ¡o giao, 13=ÄÆ¡n bá»‹ tÃ i xáº¿ khÃ¡c nháº­n
  String title;                  // TiÃªu Ä‘á»
  String body;                   // Ná»™i dung (LÆ¯U Ã: field lÃ "body", KHÃ”NG pháº£i "message")
  String orderId;                // ID Ä‘Æ¡n hÃ ng liÃªn quan
  String referenceId;            // Tham chiáº¿u (thÆ°á»ng = orderId)
  Boolean isRead;                // ÄÃ£ Ä‘á»c chÆ°a
  String imageUrl;              // URL hÃ¬nh áº£nh kÃ¨m theo
  Instant createdAt;             // Thá»i gian táº¡o
}
```

### 3.3. WalletDTO (VÃ­ tÃ i xáº¿)

```dart
class WalletDTO {
  String id;                     // ID vÃ­
  String userId;                // ID chá»§ vÃ­ (= driverId)
  String role;                  // Vai trÃ² ("driver")
  Double balance;               // Sá»‘ dÆ° kháº£ dá»¥ng (VND)
  Double totalEarned;            // Tá»•ng thu nháº­p (VND)
  Double totalWithdrawn;         // Tá»•ng Ä‘Ã£ rÃºt (VND)
  Double pendingBalance;         // Sá»‘ dÆ° chá» xá»­ lÃ½ (VND)
  String bankName;               // TÃªn ngÃ¢n hÃ ng thá»¥ hÆ°á»Ÿng
  String bankAccountNumber;      // Sá»‘ tÃ i khoáº£n
  String bankAccountName;         // TÃªn ngÆ°á»i thá»¥ hÆ°á»Ÿng
  Instant createdAt;            // Thá»i gian táº¡o vÃ­
  Instant updatedAt;             // Thá»i gian cáº­p nháº­t gáº§n nháº¥t
}
```

### 3.4. TransactionDTO (Giao dá»‹ch)

```dart
class TransactionDTO {
  String id;                     // ID giao dá»‹ch
  String walletId;              // ID vÃ­ liÃªn quan
  String userId;                // ID ngÆ°á»i thá»±c hiá»‡n
  Integer type;                  // 1=delivery_income, 2=withdrawal, 3=refund
  Double amount;                 // Sá»‘ tiá»n giao dá»‹ch (VND)
  Double fee;                   // PhÃ­ giao dá»‹ch (VND)
  Double netAmount;              // Sá»‘ tiá»n thá»±c nháº­n = amount - fee
  String description;           // MÃ´ táº¯ giao dá»‹ch
  String orderId;               // ID Ä‘Æ¡n hÃ ng liÃªn quan (náº¿u lÃ  delivery_income)
  Integer status;               // 0=pending, 1=completed, 2=failed
  Instant createdAt;            // Thá»i gian táº¡o
}
```

### 3.5. DeliveryProfileDTO (Há»“ sÆ¡ tÃ i xáº¿)

```dart
class DeliveryProfileDTO {
  String userId;                 // ID tÃ i xáº¿
  String fullName;               // Há» tÃªn Ä‘áº§y Ä‘á»§
  String phoneNumber;            // SÄT
  String photoUrl;              // URL áº£nh Ä‘áº¡i diá»‡n
  Boolean isActive;              // Tráº¡ng thÃ¡i online/offline
  String vehiclePlate;          // Biá»ƒn sá»‘ xe
  String vehicleType;            // Loáº¡i xe: MOTORCYCLE, BICYCLE, CAR
  String driverLicense;         // Giáº¥y phÃ©p lÃ¡i xe
  Double rating;                // Äiá»ƒm Ä‘Ã¡nh giÃ¡ (0.0 - 5.0)
  Integer totalTrips;            // Tá»•ng sá»‘ chuyáº¿n Ä‘Ã£ giao
  Integer todayTrips;            // Sá»‘ chuyáº¿n hÃ´m nay
  Double todayEarnings;         // Thu nháº­p hÃ´m nay (VND)
  Instant createdAt;            // Thá»i gian táº¡o
  Instant updatedAt;            // Thá»i gian cáº­p nháº­t
}
```

### 3.6. Request DTOs (Body gá»­i lÃªn)

```dart
// PUT /api/drivers/status â€" Báº­t online
class DeliveryStatusRequest {
  Boolean isActive;     // true = online
  Double lat;           // Báº®T BUá»˜C khi isActive=true
  Double lng;           // Báº®T BUá»˜C khi isActive=true
  Double heading;       // HÆ°á»›ng di chuyá»ƒn (0-360 Ä‘á»™)
  Double speed;         // Tá»‘c Ä‘á»™ (km/h)
}

// PUT /api/drivers/status â€" Táº¯t offline
class DeliveryStatusRequest {
  Boolean isActive;     // false = offline (chá»‰ cáº§n field nÃ y)
}

// POST /api/drivers/location
class DeliveryLocationUpdateRequest {
  Double lat;           // Báº®T BUá»˜C
  Double lng;           // Báº®T BUá»˜C
  Double heading;       // HÆ°á»›ng (0-360)
  Double speed;         // Tá»‘c Ä‘á»™ (km/h)
}

// POST /api/drivers/orders/{id}/respond
class DeliveryRespondRequest {
  String action;       // "accept" hoáº·c "decline"
}

// PUT /api/drivers/orders/{id}/status
class DeliveryOrderStatusRequest {
  Integer status;       // 3=HoÃ  n thÃ  nhh, 4=Há»§y
}

// POST /api/drivers/withdraw
class WithdrawRequest {
  Double amount;        // Sá»‘ tiá»  n rÃºt (VND), tá»‘i thiá»ƒu 50000
}
```

---

## 4. MÃ£ tráº¡ng thÃ¡i Ä‘Æ¡n hÃ  ng

| GiÃ¡ trá»‹ | Label | MÃ  u sáº¯c | MÃ´ táº¯ |
|---|---|---|---|
| 0 | Chá»‹ xÃ¡c nháº­n | Cam | Cá»­a hÃ  ng chÆ°a xÃ¡c nháº­n |
| 1 | Äang chuáº©n bá»‹ | VÃ ng | Cá»­a hÃ  ng Ä‘ang chuáº©n bá»‹ |
| 2 | Äang giao | Xanh dÆ°Æ¡ng | TÃ  i xáº¿ Ä‘ang giao |
| 3 | HoÃ  n thÃ  nhh | Xanh lÃ¡ | Giao thÃ  nh cÃ´ng â€" **táº¡o thu nháº¡p** |
| 4 | ÄÃ£ há»§y | Äá»� | ÄÆ¡n bá»‹ há»§y |

---

## 5. MÃ£ loáº¡i thÃ´ng bÃ¡o (Notification type)

| GiÃ¡ trá»‹ | Label | MÃ´ táº¯ |
|---|---|---|
| 11 | YÃªu cáº§u nháº­n Ä‘Æ¡n | Há»‡ thá»‘ng gÃ¡n Ä‘Æ¡n tá»± Ä‘á»™ng, cáº§n tÃ i xáº¿ pháº£n há»“i |
| 12 | ThÃ´ng bÃ¡o giao hÃ  ng | Cáº­p nháº­t tráº¡ng thÃ¡i Ä‘Æ¡n |
| 13 | ÄÆ¡n bá»‹ tÃ i xáº¿ khÃ¡c nháº­n | ÄÆ¡n Ä‘Ã£ Ä‘Æ°á»£c tÃ i xáº¿ khÃ¡c nháº­n (409 conflict) |

---

## 6. MÃ£ loáº¡i giao dá»‹ch (Transaction type)

| GiÃ¡ trá»‹ | Label | MÃ´ táº¯ |
|---|---|---|
| 1 | delivery_income | Thu nháº­p tá»« giao hÃ  ng |
| 2 | withdrawal | RÃºt tiá»  n |
| 3 | refund | HoÃ  n tiá»  n |

---

## 7. Luá»“ng hoáº¡t Ä‘á»™ng chi tiáº¿t tá»«ng chá»©c nÄƒng

### 7.1. Luá»“ng 1: Toggle Online / Offline

```
[START] â†’ TÃ  i xáº¿ báº­t/táº¯t toggle Online
    â”‚
    â”œâ”€â–º Báº¬T ONLINE (isActive = true)
    â”‚   â”‚
    â”‚   â‘  App kiá»ƒm tra GPS permission
    â”‚      â”œâ”€â–º CHÆ¯A CÃ“ â†’ Hiá»‡n dialog xin quyá»  n truy cáº­p vá»‹ trÃ­
    â”‚      â”‚      â”œâ”€â–º User GRANT â†’ láº¥y GPS â†’ bÆ°á»›c â‘¡
    â”‚      â”‚      â””â”€â–º User DENY â†’ snackbar "Cáº§n quyá»  n GPS Ä‘á»ƒ nháº­n Ä‘Æ¡n"
    â”‚      â””â”€â–º ÄÃƒ CÃ“ â†’ bÆ°á»›c â‘¡
    â”‚   â”‚
    â”‚   â‘¡ Láº¥y tá»  a Ä‘á»™ GPS hiá»‡n táº¯ (lat, lng, heading, speed)
    â”‚   â”‚
    â”‚   â‘¢ Gá»­i PUT /api/drivers/status
    â”‚      Body: { "isActive": true, "lat": 10.85, "lng": 106.79, "heading": 90, "speed": 30 }
    â”‚      â”œâ”€â–º SUCCESS (200) â†’ bÆ°á»›c â‘£
    â”‚      â””â”€â–º FAIL â†’ snackbar lá»—i + rollback toggle
    â”‚   â”‚
    â”‚   â‘£ Backend cáº­p nháº­t DriverProfile.isActive = true
    â”‚      Backend cáº­p nháº­t DriverLocation trong Realtime Database
    â”‚   â”‚
    â”‚   â‘¤ App cáº­p nháº­t UI: toggle ON, mÃ  u xanh lÃ¡, hiá»‡n icon online
    â”‚      â”œâ”€â–º Báº¯t Ä‘áº§u GPS realtime service (cáº­p nháº­t má»—i 5-10s)
    â”‚      â”‚    POST /api/drivers/location
    â”‚      â”‚    Body: { "lat": ..., "lng": ..., "heading": ..., "speed": ... }
    â”‚      â”œâ”€â–º Báº¯t Ä‘áº§u polling Ä‘Æ¡n má»›i má»—i 10-15s
    â”‚      â”‚    GET /api/drivers/orders/available
    â”‚      â””â”€â–º Hiá»‡n snackbar "Báº¡n Ä‘Ã£ online. Sáºµn sÃ  ng nháº­n Ä‘Æ¡n!"
    â”‚
    â””â”€â–º Táº®T ONLINE (isActive = false)
        â”‚
        â‘  Gá»­i PUT /api/drivers/status
           Body: { "isActive": false }
           â”œâ”€â–º SUCCESS (200) â†’ bÆ°á»›c â‘¡
           â””â”€â–º FAIL â†’ snackbar lá»—i + rollback toggle
        â”‚
        â‘¡ Backend cáº­p nháº­t DriverProfile.isActive = false
           Backend cáº­p nháº­t DriverLocation.isActive = false trong Realtime DB
        â”‚
        â‘¢ App cáº­p nháº­t UI: toggle OFF, mÃ  u xÃ¡m, hiá»‡n icon offline
           â”œâ”€â–º Dá»«ng GPS realtime service
           â”œâ”€â–º Dá»«ng polling Ä‘Æ¡n hÃ  ng
           â””â”€â–º Snackbar "Báº¡n Ä‘Ã£ offline. Sáº½ khÃ´ng nháº­n Ä‘Æ°á»£c Ä‘Æ¡n má»›i."
```

**LÆ°u Ã½:**
- Khi online, GPS cháº¡y á»Ÿ background dÃ¹ app minimize (dÃ¹ng `flutter_background_service`).
- Náº¿u GPS khÃ´ng láº¥y Ä‘Æ°á»£c location trong 10 giÃ¢y, váº«n cho online nhÃ¹ng cáº£nh bÃ¡o.
- Khi app bá»‹ kill, GPS background váº«n cháº¡y náº¿u user cho phÃ©p.
- **Body khi báº­t online**: `{ isActive: true, lat, lng, heading, speed }` â€" **KHÃ”NG pháº£i** `{ isActive: true }` riÃªng ráº½.

---

### 7.2. Luá»“ng 2: Nháº­n Ä‘Æ¡n hÃ  ng (Manual â€" tá»± chá»n)

```
[START] â†’ TÃ  i xáº¿ vÃ  o mÃ  n "ÄÆ¡n kháº£ dá»¥ng" (Available Orders)
    â”‚
    â‘  Load danh sÃ¡ch: GET /api/drivers/orders/available
    â”‚   â”œâ”€â–º SUCCESS â†’ Hiá»ƒn thá»‹ ListView cÃ¡c Ä‘Æ¡n
    â”‚   â”‚       â”œâ”€â–º CÃ³ Ä‘Æ¡n â†’ render OrderCard vá»›i nÃºt "Nháº­n Ä‘Æ¡n"
    â”‚   â”‚       â””â”€â–º KhÃ´ng Ä‘Æ¡n â†’ Empty state + icon xe + "KhÃ´ng cÃ³ Ä‘Æ¡n hÃ  ng nÃ o"
    â”‚   â””â”€â–º FAIL â†’ Error state + nÃºt "Thá»­ láº¡i"
    â”‚
    â‘¡ TÃ  i xáº¿ nháº¥n "Nháº­n Ä‘Æ¡n" trÃªn card Ä‘Æ¡n X
    â”‚
    â‘¢ Hiá»‡n dialog xÃ¡c nháº­n:
       "Báº¡n cÃ³ cháº¯c nháº­n Ä‘Æ¡n #{mÃ£ rÃºt gá»  n 6 kÃ½ tá»±} khÃ´ng?"
       Ná»™i dung: "{storeName} - PhÃ­: {deliveryFee}Ä‘"
       â”œâ”€â–º "Há»§y" â†’ ÄÃ³ng dialog
       â””â”€â–º "XÃ¡c nháº­n" â†’ bÆ°á»›c â‘£
    â”‚
    â‘£ Gá»­i POST /api/drivers/orders/{id}/accept
       â”œâ”€â–º SUCCESS (200) â†’ bÆ°á»›c â‘¤
       â”œâ”€â–º 409 CONFLICT â†’ "ÄÆ¡n hÃ  ng Ä‘Ã£ Ä‘Æ°á»£c tÃ  i xáº¿ khÃ¡c nháº­n."
       â”‚      Hiá»‡n dialog â†’ xÃ³a card vá»›i animation slide-out
       â”œâ”€â–º 404 NOT_FOUND â†’ "KhÃ´ng tÃ¬m tháº¥y Ä‘Æ¡n hÃ  ng."
       â””â”€â–º 403 FORBIDDEN â†’ "Báº¡n khÃ´ng cÃ³ quyá»  n thá»±c hiá»‡n."
    â”‚
    â‘¤ Backend thá»±c hiá»‡n cáº­p nháº­t Ä‘Æ¡n hÃ  ng:
       - driverId = currentUser, driverName, driverPhone, vehiclePlate
       - status = 1 (Äang chuáº©n bá»‹)
       - Táº¡o Notification cho tÃ  i xáº¿
    â”‚
    â‘¥ App nháº­n response (DeliveryOrderDTO Ä‘Ã£ Ä‘Æ°á»£c cáº­p nháº­t driver info)
    â”‚
    â‘¦ Hiá»‡n dialog thÃ  nh cÃ´ng:
       "Báº¡n Ä‘Ã£ nháº­n Ä‘Æ¡n thÃ  nh cÃ´ng!"
       "ÄÆ¡n: #{mÃ£} tá»« {storeName}"
       "PhÃ­ giao: {deliveryFee}Ä‘"
       â”œâ”€â–º "Xem chi tiáº¿t" â†’ Ä‘iá»ƒu hÆ°á»›ng OrderDetailScreen(id)
       â””â”€â–º "ÄÃ³ng" â†’ á»Ÿ láº¡i trang, refresh danh sÃ¡ch
    â”‚
    â‘§ ÄÆ¡n biáº¿n máº¥t khá»  i danh sÃ¡ch "Kháº£ dá»¥ng"
       vÃ¬ driverId Ä‘Ã£ Ä‘Æ°á»£c gÃ¡n, khÃ´ng cÃ²n thá»a driverId == null
```

---

### 7.3. Luá»“ng 3: Há»‡ thá»‘ng gÃ¡n Ä‘Æ¡n tá»± Ä‘á»™ng (Auto-assign)

```
[START] â†’ Backend tá»± Ä‘á»™ng gÃ¡n Ä‘Æ¡n cho tÃ  i xáº¿
    â”‚
    â‘  Backend ghi Notification cho tÃ  i xáº¿, type=11
       Backend gá»­i push notification Ä‘áº¿n app tÃ  i xáº¿
    â”‚
    â”œâ”€â–º APP ÄANG Má»ž (foreground)
    â”‚   â”‚
    â”‚   â‘¡ WebSocket nháº­n thÃ´ng bÃ¡o â†’ kiá»ƒm tra type=11
    â”‚      Hiá»‡n custom in-app banner / bottom sheet Ä‘áº·t trÃªn cÃ¹ng mÃ  n
    â”‚      Ná»™i dung:
    â”‚        "Báº¡n cÃ³ Ä‘Æ¡n hÃ  ng má»›i!"
    â”‚        "{storeName}"
    â”‚        "PhÃ­ giao: {deliveryFee}Ä‘"
    â”‚        "{deliveryAddress}" (rÃºt gá»  n)
    â”‚      Pháº¡t Ã¢m thanh thÃ´ng bÃ¡o (audioplayers)
    â”‚      Hiá»‡u á»©ng vibration (HapticFeedback.heavyImpact())
    â”‚      â”œâ”€â–º "Nháº­n Ä‘Æ¡n" â†’ bÆ°á»›c â‘¢
    â”‚      â””â”€â–º "Tá»« chá»‘i" â†’ bÆ°á»›c â‘¤
    â”‚   â”‚
    â”‚   â‘¢ TÃ  i xáº¿ nháº¥n "Nháº­n Ä‘Æ¡n"
    â”‚   â”‚
    â”‚   â‘£ Gá»­i POST /api/drivers/orders/{id}/respond
    â”‚      Body: { "action": "accept" }
    â”‚      â”œâ”€â–º SUCCESS (200) â†’ Dialog thÃ  nh cÃ´ng â†’ Ä‘iá»ƒu hÆ°á»›ng OrderDetail
    â”‚      â”‚       Ná»™i dung: "ÄÃ£ nháº­n Ä‘Æ¡n thÃ  nh cÃ´ng! Äi giao ngay thÃ´i."
    â”‚      â”œâ”€â–º 409 CONFLICT â†’ "ÄÆ¡n Ä‘Ã£ Ä‘Æ°á»£c tÃ  i xáº¿ khÃ¡c nháº¡c."
    â”‚      â”‚       ÄÃ³ng banner â†’ snackbar
    â”‚      â””â”€â–º 403 FORBIDDEN â†’ "YÃªu cáº§u Ä‘Ã£ háº¿t háº¡n."
    â”‚   â”‚
    â”‚   â‘¤ TÃ  i xáº¿ nháº¥n "Tá»« chá»‘i"
    â”‚   â”‚
    â”‚   â‘¥ Gá»­i POST /api/drivers/orders/{id}/respond
    â”‚      Body: { "action": "decline" }
    â”‚      â”œâ”€â–º SUCCESS (200) â†’ ÄÃ³ng banner â†’ Ä‘Æ¡n biáº¿n máº¥t
    â”‚      â””â”€â–º FAIL â†’ Snackbar lá»—i
    â”‚
    â””â”€â–º APP ÄANG ÄÃ“NG HOáº¶C BACKGROUND
        â”‚
        â‘¡ WebSocket hiá»‡n thÃ´ng bÃ¡o (native OS banner)
           Title: "ÄÆ¡n hÃ  ng má»›i cáº§n giao!"
           Body: "{storeName} - PhÃ­: {deliveryFee}Ä‘"
           â”œâ”€â–º User tap â†’ Má»Ÿ app â†’ Ä‘iá»ƒu hÆ°á»›ng OrderDetailScreen(id)
           â”‚      Hiá»‡n dialog: "Báº¡n cÃ³ nháº­n Ä‘Æ¡n nÃ o khÃ´ng?"
           â”‚      â”œâ”€â–º "Nháº­n" â†’ POST /respond action=accept
           â”‚      â””â”€â–º "Tá»« chá»‘i" â†’ POST /respond action=decline
           â””â”€â–º User dismiss notification â†’ App váº«n Ä‘Ã³ng
              Notification lÆ°u trong backend â†’ Ä‘á»  c sau á»Ÿ mÃ  n Notifications
```

---

### 7.4. Luá»“ng 4: Giao Ä‘Æ¡n hÃ  ng (Delivery Flow â€" Chi tiáº¿t theo tá»«ng tráº¡ng thÃ¡i)

#### 4A. Status 1 â†’ 2: XÃ¡c nháº­n Ä‘Ã£ láº¥y hÃ  ng tá»« cá»­a hÃ  ng

```
[START] â†’ TÃ  i xáº¿ nháº­n Ä‘Æ¡n thÃ  nh cÃ´ng, Ä‘ang á»Ÿ OrderDetailScreen (status=1)
    â”‚
    â‘  Hiá»ƒn thá»‹ OrderDetailScreen:
       - MÃ£ Ä‘Æ¡n (6 kÃ½ tá»± cuá»‘i), thÃ´ng tin cá»­a hÃ  ng, thÃ´ng tin ngÆ°á»  i nháº­n
       - NÃºt "ÄÃ£ láº¥y hÃ  ng" (PRIMARY, mÃ  u xanh lÃ¡, ná»•i báº¤t)
       - NÃºt "Tá»« chá»‘i Ä‘Æ¡n" (secondary, mÃ  u Ä‘á»  nháº¡t)
       - NÃºt "Chá»‰ Ä‘Æ°á» ng Ä‘áº¿n cá»­a hÃ  ng" (icon báº£n Ä‘á»“)
       - NÃºt "Gá»  i cá»­a hÃ  ng" (icon Ä‘iá»‡n thoáº¡i) â€" náº¿u backend cung cáº¥p
    â”‚
    â‘¡ TÃ  i xáº¿ Ä‘áº¿n cá»­a hÃ  ng â†’ nháº¥n "ÄÃ£ láº¥y hÃ  ng"
    â”‚
    â‘¢ Hiá»‡n dialog xÃ¡c nháº­n:
       "XÃ¡c nháº­n Ä‘Ã£ láº¥y hÃ  ng tá»« {storeName}?"
       â”œâ”€â–º "Há»§y" â†’ ÄÃ³ng dialog
       â””â”€â–º "XÃ¡c nháº­n" â†’ bÆ°á»›c â‘£
    â”‚
    â‘£ Gá»­i PUT /api/drivers/orders/{id}/status
       Body: { "status": 2 }
       â”œâ”€â–º SUCCESS (200) â†’ bÆ°á»›c â‘¤
       â”œâ”€â–º 403 FORBIDDEN â†’ "Báº¡n khÃ´ng pháº£i tÃ  i xáº¿ cá»§a Ä‘Æ¡n nÃ o."
       â””â”€â–º 400 BAD_REQUEST â†’ "Tráº¡ng thÃ¡i khÃ´ng há»£p lá»‡."
    â”‚
    â‘¤ Backend cáº­p nháº­t: status = 2 (Äang giao)
    â”‚
    â‘¥ App cáº­p nháº­t UI:
       - Status badge: "Äang giao" (mÃ  u xanh dÆ°Æ¡ng)
       - NÃºt hÃ  nh Ä‘á»™ng: "ÄÃ£ giao hÃ  ng" (PRIMARY, xanh lÃ¡)
       - NÃºt "BÃ¡o sá»± cá»" (secondary, cam)
       - NÃºt "Chá»‰ Ä‘Æ°á» ng Ä‘áº¿n ngÆ°á»  i nháº­n" (icon báº£n Ä‘á»“)
       - NÃºt "Gá»  i ngÆ°á»  i nháº­n" (icon Ä‘iá»‡n thoáº¡i)
       - Báº­t GPS tracking realtime cho phÃ©p ngÆ°á»  i nháº­n xem vá»‹ trÃ­
       - Snackbar: "ÄÃ£ xÃ¡c nháº­n láº¥y hÃ  ng. Báº¯t Ä‘áº§u giao!"
```

#### 4B. Status 2 â†’ 3: XÃ¡c nháº­n Ä‘Ã£ giao hÃ  ng thÃ  nh cÃ´ng

```
[START] â†’ TÃ  i xáº¿ Ä‘áº¿n Ä‘á»‹a chá»‰ giao, status=2
    â”‚
    â‘  Hiá»ƒn thá»‹ OrderDetailScreen:
       - MÃ£ Ä‘Æ¡n (6 kÃ½ tá»± cuá»‘i), thÃ´ng tin cá»­a hÃ  ng, thÃ´ng tin ngÆ°á»  i nháº­n
       - PhÃ­ giao hÃ  ng (deliveryFee) â€" hiá»ƒn thá»‹ ráº¥t lá»›n, mÃ  u xanh lÃ¡, icon â‚«
       - NÃºt "ÄÃ£ giao hÃ  ng" (PRIMARY, mÃ  u xanh lÃ¡, Ná»”I Báº¬T NHáº¤T)
       - NÃºt "BÃ¡o sá»± cá»" (secondary, cam)
       - NÃºt "Chá»‰ Ä‘Æ°á» ng" (icon báº£n Ä‘á») â†’ Google Maps
       - NÃºt "Gá»  i ngÆ°á»  i nháº­n" (icon Ä‘iá»‡n thoáº¡i)
    â”‚
    â‘¡ TÃ  i xáº¿ giao hÃ  ng xong â†’ nháº¥n "ÄÃ£ giao hÃ  ng"
    â”‚
    â‘¢ Hiá»‡n dialog xÃ¡c nháº­n:
       "XÃ¡c nháº­n Ä‘Ã£ giao hÃ  ng cho {receiverName}?"
       "Äá»‹a chá»‰: {deliveryAddress}"
       â”œâ”€â–º "Há»§y" â†’ ÄÃ³ng dialog
       â””â”€â–º "XÃ¡c nháº­n" â†’ bÆ°á»›c â‘£
    â”‚
    â‘£ Gá»­i PUT /api/drivers/orders/{id}/status
       Body: { "status": 3 }
       â”œâ”€â–º SUCCESS (200) â†’ bÆ°á»›c â‘¤
       â”œâ”€â–º 403 FORBIDDEN â†’ "Báº¡n khÃ´ng pháº£i tÃ  i xáº¿ cá»§a Ä‘Æ¡n nÃ o."
       â””â”€â–º 400 BAD_REQUEST â†’ "Tráº¡ng thÃ¡i khÃ´ng há»£p lá»‡."
    â”‚
    â‘¤ Backend tá»± Ä‘á»™ng:
       - status = 3 (HoÃ  n thÃ  nhh)
       - Táº¡o TransactionDTO: type=1 (delivery_income), amount=deliveryFee
       - Cáº­p nháº­t WalletDTO: balance += deliveryFee, totalEarned += deliveryFee
       - Dá»«ng GPS tracking realtime
    â”‚
    â‘¥ App cáº­p nháº­t UI:
       - Status badge: "HoÃ  n thÃ  nhh" (mÃ  u xanh lÃ¡)
       - NÃºt hÃ  nh Ä‘á»™ng: disabled, hiá»ƒn thá»‹ "ÄÃ£ hoÃ  n thÃ  nhh"
       - Dá»«ng GPS service
       - Hiá»‡n dialog chÃºc má»«ng:
         "ChÃºc má»«ng! Báº¡n Ä‘Ã£ hoÃ  n thÃ  nhh Ä‘Æ¡n hÃ  ng."
         "Thu nháº­p: +{deliveryFee}Ä‘"
         "Tá»•ng sá»‘ dÆ°: {newBalance}Ä‘"
         â”œâ”€â–º "Nháº­n Ä‘Æ¡n má»›i" â†’ Ä‘iá»¼u hÆ°á»›ng AvailableOrdersScreen
         â””â”€â–º "ÄÃ³ng" â†’ Ä‘iá»¼u hÆ°á»›ng OrdersScreen (tab "Äang giao")
       - Snackbar: "Cáº£m Æ¡n báº¡n! +{deliveryFee}Ä‘ Ä‘Ã£ Ä‘Æ°á»£c cá»™ng vào vÃ­."
```

#### 4C. Status 2 â†’ 4: BÃ¡o sá»± cá»" / Há»§y Ä‘Æ¡n khi Ä‘ang giao

```
[START] â†’ TÃ  i xáº¿ gáº·p sá»± cá»" khi Ä‘ang giao, status=2
    â”‚
    â‘  TÃ  i xáº¿ nháº¥n "BÃ¡o sá»± cá»"
    â”‚
    â‘¡ Hiá»‡n bottom sheet vá»›i danh sÃ¡ch lÃ½ do:
       - "KhÃ´ng tÃ¬m tháº¥y Ä‘á»‹a chá»‰ giao hÃ  ng"
       - "KhÃ¡ch hÃ ng khÃ´ng nghe máy"
       - "Cá»­a hÃ  ng Ä‘Ã³ng cá»­a / háº¿t hÃ  ng"
       - "Táº¯c Ä‘Æ°á» ng, giao trá»"
       - "LÃ½ do khÃ¡c" â†’ TextField nháº­p thÃªm
       â”œâ”€â–º "Há»§y" â†’ ÄÃ³ng bottom sheet
       â””â”€â–º "Tiáº¿p tá»¥c" â†’ bÆ°á»›c â‘¢
    â”‚
    â‘¢ Hiá»‡n dialog xÃ¡c nháº­n:
       "XÃ¡c nháº­n há»§y Ä‘Æ¡n hÃ  ng #{mÃ£}?"
       "LÃ½ do: {selectedReason}"
       â”œâ”€â–º "Há»§y" â†’ ÄÃ³ng dialog
       â””â”€â–º "XÃ¡c nháº­n há»§y" â†’ bÆ°á»›c â‘£
    â”‚
    â‘£ Gá»­i PUT /api/drivers/orders/{id}/status
       Body: { "status": 4 }
       â”œâ”€â–º SUCCESS (200) â†’ bÆ°á»›c â‘¤
       â””â”€â–º FAIL â†’ Snackbar lá»—i
    â”‚
    â‘¤ Backend:
       - status = 4 (ÄÃ£ há»§y)
       - XÃ³a driverId khá»  i order (reset Ä‘á»ƒ há»‡ thá»‘ng gÃ¡n láº¡i)
       - Táº¡o Notification type=13 cho cÃ¡c tÃ  i xáº¿ khÃ¡c
    â”‚
    â‘¥ App cáº­p nháº­t UI:
       - Snackbar: "ÄÃ£ bÃ¡o cÃ¡o sá»± cá»". ÄÆ¡n hÃ  ng Ä‘Ã£ Ä‘Æ°á»£c há»§y."
       - Äiá»¼u hÆ°á»›ng vá»  OrdersScreen
       - Náº¿u Ä‘ang á»Ÿ OrderDetail â†’ pop vá»  danh sÃ¡ch
```

---

### 7.5. Luá»“ng 5: Tá»« chá»‘i Ä‘Æ¡n hÃ  ng (Decline â€" Manual)

```
[START] â†’ TÃ  i xáº¿ xem Ä‘Æ¡n kháº£ dá»¥ng, quyáº¿t Ä‘á»‹nh khÃ´ng nháº­n
    â”‚
    â‘  TÃ  i xáº¿ nháº¥n "Tá»« chá»‘i" trÃªn OrderCard
    â”‚
    â‘¡ Hiá»‡n dialog nhá»  :
       "Báº¡n cÃ³ cháº¯c tá»« chá»‘i Ä‘Æ¡n hÃ  ng #{mÃ£}?"
       â”œâ”€â–º "Há»§y" â†’ ÄÃ³ng dialog
       â””â”€â–º "XÃ¡c nháº­n tá»« chá»‘i" â†’ bÆ°á»›c â‘¢
    â”‚
    â‘¢ Gá»­i POST /api/drivers/orders/{id}/decline
       â”œâ”€â–º SUCCESS (200) â†’ bÆ°á»›c â‘£
       â””â”€â–º FAIL â†’ Snackbar lá»—i
    â”‚
    â‘£ Backend ghi decline log (khÃ´ng gÃ¡n cho tÃ  i xáº¿ khÃ¡c tá»± Ä‘á»™ng)
    â”‚
    â‘¤ App: XÃ³a card vá»›i animation slide-out + snackbar "ÄÃ£ tá»« chá»‘i Ä‘Æ¡n hÃ  ng."
```

---

### 7.6. Luá»“ng 6: ThÃ´ng bÃ¡o push (Push Notifications)

```
[START] â†’ Backend táº¡o thÃ´ng bÃ¡o cho tÃ  i xáº¿
    â”‚
    â‘  Backend ghi Notification cho tÃ  i xáº¿
       type values:
       - 11 = YÃªu cáº§u nháº­n Ä‘Æ¡n (auto-assign)
       - 12 = ThÃ´ng bÃ¡o giao hÃ  ng (order status update)
       - 13 = ÄÆ¡n Ä‘Ã£ Ä‘Æ°á»£c tÃ  i xáº¿ khÃ¡c nháº­n (409 conflict)
    â”‚
    â‘¡ Backend gá»­i push notification Ä‘áº¿n device cá»§a tÃ  i xáº¿
    â”‚
    â”œâ”€â–º PUSH KHI APP FOREGROUND
    â”‚   â”‚
    â”‚   â‘¢ WebSocket nháº­n thÃ´ng bÃ¡o â†’ kiá»ƒm tra notification type
    â”‚   â”‚
    â”‚   â”œâ”€â–º type=11 (YÃªu cáº§u nháº­n Ä‘Æ¡n)
    â”‚   â”‚      Hiá»‡n custom in-app banner / bottom sheet
    â”‚   â”‚      Pháº¡t Ã¢m thanh thÃ´ng bÃ¡o (audioplayers)
    â”‚   â”‚      HapticFeedback.heavyImpact()
    â”‚   â”‚      NÃºt "Nháº­n" / "Tá»« chá»‘i" â†’ gá»  i /respond
    â”‚   â”‚      Banner tá»± Ä‘á»™ng áº©n sau 30 giÃ¢y náº¿u khÃ´ng pháº£n há»“i
    â”‚   â”‚
    â”‚   â”œâ”€â–º type=12 (ThÃ´ng bÃ¡o giao hÃ  ng)
    â”‚   â”‚      Hiá»‡n snackbar nhá»  : "ÄÆ¡n #{mÃ£} Ä‘Ã£ Ä‘Æ°á»£c cáº­p nháº­t."
    â”‚   â”‚      Refresh OrderDetail náº¿u Ä‘ang má»Ÿ
    â”‚   â”‚
    â”‚   â””â”€â–º type=13 (TÃ  i xáº¿ khÃ¡c nháº­n)
    â”‚          Hiá»‡n dialog: "ÄÆ¡n hÃ  ng Ä‘Ã£ Ä‘Æ°á»£c tÃ  i xáº¿ khÃ¡c nháº­n."
    â”‚          ÄÆ¡n tá»± Ä‘á»™ng biáº¿n máº¥t khá»  i danh sÃ¡ch
    â”‚          Náº¿u Ä‘ang á»Ÿ OrderDetail â†’ pop vá»  danh sÃ¡ch
    â”‚
    â””â”€â–º PUSH KHI APP BACKGROUND / CLOSED
        â”‚
        â‘¢ WebSocket hiá»‡n thÃ´ng bÃ¡o (native OS banner)
           â”œâ”€â–º User tap â†’ Má»Ÿ app â†’ xá»­ lÃ½ theo type
           â”‚      type=11 â†’ Ä‘iá»¼u hÆ°á»›ng OrderDetail + dialog accept/decline
           â”‚      type=12/13 â†’ Ä‘iá»¼u hÆ°á»›ng NotificationsScreen
           â””â”€â–º User swipe dismiss â†’ Notification lÆ°u trong backend
              User Ä‘á»  c sau á»Ÿ mÃ  n Notifications
```

**LÆ°u Ã½ quan trá» ng:**
- NotificationDTO.field `body` chá»©a ná»™i dung â€" **KHÃ”NG pháº£i `message`**
- TrÆ°á» ng `referenceId` thÆ°á»  ng = `orderId` â€" dÃ¹ng Ä‘á»ƒ Ä‘iá»¼u hÆ°á»›ng

---

### 7.7. Luá»“ng 7: VÃ­ & RÃºt tiá»  n (Wallet & Withdraw)

```
[START] â†’ TÃ  i xáº¿ vÃ  o mÃ  n VÃ­
    â”‚
    â‘  Load vÃ­: GET /api/drivers/wallet
    â”‚   â”œâ”€â–º SUCCESS â†’ Hiá»ƒn thá»‹ sá»‘ dÆ° ná»•i báº¤t
    â”‚   â””â”€â–º FAIL â†’ Error state + retry
    â”‚
    â”œâ”€â–º XEM Lá»ŠCH SÁ»¬ GIAO DÁ»ŠCH
    â”‚   â”‚
    â”‚   â‘¡ Load giao dá»‹ch: GET /api/drivers/transactions?page=0&size=20
    â”‚   â”‚   â”œâ”€â–º SUCCESS â†’ Hiá»ƒn thá»‹ ListView
    â”‚   â”‚   â”‚       â”œâ”€â–º type=1 (delivery_income): icon â†‘ mÃ  u xanh lÃ¡, "+{amount}Ä‘"
    â”‚   â”‚   â”‚       â”œâ”€â–º type=2 (withdrawal): icon â†“ mÃ  u Ä‘á»  , "-{amount}Ä‘"
    â”‚   â”‚   â”‚       â””â”€â–º type=3 (refund): icon â†© mÃ  u cam, "+{amount}Ä‘"
    â”‚   â”‚   â”‚   Pull-to-refresh â†’ reload page 0
    â”‚   â”‚   â”‚   Infinite scroll â†’ page++ khi cuá»  n Ä‘áº¿n cuá»  n
    â”‚   â”‚   â””â”€â–º FAIL â†’ Snackbar lá»—i
    â”‚   â”‚
    â”‚   â‘¢ Tap transaction item:
    â”‚      Hiá»‡n bottom sheet chi tiáº¿t:
    â”‚      - MÃ´ táº¯: description
    â”‚      - Sá»‘ tiá»  n: {amount}Ä‘
    â”‚      - PhÃ­: {fee}Ä‘
    â”‚      - Thá»±c nháº­n: {netAmount}Ä‘
    â”‚      - Tráº¡ng thÃ¡i: badge (0=pending, 1=completed, 2=failed)
    â”‚      - Thá»i gian: formatted createdAt
    â”‚      - MÃ£ Ä‘Æ¡n: orderId (náº¿u lÃ  delivery_income)
    â”‚
    â””â”€â–º RÃšT TIá»€N
        â”‚
        â‘¡ Nháº¥n nÃºt "RÃºt tiá»  n" (chá»‰ hiá»‡n khi balance >= 50000)
        â”‚   Náº¿u balance < 50000 â†’ nÃºt disabled + tooltip "Sá»‘ dÆ° tá»‘i thiá»ƒu 50.000Ä‘"
        â”‚
        â‘¢ Hiá»‡n bottom sheet nháº­p sá»‘ tiá»  n:
           - Input sá»‘ tiá»  n rÃºt (VND), formatter sá»‘ tá»± Ä‘á»™ng thÃªm dáº¥u cháº¥m
           - Sá»‘ dÆ° kháº£ dá»¥ng: {balance}Ä‘ (tap Ä‘á»ƒ Ä‘iá»  n max)
           - PhÃ­ rÃºt: 0Ä‘ (miá»…n phÃ­)
           - Sá»‘ tiá»  n nháº­n Ä‘Æ°á»£c: {amount}Ä‘ (= amount - fee)
           - ThÃ´ng tin ngÃ¢n hÃ  ng (tá»« WalletDTO):
             - {bankName}
             - {bankAccountNumber} (mask: ****1234)
             - {bankAccountName}
           - NÃºt chá»  n nhanh: "50K", "100K", "200K", "500K", "Táº¥t cáº£"
           â”œâ”€â–º "Há»§y" â†’ ÄÃ³ng bottom sheet
           â””â”€â–º "XÃ¡c nháº­n rÃºt tiá»  n" â†’ bÆ°á»›c â‘£
        â”‚
        â‘£ Validation client-side:
           â”œâ”€â–º amount < 50000 â†’ "Sá»‘ tiá»  n tá»‘i thiá»ƒu lÃ  50.000Ä‘"
           â”œâ”€â–º amount > balance â†’ "Sá»‘ dÆ° khÃ´ng Ä‘á»§"
           â”œâ”€â–º bankAccountNumber == null â†’ "Báº¡n chÆ°a liÃªn káº¿t ngÃ¢n hÃ  ng. Vui lÃ²ng cáº­p nháº­t trong Há»“ sÆ¡."
           â””â”€â–º PASS â†’ bÆ°á»›c â‘¤
        â”‚
        â‘¤ Gá»­i POST /api/drivers/withdraw
           Body: { "amount": 50000 }
           â”œâ”€â–º SUCCESS (200) â†’ bÆ°á»›c â‘¥
           â”œâ”€â–º 400 BAD_REQUEST â†’ "Sá»‘ dÆ° khÃ´ng Ä‘á»§" / "VÆ°á»£t giá»›i háº¡n rÃºt"
           â””â”€â–º 404 NOT_FOUND â†’ "KhÃ´ng tÃ¬m tháº¥y vÃ­"
        â”‚
        â‘¥ Backend táº¡o TransactionDTO: type=2 (withdrawal), status=0 (pending)
           Backend cáº­p nháº­t WalletDTO: balance -= amount, pendingBalance += amount
        â”‚
        â‘¦ Hiá»‡n dialog thÃ  nh cÃ´ng:
           "YÃªu cáº§u rÃºt tiá»  n thÃ  nh cÃ´ng!"
           "Sá»‘ tiá»  n: {amount}Ä‘"
           "NgÃ¢n hÃ  ng: {bankName}"
           "Sáº½ Ä‘Æ°á»£c xá»­ lÃ½ trong 1-3 ngÃ  y lÃ m viá»‡c."
           "Tráº¡ng thÃ¡i: Äang chá»  xá»­ lÃ½"
           â””â”€â–º "ÄÃ³ng" â†’ refresh vÃ­ + giao dá»‹ch
```

---

### 7.8. Luá»“ng 8: Thá»‘ng kÃª tÃ  i xáº¿ (Driver Stats)

```
[START] â†’ TÃ  i xáº¿ má»Ÿ app / vÃ  o mÃ  n Orders
    â”‚
    â‘  Load profile: GET /api/drivers/profile
    â”‚   â””â”€â–º Láº¥y: todayTrips, todayEarnings, totalTrips, rating
    â”‚
    â‘¡ Hiá»ƒn thá»‹ sticky header stats:
       - HÃ´m nay: {todayTrips} Ä‘Æ¡n | Thu nháº­p: {todayEarnings}Ä‘
       - Tá»•ng: {totalTrips} Ä‘Æ¡n | Rating: â˜…{rating}/5.0
    â”‚
    â‘¢ Má»—i khi cÃ³ Ä‘Æ¡n hoÃ  n thÃ  nhh (status 3):
       - todayTrips += 1
       - todayEarnings += deliveryFee
       - Animate sá»‘ thu nháº­p (count-up animation)
```

---

## 8. YÃªu cáº§u giao diá»‡n tá»«ng mÃ  n hÃ¬nh

### 8.1. MÃ  n hÃ¬nh Tá»•ng há»£p ÄÆ¡n hÃ  ng (Driver Orders Tab)

**Route:** `/driver/orders` (tab thá»© 2 trong Bottom Navigation Bar)

**Giao diá»‡n:**
- **AppBar:** "ÄÆ¡n hÃ  ng cá»§a tÃ´i" + icon thÃ´ng bÃ¡o (chuÃ´ng) + badge sá»‘ chÆ°a Ä‘á»  c
- **Sticky Header Stats:** 2 card náº±m ngang
  - Card tráº£i: "HÃ´m nay" + `{todayTrips}` Ä‘Æ¡n + `{todayEarnings}`Ä‘ (mÃ  u xanh lÃ¡)
  - Card pháº£i: "Tá»•ng" + `{totalTrips}` Ä‘Æ¡n + "â˜…{rating}"
- **Chip filter:** "Táº¥t cáº£" | "Äang giao" | "HoÃ  n thÃ  nhh" | "ÄÃ£ há»§y"
- **Danh sÃ¡ch Ä‘Æ¡n:** ListView, má»—i item lÃ  OrderCard
  - Tap â†’ Ä‘iá»¼u hÆ°á»›ng OrderDetailScreen
  - Swipe left â†’ quick actions (xem nhanh)
- **FAB (Floating Action Button):** icon "+" / icon xe â†’ Ä‘iá»¼u hÆ°á»›ng AvailableOrdersScreen
  - Chá»‰ hiá»‡n khi tÃ  i xáº¿ **Online**
  - Khi Offline: áºÉn FAB hoáº·c hiá»‡n má»  + tooltip "Báº­t online Ä‘á»ƒ nháº­n Ä‘Æ¡n"
- **Pull-to-refresh:** Refresh táº¥t cáº£ dá»¯ liá»‡u (profile + orders)
- **Empty state:** Icon Ä‘Æ¡n hÃ  ng rá»—ng + "ChÆ°a cÃ³ Ä‘Æ¡n hÃ  ng nÃ o"

**Logic lá»  c API:**
| Chip | API gá»  i |
|---|---|
| Táº¥t cáº£ | Gá»  i `/active` + `/history` gá»™p láº¡i, sort theo createdAt desc |
| Äang giao | `GET /api/drivers/orders/active` |
| HoÃ  n thÃ  nhh | `GET /api/drivers/orders/history` (lá»  c status=3) |
| ÄÃ£ há»§y | `GET /api/drivers/orders/history` (lá»  c status=4) |

---

### 8.2. MÃ  n hÃ¬nh ÄÆ¡n hÃ  ng Kháº£ dá»¥ng (Available Orders Screen)

**Route:** `/driver/orders/available`

**Giao diá»‡n:**
- **AppBar:** "ÄÆ¡n hÃ  ng kháº£ dá»¥ng" + icon refresh (manual fetch) + icon sound toggle
- **Sound toggle:** Báº­t/táº¯t Ã¢m thanh thÃ´ng bÃ¡o Ä‘Æ¡n má»›i (lÆ°u vào SharedPreferences)
- **ThÃ´ng tin tÃ³m táº¯t:** "CÃ³ {n} Ä‘Æ¡n hÃ  ng chá»  báº¡n" (hiá»ƒn thá»‹ khi n > 0)
- **Danh sÃ¡ch Ä‘Æ¡n:** ListView, má»—i AvailableOrderCard gá»“m:
  - **Header:** Icon cá»­a hÃ  ng + `storeName` (font lá»›n, bold)
  - **Body:**
    - `storeAddress` (icon Ä‘á»‹a chá»‰, mÃ  u xÃ¡m, 2 dÃ²ng max)
    - `deliveryAddress` (icon giao hÃ  ng, mÃ  u cam)
    - Danh sÃ¡ch mÃ³n (collapsible, hiá»ƒn thá»‹ 2 mÃ³n Ä‘áº§u + "Xem thÃªm X mÃ³n")
    - PhÃ­ giao: `deliveryFee` â€" **Ná»”I Báº¬T NHáº¤T**, font lá»›n, xanh lÃ¡
    - Tá»•ng tiá»  n: `totalAmount`Ä‘ (font nhá»  , xÃ¡m)
  - **Footer:** NÃºt "Nháº­n Ä‘Æ¡n" (PRIMARY, full width) + NÃºt "Tá»« chá»‘i" (text button)
- **Pull-to-refresh:** Refresh danh sÃ¡ch
- **Auto-refresh:** Polling `GET /available` má»—i 10-15 giÃ¢y khi screen Ä‘ang hiá»ƒn thá»‹
- **Empty state:** HÃ¬nh minh há»  xe mÃ¡y + "KhÃ´ng cÃ³ Ä‘Æ¡n hÃ  ng nÃ o kháº£ dá»¥ng"

**Logic:**
- Nháº¥n "Nháº­n Ä‘Æ¡n" â†’ dialog xÃ¡c nháº­n â†’ `POST /accept`
- Nháº¥n "Tá»« chá»‘i" â†’ dialog xÃ¡c nháº­n â†’ `POST /decline` â†’ animation xÃ³a card
- Khi polling cÃ³ Ä‘Æ¡n má»›i â†’ pháº¡t Ã¢m thanh + HapticFeedback + animation slide-in card má»›i
- Khi Ä‘Æ¡n bá»‹ tÃ  i xáº¿ khÃ¡c nháº­n (409) â†’ card biáº¿n máº¥t vá»›i animation + snackbar

---

### 8.3. MÃ  n hÃ¬nh Chi tiáº¿t ÄÆ¡n hÃ  ng (Order Detail Screen)

**Route:** `/driver/orders/detail/:id` â€" nháº­n `orderId` tá»« route param

**Giao diá»‡n - chia thÃ nh 6 sections:**

**Section 1: ThÃ´ng tin cá»­a hÃ  ng**
- Icon cá»­a hÃ  ng + `storeName` (font lá»›n, bold)
- Äá»‹a chá»‰ `storeAddress` (tap Ä‘á»ƒ copy clipboard)
- Tá»  a Ä‘á»™: `storeLat`, `storeLng`
- NÃºt **"Chá»‰ Ä‘Æ°á» ng"** (Google Maps):
  - URL: `https://www.google.com/maps/dir/?api=1&destination={storeLat},{storeLng}`
  - DÃ¹ng `url_launcher` Ä‘á»ƒ má»Ÿ

**Section 2: ThÃ´ng tin ngÆ°á»  i nháº­n**
- Icon ngÆ°á»  i + `receiverName` (áºÉn 1 pháº§n: "Ng*** Van A")
- Äá»‹a chá»‰ giao `deliveryAddress` (font normal, 2 dÃ²ng)
- Tá»  a Ä‘á»™: `deliveryLat`, `deliveryLng`
- NÃºt **"Chá»‰ Ä‘Æ°á» ng"** (Google Maps) â†’ Ä‘áº¿n deliveryLat/lng
- NÃºt **"Gá»  i ngÆ°á»  i nháº­n"** â†’ `url_launcher` vá»›i scheme `tel:{receiverPhone}`

**Section 3: Danh sÃ¡ch mÃ³n Äƒn**
- ListView tá»«ng `OrderItemData`:
  - áº¢nh thumbnail (60Ã—60, border-radius 8, cÃ³ fallback icon)
  - TÃªn mÃ³n `name` (bold)
  - Sá»‘ lÆ°á»£ng Ã— Ä‘Æ¡n giÃ¡: "`{quantity}` Ã— `{price}`Ä‘"
  - Options hiá»ƒn thá»‹: "+ Tran chau: 5.000Ä‘" (mÃ  u xÃ¡m, font nhá»  )
  - Divider giá»¯a cÃ¡c mÃ³n
- Tá»•ng tiá»  n: `totalAmount`Ä‘ (font bold, gáº¡ch ngang náº¿u cÃ³ giáº£m giÃ¡)

**Section 4: ThÃ´ng tin thanh toÃ¡n**
- PhÆ°Æ¡ng thá»©c: icon + text ("Tiá»  n máº·t", "MoMo", "ZaloPay", "VNPay")
- Tráº¡ng thÃ¡i thanh toÃ¡n: badge ("ÄÃ£ thanh toÃ¡n" / "ChÆ°a thanh toÃ¡n")
- **PhÃ­ giao hÃ  ng (THU NHáº¬P):** `deliveryFee` â€" **HIá»‚N THá»Š Ráº¤T Lá»šN**, mÃ  u xanh lÃ¡, icon â‚«
- Ghi chÃº `note`: hiá»ƒn thá»‹ vá»›i icon âš  ï¸  , ná»  n vàng nháº¡t, border vàng

**Section 5: ThÃ´ng tin Ä‘Æ¡n**
- MÃ£ Ä‘Æ¡n: **6 kÃ½ tá»± cuá»‘i** cá»§a `id` â€" font very large (28sp), bold, mÃ  u primary
- Thá»i gian táº¡o: format "HÃ´m nay HH:mm" hoáº·c "dd/MM HH:mm"
- Tráº¡ng thÃ¡i: StatusBadge vá»›i mÃ  u theo báº£ng tráº¡ng thÃ¡i

**Section 6: HÃ  nh Ä‘á»™ng (Action Buttons)**

| Status | NÃºt Primary | NÃºt Secondary | Icon chá»‰ Ä‘Æ°á» ng | Icon gá»  i |
|---|---|---|---|---|
| 0 (Chá»  xÃ¡c nháº­n) | Disabled: "Chá»  cá»­a hÃ  ng xÃ¡c nháº­n" | â€ţ | âœ… | âœ… |
| 1 (Äang chuáº©n bá»‹) | "ÄÃ£ láº¥y hÃ  ng" (xanh lÃ¡) | "Tá»« chá»‘i" (Ä‘á»  nháº¡t) | âœ… (cá»­a hÃ  ng) | âœ… (cá»­a hÃ  ng) |
| 2 (Äang giao) | "ÄÃ£ giao hÃ  ng" (xanh lÃ¡, Ná»”I Báº¬T) | "BÃ¡o sá»± cá»" (cam) | âœ… (ngÆ°á»  i nháº­n) | âœ… (ngÆ°á»  i nháº­n) |
| 3 (HoÃ  n thÃ  nhh) | Disabled: "ÄÃ£ hoÃ  n thÃ  nhh" (xÃ¡m) | â€ţ | âœ… | âœ… |
| 4 (ÄÃ£ há»§y) | Disabled: "ÄÃ£ há»§y" (Ä‘á»  ) | â€ţ | âœ… | âœ… |

---

### 8.4. MÃ  n hÃ¬nh ThÃ´ng bÃ¡o (Notifications Screen)

**Route:** `/driver/notifications`

**Giao diá»‡n:**
- **AppBar:** "ThÃ´ng bÃ¡o" + nÃºt "ÄÃ¡nh dáº¥u Ä‘Ã£ Ä‘á»  c táº¥t cáº£" (icon checkmark-all)
  - Chá»‰ hiá»‡n khi cÃ³ thÃ´ng bÃ¡o chÆ°a Ä‘á»  c
- **Danh sÃ¡ch thÃ´ng bÃ¡o:** ListView, má»—i NotificationItem:
  - Icon theo type (11=motorcycle_delivery, 12=local_shipping, 13=warning, khÃ¡c=info)
    - type=11: icon xe mÃ¡y, mÃ  u xanh dÆ°Æ¡ng
    - type=12: icon giao hÃ  ng, mÃ  u xanh lÃ¡
    - type=13: icon warning, mÃ  u Ä‘á»  ;
  - TiÃªu Ä‘á»  `title` (bold náº¿u chÆ°a Ä‘á»  c, normal náº¿u Ä‘Ã£ Ä‘á»  c)
  - Ná»™i dung `body` (mÃ  u xÃ¡m, 2 dÃ²ng max)
  - Thá»i gian: "5 phÃºt trÆ°á»›c", "HÃ´m nay 14:30", "02/06 14:30" (dÃ¹ng intl package)
  - Badge cháº¥m Ä‘á»  nhá»  trÃªn gÃ³c pháº£i náº¿u `isRead == false`
  - Swipe left â†’ nÃºt xÃ³a Ä‘á»  â†’ `DELETE /{id}`
- **Tap item:**
  - Náº¿u cÃ³ `orderId` (hoáº·c `referenceId`): Ä‘iá»¼u hÆ°á»›ng OrderDetailScreen â†’ Ä‘Ã¡nh dáº¥u Ä‘Ã£ Ä‘á»  c
  - Náº¿u khÃ´ng cÃ³ orderId: chá»‰ Ä‘Ã¡nh dáº¥u Ä‘Ã£ Ä‘á»  c â†’ cáº­p nháº­t badge
- **Pull-to-refresh:** Refresh danh sÃ¡ch
- **Empty state:** Icon chuÃ´ng + "ChÆ°a cÃ³ thÃ´ng bÃ¡o nÃ o"

**LÆ°u Ã½ quan trá» ng:**
- NotificationDTO dÃ¹ng field **`body`** chá»©a ná»™i dung â€" **KHÃ”NG pháº£i `message`**
- Field `referenceId` thÆ°á»  ng = `orderId` â€" dÃ¹ng Ä‘á»ƒ Ä‘iá»¼u hÆ°á»›ng

---

### 8.5. MÃ  n hÃ¬nh VÃ­ TÃ  i xáº¿ (Wallet Screen)

**Route:** `/driver/wallet`

**Giao diá»‡n:**
- **AppBar:** "VÃ­ cá»§a tÃ´i" (khÃ´ng cÃ³ back button náº¿u lÃ  tab)
- **Balance Card** (Gradient background, ná»•i báº¤t):
  - Label: "Sá»‘ dÆ° kháº£ dá»¥ng"
  - Sá»‘ dÆ°: `{balance}Ä‘` â€" font very large (36sp+), bold, white
  - NÃºt "RÃºt tiá»  n" (mÃ  u tráº¯ng, border-radius full)
    - Disabled náº¿u balance < 50000, kÃ¨m tooltip
- **Stats Row:** 3 item náº±m ngang (cÃ¡ch Ä‘á»  ):
  - "Tá»•ng thu nháº­p" / `{totalEarned}Ä‘` (xanh lÃ¡)
  - "Äang chá»  " / `{pendingBalance}Ä‘` (cam)
  - "ÄÃ£ rÃºt" / `{totalWithdrawn}Ä‘` (xÃ¡m)
- **ThÃ´ng tin ngÃ¢n hÃ  ng:**
  - Náº¿u Ä‘Ã£ liÃªn káº¿t: icon ngÃ¢n hÃ  ng + `{bankName}` + sá»  TK mask "â€¢â€¢â€¢â€¢{last4digits}"
  - Náº¿u chÆ°a: Card ná»  n cam nháº¡t + icon warning + "Báº¡n chÆ°a liÃªn káº¿t ngÃ¢n hÃ  ng" + nÃºt "LiÃªn káº¿t ngay"
- **Danh sÃ¡ch giao dá»‹ch:**
  - Tab bar: "Táº¥t cáº£" | "Thu nháº­p" | "RÃºt tiá»  n"
  - ListView TransactionDTO
  - Má»—i item:
    - Icon â†‘ (income=xanh lÃ¡), â†“ (withdrawal=Ä‘á»  ), â†© (refund=cam)
    - MÃ´ táº¯: `description` (VD: "Thu nháº­p giao Ä‘Æ¡n #{mÃ£}")
    - Sá»‘ tiá»  n: `+{amount}Ä‘` (income/refund), `-{amount}Ä‘` (withdrawal)
    - Thá»i gian: formatted `createdAt`
    - Status badge: pending=xÃ¡m, completed=xanh lÃ¡, failed=Ä‘á»  ;
  - Pull-to-refresh
  - Infinite scroll phÃ¢n trang (page++ khi cuá»  n Ä‘áº¿n cuá»  n)
  - Empty state theo tab

---

### 8.6. MÃ  n hÃ¬nh RÃºt tiá»  n (Withdraw Screen)

**Route:** `/driver/wallet/withdraw`

**Giao diá»‡n:**
- **AppBar:** "RÃºt tiá»  n" + back button
- **Sá»‘ dÆ° hiá»‡n táº¯:** `{balance}Ä‘` (hiá»ƒn thá»‹ lá»›n á»Ÿ Ä‘áº§u, mÃ  u xÃ¡m)
- **Input sá»‘ tiá»  n:**
  - TextField vá»›i formatter tá»± Ä‘á»™ng thÃªm dáº¥u cháº©m phÃ¢n cách (VD: "50.000")
  - Icon â‚« á»Ÿ bÃªn pháº£i
  - NÃºt chá»  n nhanh: chip buttons "50K" | "100K" | "200K" | "500K" | "Táº¥t cáº£"
  - Khi tap "Táº¥t cáº£" â†’ Ä‘iá»  n balance vào input
- **ThÃ´ng tin nháº­n tiá»  n:**
  - TÃªn ngÃ¢n hÃ  ng: `{bankName}`
  - Sá»‘ tÃ  i khoáº£n: `{bankAccountNumber}` (mask: "â€¢â€¢â€¢â€¢ â€¢â€¢â€¢â€¢ â€¢â€¢â€¢â€¢ 1234")
  - TÃªn chá»  TK: `{bankAccountName}`
- **Chi tiáº¿t:**
  - Sá»‘ tiá»  n rÃºt: `{amount}Ä‘`
  - PhÃ­ rÃºt: `0Ä‘` (miá»…n phÃ­)
  - Sá»‘ tiá»  n nháº­n Ä‘Æ°á»£c: `{amount}Ä‘`
- **Validation:**
  - amount < 50000 â†’ error text "Sá»‘ tiá»  n tá»‘i thiá»ƒu: 50.000Ä‘"
  - amount > balance â†’ error text "Sá»‘ dÆ° khÃ´ng Ä‘á»§"
  - bankAccountNumber == null â†’ disabled button + text "Báº¡n chÆ°a liÃªn káº¿t ngÃ¢n hÃ  ng"
- **NÃºt "XÃ¡c nháº­n rÃºt tiá»  n"** (disabled náº¿u validation fail)
- **LÆ°u Ã½:** Text nhá»  bÃªn dÆ°á»›i: "YÃªu cáº§u sáº½ Ä‘Æ°á»£c xá»­ lÃ½ trong 1-3 ngÃ  y lÃ m viá»‡c."

---

## 9. RÃ ng buá»™c kÄ© thuáº­t

| ThÃ  nh pháº§n | YÃªu cáº§u |
|---|---|
| **Framework** | Flutter (StatelessWidget + StatefulWidget thuáº§n, khÃ´ng code generation phá»©c táº¡p) |
| **State Management** | Provider hoáº·c BLoC (thá»‘ng nháº¥t vá»›i project) |
| **HTTP Client** | dio (interceptor tá»± Ä‘á»™ng gáº¯n JWT, handle 401 â†’ redirect login) |
| **Navigation** | go_router hoáº·c Navigator 2.0 thuáº§n |
| **Maps** | url_launcher (Google Maps URL scheme) |
| **Phone** | url_launcher (`tel:` scheme) |
| **Date/Time** | intl package (format "5 phÃºt trÆ°á»›c", "HÃ´m nay 14:30", "02/06 14:30") |
| **Push Notifications** | WebSocket STOMP |
| **Background GPS** | flutter_background_service + geolocator |
| **Permissions** | permission_handler |
| **Local Storage** | shared_preferences (token, driverId, sound toggle, cached orders) |
| **Secure Storage** | flutter_secure_storage (JWT credentials â€" KHÃ”NG dÃ¹ng shared_preferences cho token) |
| **Audio** | audioplayers (thÃ´ng bÃ¡o Ä‘Æ¡n má»›i) |
| **Haptic** | Flutter services (HapticFeedback.heavyImpact() khi nháº¥n nÃºt quan trá» ng) |
| **Pull-to-refresh** | RefreshIndicator cho má»  danh sÃ¡ch |
| **Loading** | Shimmer skeleton (2-3 placeholder cards) |
| **Error** | Snackbar cho lá»—i thÆ°á» ng, dialog cho lá»—i nghiÃªm trá» ng (409, 403) |
| **Empty State** | SVG/PNG placeholder + message theo ngá»¯ cáº£nh |
| **Polling** | Timer.periodic 10-15s cho danh sÃ¡ch Ä‘Æ¡n kháº£ dá»¥ng khi online |
| **Confirm Dialog** | LuÃ´n há»  i xÃ¡c nháº­n trÆ°á»›c khi action irreversible (nháº­n Ä‘Æ¡n, giao hÃ  ng, há»§y) |
| **Count-up animation** | Thu nháº­p tÄƒng â†’ animate sá» (dÃ¹ng flutter_countup) |

---

## 10. Cáº¥u trÃºc thÆ° má»¥c Ä‘á»  xuáº¥t

```
lib/
â”œâ”€â”€ main.dart
â”œâ”€â”€ config/
â”‚   â”œâ”€â”€ api_config.dart              # Base URL, headers, dio instance
â”‚   â”œâ”€â”€ app_theme.dart               # Colors, typography, constants
â”‚   â””â”€â”€ app_routes.dart              # go_router route definitions
â”œâ”€â”€ models/
â”‚   â”œâ”€â”€ delivery_order_model.dart    # DeliveryOrderDTO + nested OrderItemData, OptionData
â”‚   â”œâ”€â”€ notification_model.dart      # NotificationDTO
â”‚   â”œâ”€â”€ wallet_model.dart            # WalletDTO
â”‚   â”œâ”€â”€ transaction_model.dart        # TransactionDTO
â”‚   â”œâ”€â”€ driver_profile_model.dart     # DeliveryProfileDTO
â”‚   â””â”€â”€ requests/
â”‚       â”œâ”€â”€ delivery_status_request.dart     # PUT /drivers/status
â”‚       â”œâ”€â”€ delivery_location_request.dart    # POST /drivers/location
â”‚       â”œâ”€â”€ delivery_respond_request.dart     # POST /orders/{id}/respond
â”‚       â”œâ”€â”€ delivery_order_status_request.dart # PUT /orders/{id}/status
â”‚       â””â”€â”€ withdraw_request.dart              # POST /withdraw
â”œâ”€â”€ services/
â”‚   â”œâ”€â”€ api_service.dart             # Dio + JWT interceptor (auto-add Bearer token)
â”‚   â”œâ”€â”€ auth_service.dart            # Token management (get/set/clear token)
â”‚   â”œâ”€â”€ order_service.dart           # Táº¥t cáº£ API orders
â”‚   â”œâ”€â”€ notification_service.dart     # Notifications API
â”‚   â”œâ”€â”€ wallet_service.dart          # Wallet & transactions API
â”‚   â”œâ”€â”€ driver_service.dart          # Profile, status, vehicle API
â”‚   â””â”€â”€ location_service.dart        # GPS + Realtime DB update
â”œâ”€â”€ providers/
â”‚   â”œâ”€â”€ auth_provider.dart           # Login state, token
â”‚   â”œâ”€â”€ driver_provider.dart         # Profile, isActive, online/offline
â”‚   â”œâ”€â”€ order_provider.dart          # Danh sÃ¡ch Ä‘Æ¡n hÃ  ng + polling
â”‚   â”œâ”€â”€ order_detail_provider.dart   # Chi tiáº¿t 1 Ä‘Æ¡n + status update
â”‚   â”œâ”€â”€ notification_provider.dart   # Notifications state + badge count
â”‚   â””â”€â”€ wallet_provider.dart         # VÃ­ + giao dá»‹ch + withdraw
â”œâ”€â”€ screens/
â”‚   â””â”€â”€ driver/
â”‚       â”œâ”€â”€ driver_main_screen.dart   # Bottom nav + tab views
â”‚       â”œâ”€â”€ orders/
â”‚       â”‚   â”œâ”€â”€ orders_screen.dart         # Tab tá»•ng há»£p
â”‚       â”‚   â”œâ”€â”€ available_orders_screen.dart
â”‚       â”‚   â”œâ”€â”€ order_detail_screen.dart
â”‚       â”‚   â””â”€â”€ widgets/
â”‚       â”‚       â”œâ”€â”€ order_card.dart
â”‚       â”‚       â”œâ”€â”€ available_order_card.dart
â”‚       â”‚       â”œâ”€â”€ order_status_badge.dart
â”‚       â”‚       â”œâ”€â”€ order_action_buttons.dart
â”‚       â”‚       â”œâ”€â”€ order_store_info.dart
â”‚       â”‚       â”œâ”€â”€ order_recipient_info.dart
â”‚       â”‚       â””â”€â”€ order_items_list.dart
â”‚       â”œâ”€â”€ wallet/
â”‚       â”‚   â”œâ”€â”€ wallet_screen.dart
â”‚       â”‚   â”œâ”€â”€ withdraw_screen.dart
â”‚       â”‚   â””â”€â”€ widgets/
â”‚       â”‚       â”œâ”€â”€ balance_card.dart
â”‚       â”‚       â”œâ”€â”€ wallet_stats_row.dart
â”‚       â”‚       â”œâ”€â”€ transaction_item.dart
â”‚       â”‚       â””â”€â”€ withdraw_form.dart
â”‚       â”œâ”€â”€ notifications/
â”‚       â”‚   â”œâ”€â”€ notifications_screen.dart
â”‚       â”‚   â””â”€â”€ widgets/
â”‚       â”‚       â””â”€â”€ notification_item.dart
â”‚       â””â”€â”€ profile/
â”‚           â””â”€â”€ driver_profile_screen.dart
â””â”€â”€ utils/
    â”œâ”€â”€ formatters.dart              # Currency (VND), date/time formatters
    â”œâ”€â”€ constants.dart               # Status codes, colors, strings
    â”œâ”€â”€ validators.dart              # Form validators
    â””â”€â”€ helpers.dart                 # URL helpers, phone dialer, map opener
```

---

## 11. Má»™t sá»‘ lÆ°u Ã½ quan trá» ng

1. **deliveryFee** luÃ´n hiá»ƒn thá»‹ **Ná»”I Báº¬T NHáº¤T** mÃ  u xanh lÃ¡, font lá»›n â€" Ä‘Ã¢y lÃ  thu nháº¡p tÃ  i xáº¿.
2. **MÃ£ Ä‘Æ¡n hÃ  ng**: Hiá»ƒn thá»‹ **6 kÃ½ tá»± cuá»‘i** cá»§a UUID Ä‘á»ƒ dá»  Ä‘á»  c vÃ  xÃ¡c nháº­n vá»›i cá»­a hÃ  ng/khÃ¡ch.
3. **Polling khi online**: Khi tÃ  i xáº¿ online, polling `GET /available` má»—i 10-15s. Khi app minimize, dÃ¹ng WebSocket thay vì polling.
4. **GPS Background**: Khi online, GPS cháº¡y á»Ÿ background (`flutter_background_service`) má»—i 5-10s, gá»  i `POST /location`.
5. **Ã‚m thanh thÃ´ng bÃ¡o**: Pháº¡t Ã¢m thanh khi cÃ³ Ä‘Æ¡n má»›i (dÃ¹ng `audioplayers`), kÃ¨m `HapticFeedback.heavyImpact()`.
6. **JWT Token**: LÆ°u trong `flutter_secure_storage`, KHÃ”NG dÃ¹ng `shared_preferences` cho credentials.
7. **409 Conflict**: Khi nháº­n Ä‘Æ¡n mÃ  tÃ  i xáº¿ khÃ¡c Ä‘Ã£ nháº­n â†’ hiá»‡n dialog "ÄÆ¡n Ä‘Ã£ Ä‘Æ°á»£c tÃ  i xáº¿ khÃ¡c nháº­n", xÃ³a card vá»›i animation.
8. **NotificationDTO**: Field chá»©a ná»™i dung lÃ  **`body`**, KHÃ”NG pháº£i `message`. Field tham chiáº¿u lÃ  **`referenceId`**, KHÃ”NG pháº£i `data`.
9. **DriverId tá»« JWT**: Táº¥t cáº£ API dÃ¹ng driverId tá»« token â€" KHÃ”NG hardcode, KHÃ”NG truyá»  n trong URL.
10. **Confirm Dialog**: LuÃ´n há»  i xÃ¡c nháº­n trÆ°á»›c khi: nháº­n Ä‘Æ¡n, xÃ¡c nháº­n láº¥y hÃ  ng, xÃ¡c nháº­n giao hÃ  ng, há»§y Ä‘Æ¡n.
11. **Offline graceful**: Khi khÃ´ng cÃ³ máº¡ng, hiá»ƒn thá»‹ cached data tá»« local storage.
12. **Status 0**: Khi Ä‘Æ¡n á»Ÿ status=0 (Chá»  xÃ¡c nháº­n), tÃ  i xáº¿ chá»‰ xem Ä‘Æ°á»£c thÃ´ng tin, khÃ´ng cÃ³ action.
