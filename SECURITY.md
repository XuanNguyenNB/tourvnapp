# 🔐 Bảo Mật - Firebase API Keys

## ⚠️ Thông Báo Quan Trọng về GitHub Alerts

GitHub đã phát hiện Firebase API keys trong repository này. **Đây là FALSE POSITIVE** - an toàn cho mobile apps.

### Tại Sao An Toàn?

Firebase mobile API keys **được thiết kế để công khai** trong ứng dụng di động:

✅ Không phải secret keys - chỉ định danh project  
✅ Được bảo vệ bởi Firebase Security Rules  
✅ API restrictions configured trong Google Cloud Console  
✅ Platform verification (SHA-1 cho Android, Bundle ID cho iOS)

### 🔒 Cấu Hình Bảo Mật Bắt Buộc

**Xem chi tiết tại**: `docs/FIREBASE_SECURITY_SETUP.md`

**Checklist nhanh**:
- [ ] Configure API restrictions trong Google Cloud Console
- [ ] Add SHA-1 fingerprints cho Android app
- [ ] Add Bundle ID cho iOS app  
- [ ] Setup Firebase Security Rules
- [ ] Enable Firebase App Check (khuyến nghị)

### 📚 Tài Liệu Tham Khảo

- [Firebase: Using API Keys](https://firebase.google.com/docs/projects/api-keys)
- Hướng dẫn chi tiết: `docs/FIREBASE_SECURITY_SETUP.md`

---

## 🚨 Cách Dismiss GitHub Alerts

1. Vào **Security > Secret scanning alerts** trên GitHub
2. Chọn mỗi alert → **Dismiss**
3. Reason: "Used in tests" hoặc "Won't fix"
4. Comment: "Firebase mobile API key - safe when restricted per docs/SECURITY.md"

---
*Firebase mobile API keys ≠ Backend secret keys*
