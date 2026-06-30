# Smart Waste AI — Intelligent Food Management & Waste Reduction System

A production-level Flutter app + FastAPI backend that uses AI to track your groceries, detect expiry dates via OCR, suggest recipes from expiring items using Groq LLM, and reduce food waste.

---

## Architecture Overview

```
Flutter App (Mobile)
       │
       ▼ HTTPS
FastAPI Backend (Render)
  ├─ OCR Service (Tesseract)
  ├─ Detection Service (HuggingFace DETR)
  ├─ Groq AI Service (Llama 3)
  └─ Firebase Admin SDK
       │
       ▼
   Firestore DB
```

---

## Stack (100% Free-Tier)

| Layer | Tech | Cost |
|-------|------|------|
| Mobile | Flutter + Riverpod | Free |
| Backend | FastAPI on Render | Free |
| Auth + DB | Firebase Auth + Firestore | Free |
| OCR | Tesseract | Free/OSS |
| AI Detection | HuggingFace DETR | Free |
| LLM | Groq API (Llama3) | Free |

---

## Project Structure

```
smart-waste-ai/
├── lib/                          # Flutter source
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart   # Full color system + gradients
│   │   │   ├── app_typography.dart
│   │   │   └── app_constants.dart
│   │   ├── theme/app_theme.dart  # Material 3 theme
│   │   ├── routes/app_router.dart
│   │   └── utils/date_utils.dart
│   ├── features/
│   │   ├── auth/                 # Login + Signup
│   │   ├── home/                 # Dashboard
│   │   ├── camera/               # AI scan + OCR
│   │   ├── inventory/            # Expiry tracking
│   │   ├── recipes/              # Groq AI recipes
│   │   ├── analytics/            # Charts + waste report
│   │   └── shopping/             # AI shopping assistant
│   └── shared/                   # Models + widgets
│
├── backend/
│   ├── app/
│   │   ├── api/routes/           # FastAPI endpoints
│   │   ├── services/             # OCR, detection, Groq
│   │   ├── models/schemas.py     # Pydantic models
│   │   └── core/                 # Config + Firebase
│   ├── Dockerfile
│   ├── requirements.txt
│   └── .env.example
│
├── firestore.rules               # Security rules
├── firestore.indexes.json
└── pubspec.yaml
```

---

## Quick Start

### 1. Firebase Setup

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase (creates firebase_options.dart automatically)
flutterfire configure
```

Then enable:
- Firebase Authentication → Email/Password
- Firestore Database
- Deploy security rules: `firebase deploy --only firestore:rules`

### 2. Groq API Key (Free)

1. Go to [console.groq.com](https://console.groq.com)
2. Create a free account
3. Generate an API key
4. Add to backend `.env`

### 3. Backend Setup

```bash
cd backend
cp .env.example .env
# Edit .env with your keys

# Install dependencies
pip install -r requirements.txt

# Run locally
uvicorn app.main:app --reload --port 8000
```

### 4. Deploy Backend to Render (Free)

1. Push to GitHub
2. New Web Service on [render.com](https://render.com)
3. Select your repo, set root to `backend/`
4. Build command: `pip install -r requirements.txt`
5. Start command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
6. Add environment variables from `.env`

### 5. Flutter App

```bash
# Install dependencies
flutter pub get

# Update API URL in lib/core/constants/app_constants.dart
# Change baseUrl to your Render URL

# Run
flutter run
```

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/detect` | Upload image → AI detection + OCR |
| POST | `/api/v1/detect/ocr-only` | OCR expiry extraction only |
| POST | `/api/v1/recipes/generate` | Groq AI recipe generation |
| GET | `/api/v1/recipes/meal-plan` | Weekly meal plan |
| POST | `/api/v1/shopping/suggest` | AI shopping recommendations |
| POST | `/api/v1/analytics/waste-report` | Waste analysis report |
| GET | `/api/v1/inventory/{userId}` | Get user inventory |
| POST | `/api/v1/inventory` | Add inventory item |
| PATCH | `/api/v1/inventory/{id}/consume` | Mark consumed |
| GET | `/health` | Health check |

---

## Firestore Schema

### `users/{uid}`
```json
{
  "uid": "string",
  "name": "string",
  "email": "string",
  "createdAt": "timestamp",
  "sustainabilityScore": 847,
  "totalItemsSaved": 142,
  "wasteReduced": 2.4
}
```

### `inventory/{itemId}`
```json
{
  "userId": "string",
  "name": "Whole Milk",
  "category": "Dairy",
  "emoji": "🥛",
  "expiryDate": "timestamp",
  "addedDate": "timestamp",
  "quantity": 1.0,
  "unit": "L",
  "isConsumed": false,
  "wasted": false,
  "confidence": 0.95
}
```

### `waste_logs/{logId}`
```json
{
  "userId": "string",
  "itemId": "string",
  "timestamp": "timestamp"
}
```

---

## AI Pipeline Flow

```
1. Flutter captures image
2. POST /api/v1/detect (multipart/form-data)
3. Backend:
   a. Validate image (in-memory only, never stored)
   b. Preprocess image (resize, contrast, sharpen)
   c. Run Tesseract OCR → extract expiry dates
   d. Run DETR model → detect food objects
   e. Merge OCR dates with detected items
   f. Delete image bytes from memory
   g. Return structured JSON
4. Flutter displays detected items with expiry dates
5. User confirms → saved to Firestore
6. Groq API generates recipes from expiring items
```

---

## Groq Prompt Engineering

### Recipe Generation
- Model: `llama3-8b-8192`
- Returns: JSON with name, steps, nutrition, expiry urgency
- Temperature: 0.7 for variety

### Shopping Suggestions
- Analyzes inventory gaps + expiry patterns
- Returns prioritized list with reasons

---

## Key Design Decisions

1. **No image storage** — images processed in-memory, immediately discarded (privacy + free tier)
2. **Graceful degradation** — all AI services have mock fallbacks for offline/demo
3. **Firestore real-time** — inventory syncs instantly across devices
4. **Riverpod streams** — reactive UI updates without polling
5. **Clean architecture** — features are fully isolated

---

## Tesseract Installation

**Ubuntu/Debian:**
```bash
sudo apt-get install tesseract-ocr
```

**macOS:**
```bash
brew install tesseract
```

**Windows:**
Download installer from [GitHub releases](https://github.com/UB-Mannheim/tesseract/wiki)
Set `TESSERACT_PATH=C:\Program Files\Tesseract-OCR\tesseract.exe`
