# 🏠 Digital Kos Management System

A full-stack mobile application for managing kos (boarding house) properties, tenants, and payments. Built with Flutter (Android) and Node.js + MySQL.

---

## 📱 Screenshots

> Add your emulator/device screenshots here after testing

---

## 🏗️ Architecture

```
MVVM Architecture
├── View        → Flutter Screens (screens/)
├── ViewModel   → Providers (providers/)
├── Repository  → Data logic layer (repositories/)
└── Service     → Pure HTTP/API calls (services/)

Backend: MVC
├── Routes      → URL definitions
├── Controllers → Request handling
├── Models      → Database queries
└── Services    → Business logic (billing, sheets, etc.)
```

---

## 🗂️ Project Structure

```
kos-management/
├── kos-backend/                  ← Node.js backend
│   ├── config/
│   │   └── db.js                 ← MySQL connection pool
│   ├── controllers/
│   │   ├── authController.js
│   │   ├── kosController.js
│   │   ├── roomController.js
│   │   ├── billController.js
│   │   ├── addonController.js
│   │   ├── analyticsController.js
│   │   ├── exportController.js
│   │   ├── sheetsController.js
│   │   ├── tenantAuthController.js
│   │   └── tenantBillController.js
│   ├── models/
│   │   ├── owner.js
│   │   ├── kos.js
│   │   ├── roomType.js
│   │   ├── room.js
│   │   ├── tenant.js
│   │   ├── tenantAuth.js
│   │   ├── addon.js
│   │   └── bill.js
│   ├── routes/
│   │   ├── authRoutes.js
│   │   ├── kosRoutes.js
│   │   ├── roomRoutes.js
│   │   ├── billRoutes.js
│   │   ├── addonRoutes.js
│   │   ├── analyticsRoutes.js
│   │   ├── exportRoutes.js
│   │   ├── sheetsRoutes.js
│   │   ├── tenantAuthRoutes.js
│   │   └── tenantBillRoutes.js
│   ├── middleware/
│   │   └── authMiddleware.js     ← JWT verification
│   ├── services/
│   │   ├── billingService.js     ← Auto billing logic
│   │   └── sheetsService.js      ← Google Sheets sync
│   ├── jobs/
│   │   └── billingCron.js        ← Midnight cron job
│   ├── .env.example              ← Environment template
│   ├── .gitignore
│   ├── package.json
│   └── index.js                  ← Entry point
│
└── kos_management/               ← Flutter app
    └── lib/
        ├── config/
        │   └── api_config.dart   ← Base URL config
        ├── models/
        │   ├── user_model.dart
        │   └── tenant_model.dart
        ├── services/             ← Pure HTTP calls
        │   ├── auth_service.dart
        │   ├── kos_service.dart
        │   ├── room_service.dart
        │   ├── bill_service.dart
        │   ├── addon_service.dart
        │   ├── analytics_service.dart
        │   ├── notification_service.dart
        │   ├── sheets_service.dart
        │   ├── tenant_auth_service.dart
        │   └── tenant_bill_service.dart
        ├── repositories/         ← Data logic layer
        │   ├── auth_repository.dart
        │   ├── kos_repository.dart
        │   ├── room_repository.dart
        │   ├── bill_repository.dart
        │   ├── addon_repository.dart
        │   ├── analytics_repository.dart
        │   ├── notification_repository.dart
        │   ├── sheets_repository.dart
        │   ├── tenant_auth_repository.dart
        │   └── tenant_bill_repository.dart
        ├── providers/            ← State management (ViewModel)
        │   ├── auth_provider.dart
        │   ├── kos_provider.dart
        │   ├── bill_provider.dart
        │   ├── addon_provider.dart
        │   ├── analytics_provider.dart
        │   └── tenant_provider.dart
        ├── screens/              ← UI screens (View)
        │   ├── role_select_screen.dart
        │   ├── login_screen.dart
        │   ├── register_screen.dart
        │   ├── dashboard_screen.dart
        │   ├── kos_setup_screen.dart
        │   ├── room_list_screen.dart
        │   ├── add_room_screen.dart
        │   ├── tenant_list_screen.dart
        │   ├── add_tenant_screen.dart
        │   ├── tenant_addon_screen.dart
        │   ├── billing_screen.dart
        │   ├── analytics_screen.dart
        │   ├── payment_history_screen.dart
        │   ├── export_screen.dart
        │   ├── addon_management_screen.dart
        │   ├── tenant_login_screen.dart
        │   ├── tenant_setup_password_screen.dart
        │   ├── tenant_home_screen.dart
        │   └── tenant_payment_screen.dart
        ├── widgets/
        │   └── property_switcher.dart
        └── main.dart
```

