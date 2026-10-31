# TakeMyTrash — User Side App

A full-stack mobile application (React Native + Node.js) for users to book trash pickup services, with real-time collector tracking and Razorpay payments.

---

## 📁 Project Structure

```
TakeMyTrash_user/
├── backend/          # Node.js + Express + Prisma API
└── mobile/           # React Native (Expo) App
```

---

## 🚀 Quick Start

### Prerequisites
- Node.js 20+
- PostgreSQL running locally
- Redis running locally
- Expo CLI: `npm install -g expo-cli`

---

### Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Copy and configure environment
cp .env.example .env
# Edit .env with your PostgreSQL, Redis, Razorpay, and Google Maps keys

# Generate Prisma client
npm run prisma:generate

# Run database migrations
npm run prisma:migrate

# Start development server
npm run dev
```

Backend runs on: `http://localhost:3000`

---

### Mobile App Setup

```bash
cd mobile

# Install dependencies
npm install

# Copy and configure environment
cp .env.example .env
# Set EXPO_PUBLIC_API_URL to your backend URL

# Start Expo dev server
npx expo start

# Run on Android
npx expo run:android

# Run on iOS
npx expo run:ios
```

---

## 🔌 API Reference

### Authentication
| Method | Endpoint | Description |
|--------|---------|-------------|
| POST | /api/auth/register | Register new user |
| POST | /api/auth/login | Login (email/phone + password) |
| POST | /api/auth/refresh | Refresh access token |
| POST | /api/auth/logout | Logout |
| POST | /api/auth/send-otp | Send OTP to phone |
| POST | /api/auth/verify-otp | Verify OTP |

### Bookings
| Method | Endpoint | Description |
|--------|---------|-------------|
| POST | /api/bookings | Create booking |
| GET | /api/bookings | List all user bookings |
| GET | /api/bookings/:id | Get booking details |
| GET | /api/bookings/:id/status | Get booking status |
| PATCH | /api/bookings/:id/cancel | Cancel booking |

### Payments
| Method | Endpoint | Description |
|--------|---------|-------------|
| POST | /api/payments/create-order | Create Razorpay order |
| POST | /api/payments/verify | Verify payment signature |
| GET | /api/payments/history | Payment history |

### Ratings
| Method | Endpoint | Description |
|--------|---------|-------------|
| POST | /api/ratings | Submit a rating |

---

## 🔴 Real-time Events (Socket.io)

**Client → Server:**
- `join_booking_room` — Subscribe to booking updates
- `leave_booking_room` — Unsubscribe

**Server → Client:**
- `booking_assigned` — Collector matched
- `collector_location` — Live location update
- `pickup_started` — Collector arrived
- `pickup_completed` — Pickup done
- `booking_cancelled` — Booking cancelled

---

## 🗺️ Google Maps Integration

To enable real-time map tracking and address autocomplete:

1. Get a Google Maps API key from [Google Cloud Console](https://console.cloud.google.com/)
2. Enable: Maps SDK for Android/iOS, Places API, Directions API
3. Add to `mobile/.env`: `EXPO_PUBLIC_GOOGLE_MAPS_KEY=your_key`
4. Add to `backend/.env`: `GOOGLE_MAPS_API_KEY=your_key`

---

## 💳 Razorpay Integration

1. Create a Razorpay account at [razorpay.com](https://razorpay.com)
2. Get your test API keys from the Dashboard
3. Add to `backend/.env`: `RAZORPAY_KEY_ID` and `RAZORPAY_KEY_SECRET`
4. Install `react-native-razorpay` in mobile for production payment UI

---

## 🤝 Collector App Integration

The collector app (built separately) needs to connect to the **same backend** and:

1. Authenticate with the same JWT system (use `role: 'collector'` claim)
2. Accept bookings via Socket.io events
3. Emit `collector_location_update` events with booking ID and lat/lng
4. Emit `pickup_started` and `pickup_completed` events

Redis key format for collector location: `collector:location:{collectorId}`

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | React Native (Expo) |
| Navigation | React Navigation v6 |
| State | Zustand |
| Backend | Node.js + Express.js |
| Database | PostgreSQL via Prisma |
| Real-time | Socket.io |
| Payments | Razorpay |
| Auth | JWT + bcrypt |
| Cache/Queue | Redis + Bull |

---

## 📱 Screens

1. **Splash** — Auto auth check
2. **Login** — Email + password
3. **Register** — New account
4. **Dashboard** — Stats, active bookings, quick actions
5. **Book Pickup** — Immediate / Scheduled choice
6. **Address** — Location selection
7. **Booking Details** — Waste type, quantity, notes
8. **Booking Confirm** — Review & confirm
9. **Assigning Collector** — Animated waiting
10. **Payment** — Razorpay checkout
11. **Tracking** — Live collector map
12. **History** — All past bookings
13. **Booking Detail** — Single booking view
14. **Rating** — Star rating + comment
15. **Profile** — User info + settings
