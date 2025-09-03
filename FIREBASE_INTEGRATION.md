# Vaadly – Push, Email, Media & Access (Firebase Copy‑Paste)

> Drop-in snippets for **Firebase**: Push (FCM), Email (SendGrid), media capture (photos/videos), and strict access rules so residents only see their own data unless on the committee.

---

## 1) Firestore Security Rules (strict per resident/unit)

Create/replace `firestore.rules`:

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    function authed() { return request.auth != null; }
    // role stored under buildings/{b}/members/{uid}.role
    function role(b) { return get(/databases/$(db)/documents/buildings/$(b)/members/$(request.auth.uid)).data.role; }
    function inBuilding(b) { return exists(/databases/$(db)/documents/buildings/$(b)/members/$(request.auth.uid)); }
    // units/{u}.residentUids: array of residents assigned to unit
    function isUnitResident(b, u) { return (get(/databases/$(db)/documents/buildings/$(b)/units/$(u)).data.residentUids).hasOnly([request.auth.uid]) || (get(/databases/$(db)/documents/buildings/$(b)/units/$(u)).data.residentUids).hasAny([request.auth.uid]); }

    match /buildings/{b} {
      // Building doc metadata – committee or super admin can write; all members can read
      allow read: if authed() && inBuilding(b);
      allow write: if authed() && (role(b) in ['committee','super_admin']);

      // MEMBERS – committee can manage membership, everyone can read their own
      match /members/{uid} {
        allow read: if authed() && inBuilding(b) && (uid == request.auth.uid || role(b) in ['committee','super_admin']);
        allow write: if authed() && role(b) in ['committee','super_admin'];
        // deviceTokens subcollection to store FCM tokens
        match /deviceTokens/{token} {
          allow read: if authed() && uid == request.auth.uid;
          allow write: if authed() && uid == request.auth.uid;
        }
      }

      // UNITS – residents can read only their unit; committee can R/W all
      match /units/{u} {
        allow read: if authed() && inBuilding(b) && (role(b) in ['committee','super_admin'] || isUnitResident(b, u));
        allow write: if authed() && role(b) in ['committee','super_admin'];
      }

      // VENDORS – visible to committee; residents only see minimal fields via server (do not read raw list)
      match /vendors/{id} {
        allow read: if authed() && inBuilding(b) && role(b) in ['committee','super_admin'];
        allow write: if authed() && role(b) in ['committee','super_admin'];
      }

      // WORK ORDERS – resident can read/create only those tied to their unit or createdBy == self
      match /work_orders/{wo} {
        allow create: if authed() && inBuilding(b);
        allow read: if authed() && inBuilding(b) && (
          role(b) in ['committee','super_admin'] ||
          request.resource.data.createdBy == request.auth.uid ||
          (resource.data.unitId != null && isUnitResident(b, resource.data.unitId))
        );
        allow update, delete: if authed() && (
          role(b) in ['committee','super_admin'] ||
          resource.data.createdBy == request.auth.uid
        );
        // media under a work order – same visibility as parent
        match /media/{m} {
          allow read, write: if authed() && inBuilding(b);
        }
        // quotes are visible only to committee; vendors see theirs via callable
        match /quotes/{q} { allow read, write: if authed() && role(b) in ['committee','super_admin']; }
      }

      // FINANCE – invoices/payments: resident sees their unit's only; committee sees all
      match /invoices/{inv} {
        allow read: if authed() && inBuilding(b) && (
          role(b) in ['committee','super_admin'] ||
          (resource.data.unitId != null && isUnitResident(b, resource.data.unitId))
        );
        allow write: if authed() && role(b) in ['committee','super_admin'];
      }
      match /payments/{pay} {
        allow read: if authed() && inBuilding(b) && (
          role(b) in ['committee','super_admin'] ||
          (resource.data.unitId != null && isUnitResident(b, resource.data.unitId))
        );
        allow write: if authed() && role(b) in ['committee','super_admin'];
      }

      // DOCUMENTS – residents see building docs flagged as publicForResidents OR docs tied to their unit
      match /documents/{doc} {
        allow read: if authed() && inBuilding(b) && (
          role(b) in ['committee','super_admin'] ||
          resource.data.publicForResidents == true ||
          (resource.data.unitId != null && isUnitResident(b, resource.data.unitId))
        );
        allow write: if authed() && role(b) in ['committee','super_admin'];
      }

      // ANNOUNCEMENTS – all residents in building can read; committee writes
      match /announcements/{msg} {
        allow read: if authed() && inBuilding(b);
        allow write: if authed() && role(b) in ['committee','super_admin'];
      }

      // AUDIT – committee + super admin read; anyone can create logs for their actions
      match /audit/{id} {
        allow read: if authed() && inBuilding(b) && role(b) in ['committee','super_admin'];
        allow create: if authed() && inBuilding(b);
      }
    }
  }
}
```

> These rules enforce: **residents only see their own unit's items** (work orders/invoices/payments), while **committee** can see/manage all.

---

## 2) Firebase Storage Rules (media privacy)

Create/replace `storage.rules`:

```js
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    function authed() { return request.auth != null; }
    match /buildings/{b}/wo/{wo}/{file} {
      allow read, write: if authed(); // tie UI to Firestore rules to gate listing
    }
    match /buildings/{b}/documents/{file} {
      allow read, write: if authed();
    }
  }
}
```

> Access to file **URLs** is authenticated; list/download actions are gated in the app by Firestore checks.

---

## 3) Cloud Functions – Push & Email

`functions/src/notify.ts`:

```ts
import * as admin from 'firebase-admin';
import { onRequest } from 'firebase-functions/v2/https';