---

## ⚙️ Tech Stack

| Layer            | Technology                             |
| ---------------- | -------------------------------------- |
| Mobile Frontend  | Flutter (Android)                      |
| State Management | Provider + MVVM                        |
| Backend          | Node.js + Express                      |
| Database         | MySQL                                  |
| Authentication   | JWT + bcrypt                           |
| Scheduled Jobs   | node-cron                              |
| Notifications    | Fonnte (WhatsApp) + Nodemailer (Email) |
| Export           | CSV + Google Sheets API                |
| Architecture     | MVC (backend) + MVVM (frontend)        |

---

## 🗄️ Database Schema

```sql
owners          ← kos owner accounts
kos             ← kos properties (many per owner)
room_types      ← pricing templates (Standard, VIP...)
rooms           ← individual rooms (A01, B01...)
tenants         ← active/inactive tenants
addons          ← available add-on services
tenant_addons   ← which add-ons a tenant has
bills           ← monthly bills (auto-generated)
notifications   ← in-app notification records
```

### Key relationships

```
owner → has many → kos
kos → has many → room_types, rooms
room → belongs to → room_type, kos
tenant → occupies → room
tenant → has many → tenant_addons, bills
bill → belongs to → tenant, kos
```

---

## 🚀 Getting Started

### Prerequisites

- Node.js v18+
- MySQL 8.0+
- Flutter SDK 3.x
- Android Studio + emulator or physical device

---

### Backend Setup

**1. Clone the repo**

```bash
git clone https://github.com/YOUR_USERNAME/kos-management.git
cd kos-management/kos-backend
```

**2. Install dependencies**

```bash
npm install
```

**3. Create `.env` file**

```bash
cp .env.example .env
```

Edit `.env` with your values:

```dotenv
PORT=3000
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=kos_db
JWT_SECRET=your_long_random_secret_key

# Email (Gmail App Password required)
EMAIL_USER=your@gmail.com
EMAIL_PASS=your_app_password

# WhatsApp (Fonnte)
FONNTE_TOKEN=your_fonnte_token

# Google Sheets (optional)
GOOGLE_SHEET_ID=your_spreadsheet_id
GOOGLE_CLIENT_EMAIL=your_service_account@project.iam.gserviceaccount.com
GOOGLE_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----\n...\n-----END RSA PRIVATE KEY-----"
```

**4. Create MySQL database**

```bash
mysql -u root -p
```

```sql
CREATE DATABASE kos_db;
USE kos_db;
```

**5. Run database schema**

