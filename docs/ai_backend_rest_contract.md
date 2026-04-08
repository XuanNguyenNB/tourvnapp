# AI Backend REST Contract

App nay khong con goi Firebase Functions. Tat ca tinh nang AI di qua mot HTTP backend duoc cau hinh bang:

```bash
flutter run --dart-define=AI_BACKEND_BASE_URL=https://your-ai-host.example.com
```

Neu khong truyen `AI_BACKEND_BASE_URL`, o che do debug app se mac dinh tim local AI adapter tai `http://127.0.0.1:8787`.

## Demo stack nhanh nhat

Cho buoi bao ve, stack nhanh nhat hien tai la:

- Flutter app -> local AI adapter (`functions/src/demo_server.ts`) tren cong `8787`
- AI adapter -> `CLIProxyAPI` tren cong `8317`
- `CLIProxyAPI` -> OAuth account `antigravity`
- model uu tien: `gemini-3-flash-preview`
- fallback mac dinh: `gemini-3-flash-agent`, `gemini-2.5-flash`, `gemini-3-pro-preview`

Lenh chay nhanh:

```powershell
.\scripts\start_demo_ai.ps1
```

Hoac tu chay tay:

```powershell
cd C:\Users\nguye\Documents\CLIProxyAPI
.\cli-proxy-api.exe -config config.yaml
```

```powershell
cd C:\Users\nguye\Documents\DATN\tour_vn\functions
$env:AI_PROXY_BASE_URL='http://127.0.0.1:8317'
$env:AI_PROXY_API_KEY='your-api-key-1'
$env:AI_PROXY_MODEL='gemini-3-flash-preview'
npm run serve:demo-ai
```

Neu demo tren dien thoai that, hay cho laptop va dien thoai cung Wi-Fi, sau do chay app voi:

```powershell
flutter run --dart-define=AI_BACKEND_BASE_URL=http://<LAN-IP-cua-laptop>:8787
```

## Request format

- Method: `POST`
- Headers:
  - `Content-Type: application/json`
  - `Accept: application/json, text/plain`
  - `Authorization: Bearer <firebase-id-token>` neu user da dang nhap

## Endpoints

- `POST /generateDestinationDraft`
  - Body: `{ "prompt": "..." }`
  - Response: JSON object

- `POST /generateLocationDrafts`
  - Body:
    ```json
    {
      "destinationId": "da-lat",
      "destinationName": "Da Lat",
      "prompt": "...",
      "count": 5
    }
    ```
  - Response: JSON array

- `POST /generateReviewDraft`
  - Body:
    ```json
    {
      "prompt": "...",
      "destinationId": "da-lat",
      "destinationName": "Da Lat",
      "existingLocations": [],
      "articleStyle": "review"
    }
    ```
  - Response: JSON object

- `POST /generateReviewDrafts`
  - Body:
    ```json
    {
      "prompt": "...",
      "destinationName": "Da Lat",
      "destinationId": "da-lat",
      "existingLocations": [],
      "articleStyle": "review",
      "count": 3
    }
    ```
  - Response: JSON array

- `POST /enrichAutoPlan`
  - Body: `{ "prompt": "..." }`
  - Response: JSON object

- `POST /generateStopTip`
  - Body:
    ```json
    {
      "locationName": "Ho Xuan Huong",
      "category": "places",
      "startTimeLabel": "08:00",
      "endTimeLabel": "09:00",
      "durationMin": 60
    }
    ```
  - Response:
    - plain text, hoac
    - JSON object: `{ "text": "..." }`

## Error format

Backend nen tra mot trong cac dang sau:

```json
{ "message": "..." }
```

hoac:

```json
{ "error": "..." }
```

hoac:

```json
{ "error": { "message": "..." } }
```

## Auth guidance

App se gui Firebase ID token neu co user dang dang nhap. Neu backend van muon giu logic phan quyen cu:

- cac endpoint admin (`generateDestinationDraft`, `generateLocationDrafts`, `generateReviewDraft`, `generateReviewDrafts`) nen verify token va check custom claim `admin=true`
- cac endpoint user (`enrichAutoPlan`, `generateStopTip`) chi can verify token hop le neu ban muon yeu cau dang nhap

Backend cu trong `functions/src/ai.ts` la nguon logic tot de tach sang Render, Railway, Supabase Edge Functions, Cloudflare Workers hoac server rieng.
