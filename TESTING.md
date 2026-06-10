# 🧪 Testing Checklist

Full end-to-end testing guide for the Kos Management System.

---

## Before You Start

**Reset the database (clean slate):**
```sql
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE notifications;
TRUNCATE TABLE bills;
TRUNCATE TABLE tenant_addons;
TRUNCATE TABLE addons;
TRUNCATE TABLE tenants;
TRUNCATE TABLE rooms;
TRUNCATE TABLE room_types;
TRUNCATE TABLE kos;
TRUNCATE TABLE owners;
SET FOREIGN_KEY_CHECKS = 1;
```

**Start backend:**
```bash
cd kos-backend
node index.js
```

**Start Flutter app:**
```bash
cd kos_management
flutter run
```

---

## Block 1 — Auth

| # | Test | Expected |
|---|---|---|
| 1.1 | Open app | Role Select screen appears |
| 1.2 | Tap Owner | Goes to login screen |
| 1.3 | Back button on login | Returns to role select |
| 1.4 | Tap Register → fill name/email/password | Account created, success message |
| 1.5 | Login with wrong password | Error message shown |
| 1.6 | Login with correct credentials | Lands on Dashboard |
| 1.7 | Kill app → reopen | Stays logged in (token persisted) |
| 1.8 | Logout | Returns to role select |

---

## Block 2 — Kos Setup

| # | Test | Expected |
|---|---|---|
| 2.1 | Dashboard → Kos Setup → create "Kos Melati" with address | Success message |
| 2.2 | Add room types: Standard Rp800.000 / VIP Rp1.200.000 | Both appear in list |
| 2.3 | Return to Dashboard | Welcome card shows "Kos Melati" |
| 2.4 | Check property switcher | Shows "Kos Melati" (no dropdown yet) |

---

## Block 3 — Rooms

| # | Test | Expected |
|---|---|---|
| 3.1 | Dashboard → Rooms → add A01 (Standard) | Room created |
| 3.2 | Add A02 (Standard) | Room created |
| 3.3 | Add B01 (VIP) | Room created |
| 3.4 | Check room list | All 3 show 🟢 Available |
| 3.5 | Scroll room list | List is scrollable |
| 3.6 | Back button | Returns to Dashboard |

---

## Block 4 — Tenants

| # | Test | Expected |
|---|---|---|
| 4.1 | Dashboard → Tenants → tap + | Add tenant form opens |
| 4.2 | Add "Andi Pratama" / andi@gmail.com / 628123456789 / A01 / today | Tenant created |
| 4.3 | Check room list | A01 shows 🔴 Occupied |
| 4.4 | Add "Budi Santoso" / B01 / today | Tenant created |
| 4.5 | Check tenant list | Both tenants visible |
| 4.6 | Scroll tenant list | List is scrollable |
| 4.7 | Back button | Returns to Dashboard |

---

## Block 5 — Add-ons

| # | Test | Expected |
|---|---|---|
| 5.1 | Dashboard → Add-ons → create Parkir Rp50.000, Laundry Rp75.000, AC Rp100.000 | All created |
| 5.2 | Check addon list | All 3 with correct prices |
| 5.3 | Tenants → Andi → Manage Add-ons | Toggle screen opens |
| 5.4 | Toggle Parkir Motor ON | Green border appears, total updates |
| 5.5 | Toggle Laundry ON | Total increases |
| 5.6 | Toggle Laundry OFF | Total decreases |
| 5.7 | Leave Parkir Motor ON for Andi | — |
| 5.8 | Back button | Returns to tenant list |

---

## Block 6 — Billing

| # | Test | Expected |
|---|---|---|
| 6.1 | Dashboard → Billing → tap Generate | Spinner shows |
| 6.2 | Check terminal | ✅ Andi: Rp850.000, ✅ Budi: Rp1.200.000 |
| 6.3 | Check billing screen | Both bills under Unpaid tab |
| 6.4 | Check summary cards | Correct totals |
| 6.5 | Tap Generate again | Terminal shows "Already exists" |
| 6.6 | Tap Mark Paid on Andi's bill | Bill updates |
| 6.7 | Check Paid tab | Andi's bill appears |
| 6.8 | Scroll billing screen | List is scrollable |
| 6.9 | Back button | Returns to Dashboard |

