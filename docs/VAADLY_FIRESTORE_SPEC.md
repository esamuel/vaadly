# Vaadly Firestore Structure (3-tier Model)

This document specifies the canonical collections, schemas, auth roles/claims, security rules, Cloud Function, and required indexes for Vaadly.

## Collections
```
/users/{userId}            // user profiles
/buildings/{buildingId}    // one per building
/memberships/{id}          // user ↔ building link + role
/tickets/{ticketId}        // building issues
/invoices/{invoiceId}      // billing items
/payments/{paymentId}      // receipts
/vendors/{vendorId}        // service providers
/announcements/{id}        // building posts
/chats/{chatId}            // optional: threaded discussions
```

## Document Schemas

### users/{userId}
```json
{
  "email": "sivan@gmail.com",
  "name": "סיוון שלם",
  "phone": "+972-5x-xxxxxxx",
  "locale": "he-IL",
  "avatarUrl": "",
  "createdAt": "<serverTimestamp>",
  "lastSeenAt": "<serverTimestamp>",
  "rolesCache": [
    { "buildingId": "lz66...", "role": "committee" }
  ]
}
```

### buildings/{buildingId}
```json
{
  "name": "אירלוזר 12",
  "address": "אירלוזר 12, תל אביב",
  "buildingCode": "B-ARL12",
  "managerName": "—",
  "totalFloors": 9,
  "totalUnits": 38,
  "createdBy": "<platformAdminUid>",
  "createdAt": "<serverTimestamp>",
  "counters": { "openTickets": 0, "unpaidInvoices": 0 }
}
```

### memberships/{id}
```json
{
  "userId": "<uid>",
  "buildingId": "lz66...",
  "role": "committee",     // "resident" | "committee" | "platformAdmin"
  "unit": "12B",           // only for residents
  "status": "active",
  "createdAt": "<serverTimestamp>"
}
```

### tickets/{ticketId}
```json
{
  "buildingId": "lz66...",
  "createdBy": "<residentUid>",
  "unit": "12B",
  "title": "Leak in stairwell",
  "description": "Dripping near 3rd floor",
  "status": "open",
  "priority": "normal",
  "assignee": "<committeeUid>",
  "attachments": [{ "path": "gs://...", "mime": "image/jpeg" }],
  "createdAt": "<serverTimestamp>",
  "updatedAt": "<serverTimestamp>"
}
```

### invoices/{invoiceId}
```json
{
  "buildingId": "lz66...",
  "unit": "12B",
  "residentUid": "<uid>",
  "month": "2025-09",
  "lineItems": [
    { "desc": "Monthly dues", "amount": 250.0 },
    { "desc": "Garden upgrade", "amount": 35.0 }
  ],
  "currency": "ILS",
  "total": 285.0,
  "status": "unpaid",
  "dueDate": "2025-10-10",
  "createdAt": "<serverTimestamp>"
}
```

### payments/{paymentId}
```json
{
  "buildingId": "lz66...",
  "invoiceId": "<invoiceId>",
  "residentUid": "<uid>",
  "amount": 285.0,
  "method": "credit_card",
  "paidAt": "<serverTimestamp>",
  "receiptUrl": ""
}
```

## Roles & Claims

### Roles
- platformAdmin → full global access (you)
- committee → full access to their building
- resident → only their unit + personal invoices/tickets

### Example custom claims
```json
{
  "platformAdmin": true,
  "buildings": ["lz66...", "L8HUh..."],
  "rolesByBuilding": {
    "lz66...": "committee",
    "L8HUh...": "resident"
  }
}
```

## Firestore Security Rules
```rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function authed() { return request.auth != null; }
    function isPlatformAdmin() { return authed() && request.auth.token.platformAdmin == true; }
    function rolesByBld() { return authed() ? request.auth.token.rolesByBuilding : {}; }
    function hasRole(bid, role) { return rolesByBld()[bid] == role; }
    function inBuilding(bid) { return rolesByBld()[bid] != null || isPlatformAdmin(); }
    function isSelf(uidField) { return authed() && request.auth.uid == uidField; }

    match /users/{userId} {
      allow read: if isPlatformAdmin() || (authed() && request.auth.uid == userId);
      allow create, update: if authed() && request.auth.uid == userId;
    }

    match /buildings/{buildingId} {
      allow read: if inBuilding(buildingId);
      allow create, update: if isPlatformAdmin() || hasRole(buildingId, "committee");
    }

    match /memberships/{membershipId} {
      allow read: if isPlatformAdmin()
                  || (authed() && resource.data.userId == request.auth.uid)
                  || (authed() && hasRole(resource.data.buildingId, "committee"));
      allow create, update: if isPlatformAdmin() || hasRole(request.resource.data.buildingId, "committee");
    }

    match /tickets/{ticketId} {
      allow read: if inBuilding(resource.data.buildingId);
      allow create: if inBuilding(request.resource.data.buildingId);
      allow update: if hasRole(resource.data.buildingId, "committee")
                     || isSelf(resource.data.createdBy);
    }

    match /invoices/{invoiceId} {
      allow read: if isPlatformAdmin()
                  || hasRole(resource.data.buildingId, "committee")
                  || isSelf(resource.data.residentUid);
      allow create, update: if isPlatformAdmin() || hasRole(request.resource.data.buildingId, "committee");
    }

    match /payments/{paymentId} {
      allow read: if isPlatformAdmin()
                  || hasRole(resource.data.buildingId, "committee")
                  || isSelf(resource.data.residentUid);
      allow create: if isSelf(request.resource.data.residentUid) && inBuilding(request.resource.data.buildingId);
    }

    match /vendors/{vendorId},
          /announcements/{announcementId} {
      allow read: if inBuilding(resource.data.buildingId);
      allow create, update: if isPlatformAdmin() || hasRole(request.resource.data.buildingId, "committee");
    }
  }
}
```

## Cloud Function: Sync Memberships → Claims
```ts
// functions/src/index.ts
import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

admin.initializeApp();

export const syncClaimsOnMembershipWrite = functions.firestore
  .document('memberships/{id}')
  .onWrite(async (change, ctx) => {
    const after = change.after.exists ? change.after.data() : null;
    const before = change.before.exists ? change.before.data() : null;
    const userId = (after || before).userId;

    const snap = await admin.firestore()
      .collection('memberships')
      .where('userId', '==', userId)
      .where('status', '==', 'active')
      .get();

    const rolesByBuilding: Record<string, string> = {};
    const buildings: string[] = [];
    snap.forEach(doc => {
      const d = doc.data();
      rolesByBuilding[d.buildingId] = d.role;
      buildings.push(d.buildingId);
    });

    const platformAdmin = userId === '<YOUR_UID>';

    await admin.auth().setCustomUserClaims(userId, {
      platformAdmin,
      buildings,
      rolesByBuilding
    });
  });
```

## Indexes Needed
- tickets: buildingId, status, createdAt
- invoices: buildingId, status, month
- payments: buildingId, paidAt
- memberships: userId, status

---

This file is the Windsurf-ready spec to guide implementation and enforcement across app, rules, and functions.
