import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions/v2';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { classifyWorkOrder } from './classify';
import { dispatchWorkOrder } from './dispatch';
import { paymentWebhook } from './webhooks';
import { notify } from './notify';
import { notifyEnhanced } from './notify_enhanced';
import { aiIntake } from './ai_intake';

// Initialize Firebase Admin
admin.initializeApp();

// Helpers to read runtime config (env or functions.config)
function getConfigNamespace(): any {
  // @ts-ignore - v2 keeps compat layer for functions.config()
  const cfg = (functions as any).config ? (functions as any).config() : {};
  return cfg && cfg.vaadly ? cfg.vaadly : {};
}

function getAdminUids(): string[] {
  const fromEnv = (process.env.PLATFORM_ADMIN_UIDS || '').split(',').map((s) => s.trim()).filter(Boolean);
  const ns = getConfigNamespace();
  const fromCfg = (ns.platform_admin_uids || '').split(',').map((s: string) => String(s).trim()).filter(Boolean);
  const all = [...fromEnv, ...fromCfg];
  return Array.from(new Set(all));
}

function getSeedKey(): string | undefined {
  const envKey = process.env.SEED_ADMIN_KEY;
  const ns = getConfigNamespace();
  const cfgKey = ns.seed_admin_key;
  return envKey || cfgKey;
}

// Trigger: classify on new work order
export const onWorkOrderCreate = functions.firestore
  .onDocumentCreated('buildings/{buildingId}/work_orders/{workOrderId}', async (event) => {
    const { buildingId, workOrderId } = event.params;
    await classifyWorkOrder(buildingId, workOrderId);
  });

// Scheduled: dispatch pending work orders (or chain after classify)
export const dispatchCron = functions.scheduler
  .onSchedule('every 1 minutes', async () => {
    await dispatchWorkOrder();
  });

// HTTPS: payment provider webhook
export const payments = functions.https.onRequest(paymentWebhook);

// HTTPS: send email/push notifications
export const sendNotify = functions.https.onRequest(notify);

// HTTPS: enhanced notifications with targeting and analytics
export const sendNotifyEnhanced = functions.https.onRequest(notifyEnhanced);

// HTTPS: AI resident intake (Hebrew NL -> structured work order)
export const ai_intake = aiIntake;

// Health check endpoint
export const health = functions.https.onRequest((req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    service: 'vaadly-functions'
  });
});

// Helper: ensure caller is an App Owner (for callable functions)
async function ensureAppOwnerFromAuth(auth: any) {
  const email = String(auth?.token?.email || '').toLowerCase().trim();
  if (!email) throw new HttpsError('unauthenticated', 'Sign in required');
  const snap = await admin
    .firestore()
    .collection('app_owners')
    .where('email', '==', email)
    .where('isActive', '==', true)
    .limit(1)
    .get();
  if (snap.empty) throw new HttpsError('permission-denied', 'Owner access required');
}

// HTTPS: Admin seeding endpoint to create/update a membership
// Protection: requires header x-admin-key == SEED_ADMIN_KEY
export const seedMembership = functions.https.onRequest(async (req, res) => {
  const key = req.header('x-admin-key');
  const secret = getSeedKey();
  if (!secret || key !== secret) {
    res.status(403).json({ error: 'forbidden' });
    return;
  }
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'method_not_allowed' });
    return;
  }
  try {
    const { userId, buildingId, role = 'committee', status = 'active', id } = req.body || {};
    if (!userId || !buildingId) {
      res.status(400).json({ error: 'missing userId/buildingId' });
      return;
    }

    const payload = {
      userId,
      buildingId,
      role,
      status,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    } as any;

    let ref: FirebaseFirestore.DocumentReference;
    if (id) {
      ref = admin.firestore().collection('memberships').doc(id);
      await ref.set(payload, { merge: true });
    } else {
      ref = await admin.firestore().collection('memberships').add(payload);
    }

    res.json({ ok: true, id: ref.id });
  } catch (e: any) {
    console.error('seedMembership error', e);
    res.status(500).json({ error: e?.message || 'internal_error' });
  }
});

// Firestore: Sync memberships -> custom claims
// Keeps rolesByBuilding, buildings list, and platformAdmin (allowlisted) in user claims
export const syncClaimsOnMembershipWrite = functions.firestore
  .onDocumentWritten('memberships/{id}', async (event) => {
    const after = event.data?.after?.data() as any | undefined;
    const before = event.data?.before?.data() as any | undefined;
    const userId: string | undefined = (after || before)?.userId;

    if (!userId) {
      console.warn('syncClaimsOnMembershipWrite: missing userId');
      return;
    }

    const snap = await admin
      .firestore()
      .collection('memberships')
      .where('userId', '==', userId)
      .where('status', '==', 'active')
      .get();

    const rolesByBuilding: Record<string, string> = {};
    const buildings: string[] = [];
    snap.forEach((doc) => {
      const d = doc.data() as any;
      if (d?.buildingId && d?.role) {
        rolesByBuilding[d.buildingId] = d.role;
        buildings.push(d.buildingId);
      }
    });

    const adminAllow = getAdminUids();
    const platformAdmin = adminAllow.includes(userId);

    await admin.auth().setCustomUserClaims(userId, {
      platformAdmin,
      buildings,
      rolesByBuilding,
    });
  });