---

## Block 7 — Notifications

| # | Test | Expected |
|---|---|---|
| 7.1 | After generating bills | Bell icon shows red badge |
| 7.2 | Tap bell icon | Notification screen opens |
| 7.3 | Check notification types | 🟢 bill_generated icons |
| 7.4 | Tap Mark all read | Badge clears |
| 7.5 | WhatsApp check | Message received on tenant phone |
| 7.6 | Email check | Email received (if real email used) |
| 7.7 | Back button | Returns to Dashboard |

---

## Block 8 — Payment (Tenant Portal)

| # | Test | Expected |
|---|---|---|
| 8.1 | Role Select → Tenant | Tenant login screen |
| 8.2 | Tap "Set up your password" | Setup screen opens |
| 8.3 | Enter andi@gmail.com + new password | Password set successfully |
| 8.4 | Login as Andi | Tenant home screen |
| 8.5 | Check current bill card | Shows Budi's unpaid bill details |
| 8.6 | Tap Pay Now | Payment method screen |
| 8.7 | Select QRIS → tap Pay Now | 2-second processing animation |
| 8.8 | Check success dialog | Payment successful message |
| 8.9 | Tap Done | Returns to tenant home, bill gone from current |
| 8.10 | Check bill history | Bill appears as Paid |

---

## Block 9 — Analytics

| # | Test | Expected |
|---|---|---|
| 9.1 | Dashboard → Analytics | Screen loads |
| 9.2 | Check occupancy rate | 2/3 = 66% (A01+B01 occupied, A02 free) |
| 9.3 | Check monthly income | Rp850.000 (Andi paid) |
| 9.4 | Check 6-month chart | Bar chart renders |
| 9.5 | Check recent activity | Last 5 bills listed |
| 9.6 | Scroll screen | Scrollable |
| 9.7 | Back button | Returns to Dashboard |

---

## Block 10 — Payment History

| # | Test | Expected |
|---|---|---|
| 10.1 | Tenants → Andi → History | History screen opens |
| 10.2 | Check Andi's history | Bill shows as Paid |
| 10.3 | Back → Budi → History | History screen opens |
| 10.4 | Check Budi's history | Bill shows as Unpaid |
| 10.5 | Back button | Returns to tenant list |

---

## Block 11 — Export

| # | Test | Expected |
|---|---|---|
| 11.1 | Dashboard → Export | Export screen |
| 11.2 | Copy bills URL + token → Postman GET | CSV file downloads |
| 11.3 | Open CSV in Excel | Correct columns: ID, Tenant, Room, Month, etc. |
| 11.4 | Copy tenants URL → Postman GET | CSV downloads |
| 11.5 | Open CSV | Correct tenant data |
| 11.6 | Tap Sync to Google Sheets | Success message + sheet updated |
| 11.7 | Open Google Sheet | Bills + Tenants tabs populated |
| 11.8 | Back button | Returns to Dashboard |

---

## Block 12 — Multi-Property

| # | Test | Expected |
|---|---|---|
| 12.1 | Kos Setup → create "Kos Mawar" | Second property created |
| 12.2 | Dashboard property switcher | Dropdown appears |
| 12.3 | Switch to Kos Mawar | Rooms/Tenants/Billing all empty |
| 12.4 | Switch back to Kos Melati | All original data returns |
| 12.5 | Add a room to Kos Mawar | Room only appears under Kos Mawar |

---

## Block 13 — Tenant Deactivation

| # | Test | Expected |
|---|---|---|
| 13.1 | Tenants → Budi → Deactivate | Confirmation dialog |
| 13.2 | Confirm deactivation | Budi removed from active list |
| 13.3 | Check room list | B01 flips to 🟢 Available |
| 13.4 | Add tenant → check room dropdown | B01 reappears as option |
| 13.5 | Check Budi's history | Bills still visible |

---

## Reporting Bugs

When reporting a bug, include:
1. Block number and test number (e.g. Block 6, Test 6.2)
2. What you expected
3. What actually happened
4. Terminal output if backend error
5. Screenshot if UI issue

Create a GitHub Issue with label `bug`.