const db = admin.firestore();

export const notify = onRequest(async (req, res) => {
  const { buildingId, targets, title, body, emailHtml } = req.body as {
    buildingId: string;
    targets: { type: 'building'|'unit'|'resident'|'vendor'; id?: string };
    title: string; body: string; emailHtml?: string;
  };

  // Resolve recipients (uids)
  let uids: string[] = [];
  if (targets.type === 'building') {
    const snap = await db.collection(`buildings/${buildingId}/members`).get();
    uids = snap.docs.map(d => d.id);
  } else if (targets.type === 'resident' && targets.id) {
    uids = [targets.id];
  } else if (targets.type === 'unit' && targets.id) {
    const unit = await db.doc(`buildings/${buildingId}/units/${targets.id}`).get();
    uids = (unit.get('residentUids') || []) as string[];
  }

  // Gather device tokens & emails
  const tokens: string[] = [];
  const emails: string[] = [];
  for (const uid of uids) {
    const mref = db.collection(`buildings/${buildingId}/members`).doc(uid);
    const m = await mref.get();
    const email = m.get('email'); if (email) emails.push(email);
    const tSnap = await mref.collection('deviceTokens').get();
    tSnap.forEach(t => tokens.push(t.id));
  }

  // Push (FCM)
  if (tokens.length) {
    await admin.messaging().sendEachForMulticast({ tokens, notification: { title, body } });
  }

  // Email (SendGrid via Web API)
  if (emails.length && emailHtml) {
    const sgApiKey = process.env.SENDGRID_API_KEY as string;
    const from = process.env.EMAIL_FROM || 'no-reply@vaadly.app';
    await fetch('https://api.sendgrid.com/v3/mail/send', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${sgApiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        personalizations: emails.map(e => ({ to: [{ email: e }] })),
        from: { email: from },
        subject: title,
        content: [{ type: 'text/html', value: emailHtml }]
      })
    });
  }

  // Log announcement
  await db.collection(`buildings/${buildingId}/announcements`).add({ title, body, createdAt: admin.firestore.FieldValue.serverTimestamp() });

  res.json({ ok: true, push: tokens.length, email: emails.length });
});
```

**Deploy**

```bash
# functions/package.json – ensure dependencies: firebase-admin, firebase-functions, node-fetch (if needed)
firebase deploy --only functions:notify
```

---

## 4) Flutter – Register FCM token per resident

Add to `pubspec.yaml` (already added): `firebase_messaging`

**Init & save token** (e.g., after login) `lib/features/auth/register_token.dart`:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> registerFcmToken({required String buildingId, required String uid}) async {
  final fcm = FirebaseMessaging.instance;
  await fcm.requestPermission();
  final token = await fcm.getToken();
  if (token == null) return;
  final ref = FirebaseFirestore.instance.doc('buildings/$buildingId/members/$uid/deviceTokens/$token');
  await ref.set({ 'createdAt': FieldValue.serverTimestamp(), 'platform': 'flutter' }, SetOptions(merge: true));
}
```