```sql
CREATE TABLE owners (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  role ENUM('owner','tenant') DEFAULT 'owner',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE kos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  owner_id INT NOT NULL,
  name VARCHAR(100) NOT NULL,
  address TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (owner_id) REFERENCES owners(id)
);

CREATE TABLE room_types (
  id INT AUTO_INCREMENT PRIMARY KEY,
  kos_id INT NOT NULL,
  name VARCHAR(100) NOT NULL,
  base_price DECIMAL(12,2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (kos_id) REFERENCES kos(id)
);

CREATE TABLE rooms (
  id INT AUTO_INCREMENT PRIMARY KEY,
  kos_id INT NOT NULL,
  room_type_id INT NOT NULL,
  room_number VARCHAR(20) NOT NULL,
  status ENUM('available','occupied') DEFAULT 'available',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (kos_id) REFERENCES kos(id),
  FOREIGN KEY (room_type_id) REFERENCES room_types(id)
);

CREATE TABLE tenants (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  phone VARCHAR(20),
  room_id INT NOT NULL,
  start_date DATE NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  password VARCHAR(255) NULL,
  password_set BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (room_id) REFERENCES rooms(id)
);

CREATE TABLE addons (
  id INT AUTO_INCREMENT PRIMARY KEY,
  kos_id INT NOT NULL,
  name VARCHAR(100) NOT NULL,
  price DECIMAL(12,2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (kos_id) REFERENCES kos(id)
);

CREATE TABLE tenant_addons (
  id INT AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT NOT NULL,
  addon_id INT NOT NULL,
  assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (tenant_id) REFERENCES tenants(id),
  FOREIGN KEY (addon_id) REFERENCES addons(id),
  UNIQUE KEY unique_tenant_addon (tenant_id, addon_id)
);

CREATE TABLE bills (
  id INT AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT NOT NULL,
  kos_id INT NOT NULL,
  billing_month VARCHAR(20) NOT NULL,
  base_amount DECIMAL(12,2) NOT NULL,
  addon_amount DECIMAL(12,2) DEFAULT 0,
  penalty_amount DECIMAL(12,2) DEFAULT 0,
  total_amount DECIMAL(12,2) NOT NULL,
  due_date DATE NOT NULL,
  paid_date DATE,
  status ENUM('unpaid','paid') DEFAULT 'unpaid',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (tenant_id) REFERENCES tenants(id),
  FOREIGN KEY (kos_id) REFERENCES kos(id)
);

CREATE TABLE notifications (
  id INT AUTO_INCREMENT PRIMARY KEY,
  recipient_type ENUM('owner','tenant') NOT NULL,
  recipient_id INT NOT NULL,
  title VARCHAR(100) NOT NULL,
  message TEXT NOT NULL,
  type ENUM('bill_generated','due_soon','overdue') NOT NULL,
  is_read TINYINT(1) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**6. Start the server**

```bash
node index.js
```

Expected output:

```
✅ MySQL Connected
✅ Billing cron job scheduled (runs daily at midnight)
Server running on port 3000
```

---

### Flutter Setup

**1. Navigate to Flutter project**

```bash
cd kos_management
```

**2. Install dependencies**

```bash
flutter pub get
```

**3. Configure API base URL**

Open `lib/config/api_config.dart`:

```dart
class ApiConfig {
  // For Android emulator
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // For physical device (use your computer's local IP)
  // static const String baseUrl = 'http://192.168.x.x:3000/api';
}
```

**4. Run the app**

```bash
flutter run
```

---

## 📡 API Reference

### Auth (Owner)

| Method | Endpoint             | Description        |
| ------ | -------------------- | ------------------ |
| POST   | `/api/auth/register` | Register owner     |
| POST   | `/api/auth/login`    | Login, returns JWT |

### Kos & Rooms

| Method | Endpoint                  | Description         |
| ------ | ------------------------- | ------------------- |
| POST   | `/api/kos`                | Create kos property |
| GET    | `/api/kos/my`             | Get all owner's kos |
| POST   | `/api/kos/:id/room-types` | Add room type       |
| GET    | `/api/kos/:id/room-types` | List room types     |
| POST   | `/api/rooms`              | Create room         |
| GET    | `/api/rooms/:kosId`       | List rooms          |

### Tenants

| Method | Endpoint                    | Description       |
| ------ | --------------------------- | ----------------- |
| POST   | `/api/rooms/tenants`        | Add tenant        |
| GET    | `/api/rooms/tenants/:kosId` | List tenants      |
| DELETE | `/api/rooms/tenants/:id`    | Deactivate tenant |

### Billing

| Method | Endpoint                    | Description          |
| ------ | --------------------------- | -------------------- |
| POST   | `/api/bills/generate`       | Force generate bills |
| GET    | `/api/bills/:kosId`         | Get all bills        |
| PATCH  | `/api/bills/:id/pay`        | Mark bill paid       |
| GET    | `/api/bills/overdue/:kosId` | Get overdue bills    |

### Add-ons

| Method | Endpoint                 | Description        |
| ------ | ------------------------ | ------------------ |
| POST   | `/api/addons`            | Create add-on      |
| GET    | `/api/addons/:kosId`     | List add-ons       |
| DELETE | `/api/addons/:id`        | Delete add-on      |
| POST   | `/api/addons/assign`     | Assign to tenant   |
| POST   | `/api/addons/remove`     | Remove from tenant |
| GET    | `/api/addons/tenant/:id` | Get tenant add-ons |

### Analytics & Export

| Method | Endpoint                            | Description           |
| ------ | ----------------------------------- | --------------------- |
| GET    | `/api/analytics/:kosId`             | Dashboard stats       |
| GET    | `/api/analytics/tenant/:id/history` | Payment history       |
| GET    | `/api/export/bills/:kosId`          | Export bills CSV      |
| GET    | `/api/export/tenants/:kosId`        | Export tenants CSV    |
| POST   | `/api/sheets/sync/:kosId`           | Sync to Google Sheets |

### Tenant Portal

| Method | Endpoint                          | Description         |
| ------ | --------------------------------- | ------------------- |
| POST   | `/api/tenant-auth/setup-password` | First-time password |
| POST   | `/api/tenant-auth/login`          | Tenant login        |
| GET    | `/api/tenant-auth/profile`        | Get profile         |
| GET    | `/api/tenant-bills/my`            | Get my bills        |
| GET    | `/api/tenant-bills/current`       | Current unpaid bill |
| POST   | `/api/tenant-bills/:id/pay`       | Pay a bill          |

> All endpoints except auth routes require `Authorization: Bearer <token>` header.

---

## 🔄 How Billing Works

```
Tenant moves in on May 15
→ Bill generated every 15th of each month
→ Bill = base_rent + addon_total
→ Due date = 1 month after billing date

