# Contributing Guide

Welcome to the Kos Management System. This guide helps team members get started quickly.

---

## Quick Start

1. Clone the repo
2. Follow README.md setup steps for both backend and Flutter
3. Ask the team lead for the `.env` file — never share it publicly
4. Run both backend and app — verify the testing checklist passes

---

## Git Workflow

### Branch from main

```bash
git checkout main
git pull origin main
git checkout -b feature/your-feature-name
```

### Branch naming

```
feature/add-push-notifications
fix/duplicate-bill-bug
refactor/tenant-list-pagination
docs/update-api-reference
```

### Commit messages

Follow this format:

```
type: short description

feat:     new feature
fix:      bug fix
refactor: code improvement (no behavior change)
docs:     documentation only
test:     adding or fixing tests
chore:    build, config, dependencies
```

Examples:

```
feat: add tenant deactivation confirmation dialog
fix: bill not showing after generate on slow network
refactor: extract billing logic into separate service
docs: add Google Sheets setup steps to README
```

### Open a Pull Request

- Target branch: `main`
- Fill in the PR template
- Link to the GitHub Issue if fixing a bug
- Request review from at least one team member

---

## Code Standards

### Flutter (Dart)

- Follow MVVM strictly: Screens → Providers → Repositories → Services
- Never call a Service directly from a Screen — always go through Provider
- Keep Screens as dumb as possible — logic belongs in Provider/Repository
- Use `const` constructors wherever possible
- Name files in `snake_case`: `tenant_list_screen.dart`
- Name classes in `PascalCase`: `TenantListScreen`

### Node.js

- Keep Controllers thin — business logic belongs in Services or Models
- Always handle errors — never leave a callback with unhandled `err`
- Never return raw database errors to the client
- Use `async/await` for new code — avoid mixing with callbacks
- Environment variables only through `.env` — never hardcode credentials

---

## Architecture Rules

### Frontend MVVM

```
Screen (View)
  ↓ calls
Provider (ViewModel)
  ↓ calls
Repository (Data logic)
  ↓ calls
Service (HTTP only)
  ↓ calls
Backend API
```

### Backend MVC

```
Route
  ↓ calls
Controller (request/response only)
  ↓ calls
Model (DB queries) or Service (business logic)
  ↓ calls
Database
```

---

## Adding a New Feature

### Backend steps

1. Add DB migration if needed (document in `database/migrations/`)
2. Add/update Model in `models/`
3. Add Controller in `controllers/`
4. Add route in `routes/` and register in `index.js`
5. Test with Postman

### Flutter steps

1. Add Service method in `services/`
2. Add Repository method in `repositories/`
3. Add Provider method in `providers/`
4. Build Screen in `screens/`
5. Register in `main.dart` if new Provider needed
6. Link from Dashboard or navigation flow

---

## What's Left to Build

All items below have a corresponding GitHub Issue. Pick one, create a branch, build it, open a PR.

### Priority 1 — Quick wins (1 hr each)

- [ ] **Issue #3** — Adjustable server IP via Settings screen (needed for physical device testing)
- [ ] **Issue #2** — In-app CSV download, no Postman needed (dio + path_provider)
- [ ] **Issue #4** — Password security (min 8 chars, 1 number, 1 uppercase, strength bar)
- [ ] **Issue #9** — App icon + splash screen + release APK

### Priority 2 — CRUD (2-3 hrs total)

- [ ] **Issue #1** — Edit + Delete Kos property
- [ ] **Issue #1** — Edit + Delete Room Types
- [ ] **Issue #1** — Edit + Delete Rooms (only if Available)
- [ ] **Issue #1** — Edit + Delete Tenants + Reactivate inactive tenants
- [ ] **Issue #1** — Edit + Delete Add-ons

### Priority 3 — Business logic (2 hrs each)

- [ ] **Issue #6** — Custom late penalty rate (owner sets their own Rp/day or Rp/month)
- [ ] **Issue #7** — Billing time range filters (Today/Week/Month/Year/Custom date range)
- [ ] **Issue #5** — Tenant self-registration with Kos ID (shows in owner pending list)

### Priority 4 — Payment (3-4 hrs)

- [ ] **Issue #8** — Real payment gateway (Midtrans Snap — free sandbox account needed)

---

## Current App State (v1.0.0)

### ✅ Fully working (13/13 test blocks passing)

- Owner auth — register, login, JWT, auto-login on restart
- Kos setup + room types + multi-property switcher
- Room management — add, list, status tracking
- Tenant management — add, assign, deactivate, active/inactive toggle
- Add-ons — define per kos, toggle per tenant, included in billing
- Auto billing — generates monthly on tenant's start date
- Late penalty — Rp10.000/day auto-calculated every midnight
- Notifications — in-app bell + WhatsApp + email
- Tenant portal — self-login, view bills, simulated payment
- Analytics — occupancy rate, monthly income, 6-month chart
- Payment history per tenant
- CSV export + Google Sheets sync
- MVVM architecture (services → repositories → providers → screens)

### ⚠️ Known limitations

- Payment is simulated — Midtrans integration pending (Issue #8)
- No edit/delete yet — only create (Issue #1)
- CSV requires Postman — in-app download pending (Issue #2)
- Server IP is hardcoded — Settings screen pending (Issue #3)
- Phone numbers must be 628xxxxxxxxxx format for WhatsApp
- Email needs Gmail App Password (not regular Gmail password)

---

## Environment Setup

### Getting the .env file

The `.env` file is NOT in the repo (contains real passwords). Ask the team lead for it directly. Never share it publicly or commit it.

### Testing on a physical Android device

1. Connect phone via USB or same WiFi
2. Find your computer's local IP: open CMD → `ipconfig` → copy IPv4 Address (e.g. 192.168.1.5)
3. Open `lib/config/api_config.dart` → change `_defaultHost` to your IP
4. Make sure your phone and compu

---

## Environment Setup Help

### Gmail App Password (for email notifications)

1. Go to `myaccount.google.com`
2. Security → 2-Step Verification → enable it
3. Security → App Passwords → generate for "Mail"
4. Copy the 16-character password into `.env` as `EMAIL_PASS`

### Fonnte (WhatsApp)

1. Register at `fonnte.com`
2. Connect your WhatsApp number
3. Get the API token
4. Phone numbers must be `628xxxxxxxxxx` format (no `08`)

### Google Sheets

1. `console.cloud.google.com` → create project
2. Enable Google Sheets API
3. IAM → Service Accounts → create → download JSON key
4. Share target spreadsheet with service account email (Editor)
5. Copy `client_email` and `private_key` from JSON into `.env`

---

## Getting Help

- Open a GitHub Issue for bugs
- Use the Discussions tab for questions
- Tag `@team-lead` for urgent blockers