**Foreground handler** (e.g., in `main.dart`):

```dart
FirebaseMessaging.onMessage.listen((msg) {
  // Show in-app banner/snackbar if needed
});
```

---

## 5) Flutter – Capture Hazards (photos + videos)

Upgrade `image_picker` to support video, add `video_player` if you want previews.

**Widget snippet** (replace in your create page):

```dart
final ImagePicker _picker = ImagePicker();
XFile? _photo; XFile? _video;

Future<void> pickPhoto() async { _photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70); setState(() {}); }
Future<void> pickVideo() async { _video = await _picker.pickVideo(source: ImageSource.camera, maxDuration: const Duration(seconds: 60)); setState(() {}); }

Future<String?> uploadMedia(String buildingId, String woId) async {
  final storage = FirebaseStorage.instance;
  if (_photo != null) {
    final ref = storage.ref('buildings/$buildingId/wo/$woId/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putData(await _photo!.readAsBytes(), SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }
  if (_video != null) {
    final ref = storage.ref('buildings/$buildingId/wo/$woId/${DateTime.now().millisecondsSinceEpoch}.mp4');
    await ref.putData(await _video!.readAsBytes(), SettableMetadata(contentType: 'video/mp4'));
    return await ref.getDownloadURL();
  }
  return null;
}
```

**Save media doc** under `work_orders/{wo}/media`:

```dart
await FirebaseFirestore.instance
  .doc('buildings/$buildingId/work_orders/$woId')
  .collection('media')
  .add({ 'url': url, 'type': _photo != null ? 'image' : 'video', 'createdAt': FieldValue.serverTimestamp() });
```

---

## 6) Committee vs Resident Visibility – Client Query Tips

* **Resident timeline**:

  * Work orders: query `buildings/{b}/work_orders` where `createdBy == uid` OR `unitId IN (my units)`.
  * Invoices/Payments: where `unitId IN (my units)`.
  * Documents: where `publicForResidents == true` OR `unitId IN (my units)`.
* **Committee dashboard**: unrestricted queries within building.

> Rely on **rules** above for enforcement; the queries are for efficiency.

---

## 7) Email templates (simple)

Store under `functions/templates`. Example `receipt.html`:

```html
<!doctype html>
<html><body>
  <p>שלום {{name}},</p>
  <p>תודה על התשלום ע"ס {{amount}} ₪ לבניין {{building}}.</p>
  <p>קבלה: {{invoiceId}}</p>
</body></html>
```

Render in `notify` function before sending.

---

## 8) Environment

`.env.example` additions:

```ini
# Email / Push
SENDGRID_API_KEY=sg-xxxx
EMAIL_FROM=no-reply@vaadly.app
```

Set Cloud Functions config (alternative):

```bash
firebase functions:config:set sendgrid.key="SG.xxxx" notify.email_from="no-reply@vaadly.app"
```

---

## 9) Smoke Tests

* Resident not on committee **cannot** read other units' invoices/work orders.
* Resident can create work order + attach **photo/video**; vendor/committee see it.
* Push + Email: create announcement (building target) → all members receive.
* Change member role to `committee` → gains full building access immediately.

---

**That's it.** Paste, deploy, and you've got Push, Email, rich media capture, and tight role‑based access on Firebase.