Daily at midnight (node-cron):
1. Check each tenant's billing day
2. If today matches → create bill (skip if exists)
3. Check all unpaid overdue bills
4. Update penalty = days_late × Rp10.000
5. Send WhatsApp + in-app notification
```

---

## 🔧 Environment Variables

| Variable              | Required | Description                               |
| --------------------- | -------- | ----------------------------------------- |
| `PORT`                | ✅       | Server port (default 3000)                |
| `DB_HOST`             | ✅       | MySQL host                                |
| `DB_USER`             | ✅       | MySQL username                            |
| `DB_PASSWORD`         | ✅       | MySQL password                            |
| `DB_NAME`             | ✅       | Database name                             |
| `JWT_SECRET`          | ✅       | Long random string for JWT signing        |
| `EMAIL_USER`          | ⚠️       | Gmail address for email notifications     |
| `EMAIL_PASS`          | ⚠️       | Gmail App Password (not regular password) |
| `FONNTE_TOKEN`        | ⚠️       | Fonnte API token for WhatsApp             |
| `GOOGLE_SHEET_ID`     | ⚠️       | Google Spreadsheet ID for sync            |
| `GOOGLE_CLIENT_EMAIL` | ⚠️       | Service account email                     |
| `GOOGLE_PRIVATE_KEY`  | ⚠️       | Service account private key               |

> ✅ Required | ⚠️ Optional (feature won't work without it)

---

## 🗺️ Sprint Roadmap

| Sprint   | Status  | Features                                                        |
| -------- | ------- | --------------------------------------------------------------- |
| Sprint 1 | ✅ Done | Auth, Kos Setup, Rooms, Tenants, Flutter UI                     |
| Sprint 2 | ✅ Done | Billing, Penalties, Add-ons, Notifications, WA/Email            |
| Sprint 3 | ✅ Done | Analytics, Payment History, CSV Export, Google Sheets           |
| Sprint 4 | ✅ Done | Tenant Portal, Simulated Payment, Multi-property, MVVM Refactor |

### Remaining Features (for team to continue)

- [ ] Edit + Delete for Kos, Room Types, Rooms, Tenants, Add-ons
- [ ] Reactivate deactivated tenants/rooms
- [ ] In-app CSV download (no Postman needed)
- [ ] Adjustable server IP via Settings screen
- [ ] Password security (min 8 chars, strength indicator)
- [ ] Tenant self-registration with Kos ID
- [ ] Custom late penalty rate (owner configurable)
- [ ] Billing time range filters (day/week/month/year/custom)
- [ ] Real payment gateway (Midtrans)
- [ ] App icon + splash screen + release APK
- [ ] Push notifications (FCM)

---

## 🐛 Known Issues & TODO

- [ ] Token persistence on app restart (auto-login)
- [ ] Email notifications require Gmail App Password
- [ ] Payment is simulated — real gateway (Midtrans) needs merchant account
- [ ] Google Sheets sync requires Google Cloud service account setup
- [ ] Phone numbers must be in format `628xxxxxxxxxx` for WhatsApp
- [ ] No pagination yet on long lists

---

## 👥 Team & Contribution

### How to contribute

1. Pull latest from `main`
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes
4. Test thoroughly using the testing checklist in `TESTING.md`
5. Push and open a Pull Request

### Branch naming convention

```
feature/   → new features
fix/       → bug fixes
refactor/  → code improvements
docs/      → documentation only
```

### Commit message format

```
feat: add tenant deactivation screen
fix: duplicate bill generation bug
refactor: move billing logic to service layer
docs: update API reference
```

---

## 📋 Testing

See `TESTING.md` for the full 13-block testing checklist covering all features end to end.

---

## 📄 License

MIT License — free to use and modify.
