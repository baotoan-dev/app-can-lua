# Sổ Cân Lúa (app-can-lua)

Ứng dụng ghi chép, tính tiền và in phiếu cân lúa hiện trường chuyên nghiệp dành cho nông dân và thương lái nông sản miền Tây.

---

## 1. Giới Thiệu (Overview)

**Sổ Cân Lúa** (`com.socanlua.app`) giải quyết triệt để các sai sót khi ghi chép sổ tay truyền thống ngoài ruộng lúa:
- Nhập số cân siêu tốc với bàn phím xúc giác công thái học 48px.
- Đọc số cân bằng giọng nói Tiếng Việt miền Tây (Text-to-Speech) chuẩn xác, loại bỏ lỗi nghe nhầm số.
- Tự động trừ bao bì, trừ tạp chất/độ ẩm, và tính toán số tiền thành tiền tức thì.
- Phân đợt chốt tiền và xuất biên bản / in phiếu nhiệt di động (K58, K80, A4).
- Hoạt động 100% ngoại tuyến (Offline-First), dữ liệu lưu trữ phân tầng an toàn trong máy.

---

## 2. Tính Năng Nổi Bật (Key Features)

### 🌾 Nhập Cân & Đọc Giọng Nói Tức Thì
- **Nhập cân siêu tốc:** Bàn phím số 48px to rõ, hạn chế tối đa bấm nhầm khi đứng ngoài nắng.
- **Giọng đọc Tiếng Việt miền Tây:** Phát âm dứt khoát chuẩn xác (*"Bao mười hai: năm mươi hai ký rưỡi"*), hỗ trợ 3 mức tốc độ (Chậm 0.95x, Tự nhiên 1.15x, Nhanh hiện trường 1.35x) và 3 kiểu đọc (Đầy đủ, Rút gọn, Chỉ số cân).
- **Chỉnh sửa / Xóa an toàn 2 bước:** Tự động tính chênh lệch tiền phát sinh và tự động dời thứ tự các bao còn lại.

### 💰 Quản Lý Tài Chính & Đợt Cân
- **Phân nhóm & Chốt đợt:** Hỗ trợ gom bao theo từng đợt vác lên ghe hoặc xe tải, tính tiền theo từng đợt để thanh toán cuốn chiếu.
- **Tính tiền linh hoạt:** Quản lý tiền cọc, trừ bao bì (bì chuẩn 0.2kg - 0.5kg/bao), trừ độ ẩm/tạp chất, tự động tính số tiền còn lại phải trả.

### 🖨️ Xuất Phiếu & In Ấn Di Động
- **In nhiệt tại chỗ:** Tương thích máy in nhiệt Bluetooth/USB khổ 58mm (K58) và 80mm (K80).
- **Xuất phiếu chuẩn A4 / PDF:** Tự động phân trang thông minh khi danh sách vượt quá 40-50 bao, tích hợp mã QR đối soát và chữ ký biên nhận.
- **Xuất bảng tính CSV / Excel:** Dễ dàng đối chiếu trên máy tính.

### 🛡️ Dữ Liệu Ngoại Tuyến (Offline-First) & Sao Lưu
- **Kiến trúc phân tầng lưu trữ (Partitioned Storage):** Tách biệt chỉ mục nhẹ và dữ liệu chi tiết, khởi động dưới 20ms ngay cả khi có hàng nghìn lượt cân.
- **Sao lưu & Phục hồi:** Xuất và nhập toàn bộ lịch sử qua tệp sao lưu JSON chuẩn hóa.

---

## 3. Cấu Trúc Mã Nguồn (Architecture)

```
can_lua_app/
├── lib/
│   ├── core/
│   │   ├── enums/        # Enum-Driven Architecture (VoiceReaderSpeed, WeighingGroupingMode...)
│   │   ├── theme/        # Bảng màu lúa vàng miền Tây & Emerald Dark
│   │   ├── utils/        # Đọc số tiếng Việt, định dạng tiền VNĐ, tính toán số cân
│   │   └── widgets/      # Modal Bottom Sheet chuẩn iOS, Segmented Tab, Responsive Frame
│   ├── features/
│   │   └── weighing/
│   │       ├── models/   # SessionIndexItem, WeighingSession, BagWeight
│   │       ├── screens/  # WeighingScreen, HistoryScreen, ReceiptPreviewScreen, SessionSetupScreen
│   │       ├── services/ # LocalStorageService (Partitioned), TtsVoiceService
│   │       └── widgets/  # BagGridMatrix, CustomNumpad, LiveSummaryBar
│   └── main.dart
├── test/                 # Bộ kiểm thử tự động toàn diện (Unit & Widget Tests)
├── web/                  # Web PWA & Trình phát âm thanh Google TTS Proxy
└── android/              # Cấu hình Android Application (com.socanlua.app)
```

---

## 4. Hướng Dẫn Cài Đặt & Khởi Chạy (Quick Start)

### Yêu Cầu Môi Trường
- Flutter SDK $\ge$ 3.24.0
- Dart SDK $\ge$ 3.5.0
- Node.js $\ge$ 18 (tùy chọn, phục vụ máy chủ Web Release và Audio Proxy)

### Các Bước Khởi Chạy

```bash
# 1. Cài đặt các thư viện phụ thuộc
flutter pub get

# 2. Chạy ứng dụng ở chế độ Debug
flutter run

# 3. Chạy toàn bộ bộ kiểm thử tự động
flutter test

# 4. Kiểm tra phân tích cú pháp tĩnh
flutter analyze

# 5. Biên dịch bản Web Release
flutter build web --release

# 6. Khởi chạy máy chủ Web Release (Cổng 8085)
node web_server.js
```

---

## 5. Bản Quyền & Giấy Phép (License)

Phát triển bởi **baotoan-dev**. Được cấp phép theo giấy phép [MIT](LICENSE).
