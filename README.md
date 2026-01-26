# 📖 TourVN - Ứng Dụng Du Lịch Việt Nam

Ứng dụng mobile Flutter cho tour du lịch, tích hợp Firebase Backend.

## 🚀 Bắt Đầu

### Yêu Cầu
- Flutter SDK ≥ 3.10.3
- Firebase Project: `tourvn-mobile-2026`

### Cài Đặt

```bash
# Clone repository
git clone https://github.com/XuanNguyenNB/tourvnapp.git
cd tourvnapp

# Cài đặt dependencies
flutter pub get

# Chạy app
flutter run
```

## 📱 Platform Support
- ✅ Android
- ✅ iOS
- ❌ Web (chưa cấu hình)

## 🔥 Firebase Services
- **Authentication**: Đăng nhập/Đăng ký người dùng
- **Firestore**: Database cho tours, bookings, users
- **Storage**: Lưu trữ hình ảnh

## 🔐 Bảo Mật

**Quan trọng**: Đọc `SECURITY.md` để hiểu về Firebase API keys.

Chi tiết cấu hình: `docs/FIREBASE_SECURITY_SETUP.md`

## 📁 Cấu Trúc Dự Án

```
tour_vn/
├── lib/
│   ├── firebase_options.dart    # Firebase config
│   └── main.dart                # Entry point
├── android/                     # Android platform
├── ios/                         # iOS platform
├── docs/                        # Documentation
│   ├── SECURITY.md             # Security policy
│   └── FIREBASE_SECURITY_SETUP.md
└── .env.example                # Environment template
```

## 🛠️ Development

```bash
# Run debug build
flutter run

# Build release APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

## 📚 Documentation

- `SECURITY.md` - Chính sách bảo mật
- `docs/FIREBASE_SECURITY_SETUP.md` - Hướng dẫn cấu hình Firebase
- `.env.example` - Template cho environment variables

## 📄 License

Copyright © 2026 TourVN

---
**Project**: TourVN Mobile App  
**Firebase**: tourvn-mobile-2026  
**Repository**: https://github.com/XuanNguyenNB/tourvnapp