// ========== DEV/OWNER ADMIN ENDPOINTS (SAFE: NO PASSWORDS) ==========

// Callable: list users (owner-only)
export const listUsersForOwner = onCall(async (request) => {
  await ensureAppOwnerFromAuth(request.auth);

  // Firestore profiles
  const usersSnap = await admin.firestore().collection('users').get();
  const profiles = usersSnap.docs.map((d) => {
    const u = d.data() as any;
    return {
      id: d.id,
      name: u.name ?? '',
      email: String(u.email ?? '').toLowerCase(),
      role: u.role ?? 'unknown',
      isActive: Boolean(u.isActive),
      buildingAccess: u.buildingAccess ?? {},
      lastLogin: u.lastLogin?.toDate?.()?.toISOString?.() ?? null,
      createdAt: u.createdAt?.toDate?.()?.toISOString?.() ?? null,
      updatedAt: u.updatedAt?.toDate?.()?.toISOString?.() ?? null,
    };
  });

  // Auth info by email
  const authInfoByEmail: Record<string, any> = {};
  let pageToken: string | undefined;
  do {
    const res = await admin.auth().listUsers(1000, pageToken);
    res.users.forEach((u) => {
      if (u.email) {
        authInfoByEmail[u.email.toLowerCase()] = {
          uid: u.uid,
          emailVerified: u.emailVerified,
          disabled: u.disabled,
          lastSignInTime: u.metadata?.lastSignInTime ?? null,
          providerIds: u.providerData.map((p) => p.providerId),
        };
      }
    });
    pageToken = res.pageToken;
  } while (pageToken);

  const merged = profiles.map((p) => ({
    ...p,
    auth: authInfoByEmail[p.email] ?? null,
  }));

  return { users: merged };
});

// Callable: generate password reset link for a user (owner-only)
export const generatePasswordResetLinkForOwner = onCall(async (request) => {
  await ensureAppOwnerFromAuth(request.auth);
  const email = String(request.data?.email ?? '').toLowerCase().trim();
  if (!email) throw new HttpsError('invalid-argument', 'email required');

  const link = await admin.auth().generatePasswordResetLink(email, {
    url: 'https://vaadly.app/',
    handleCodeInApp: false,
  });
  return { resetLink: link };
});

// HTTP (dev-only): export users as CSV, protected by x-admin-key
export const exportUsersCsvDev = functions.https.onRequest(async (req, res) => {
  const key = req.header('x-admin-key');
  const secret = getSeedKey();
  if (!secret || key !== secret) {
    res.status(403).json({ error: 'forbidden' });
    return;
  }
  if (req.method !== 'GET') {
    res.status(405).json({ error: 'method_not_allowed' });
    return;
  }

  try {
    // Firestore users
    const usersSnap = await admin.firestore().collection('users').get();
    const profiles = usersSnap.docs.map((d) => ({ id: d.id, ...(d.data() as any) }));

    // Auth info map
    const authInfoByEmail: Record<string, any> = {};
    let pageToken: string | undefined;
    do {
      const resUsers = await admin.auth().listUsers(1000, pageToken);
      resUsers.users.forEach((u) => {
        if (u.email) {
          authInfoByEmail[u.email.toLowerCase()] = u;
        }
      });
      pageToken = resUsers.pageToken;
    } while (pageToken);

    const headers = [
      'name',
      'email',
      'role',
      'isActive',
      'lastLogin',
      'uid',
      'emailVerified',
      'disabled'
    ];

    const rows = profiles.map((p) => {
      const email = String(p.email ?? '').toLowerCase();
      const auth = authInfoByEmail[email];
      const lastLogin = p.lastLogin?.toDate?.()?.toISOString?.() ?? '';
      const values = [
        p.name ?? '',
        email,
        p.role ?? '',
        String(Boolean(p.isActive)),
        lastLogin,
        auth?.uid ?? '',
        String(Boolean(auth?.emailVerified)),
        String(Boolean(auth?.disabled)),
      ];
      return values.map(csvEscape).join(',');
    });

    const csv = [headers.join(','), ...rows].join('\n');
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.status(200).send(csv);
  } catch (e: any) {
    console.error('exportUsersCsvDev error', e);
    res.status(500).json({ error: e?.message || 'internal_error' });
  }
});

function csvEscape(value: any): string {
  const s = String(value ?? '');
  if (s.includes(',') || s.includes('"') || s.includes('\n')) {
    return '"' + s.replace(/"/g, '""') + '"';
  }
  return s;
}
