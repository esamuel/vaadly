"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.exportUsersCsvDev = exports.generatePasswordResetLinkForOwner = exports.listUsersForOwner = exports.syncClaimsOnMembershipWrite = exports.seedMembership = exports.mcp_execute = exports.mcp_tools = exports.mcp_ping = exports.health = exports.ai_intake = exports.sendNotifyEnhanced = exports.sendNotify = exports.payments = exports.dispatchCron = exports.onWorkOrderCreate = void 0;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions/v2"));
const https_1 = require("firebase-functions/v2/https");
const classify_1 = require("./classify");
const dispatch_1 = require("./dispatch");
const webhooks_1 = require("./webhooks");
const notify_1 = require("./notify");
const notify_enhanced_1 = require("./notify_enhanced");
const ai_intake_1 = require("./ai_intake");
const mcp_1 = require("./mcp");
// Initialize Firebase Admin
admin.initializeApp();
// Helpers to read runtime config (env or functions.config)
function getConfigNamespace() {
    // @ts-ignore - v2 keeps compat layer for functions.config()
    const cfg = functions.config ? functions.config() : {};
    return cfg && cfg.vaadly ? cfg.vaadly : {};
}
function getAdminUids() {
    const fromEnv = (process.env.PLATFORM_ADMIN_UIDS || '').split(',').map((s) => s.trim()).filter(Boolean);
    const ns = getConfigNamespace();
    const fromCfg = (ns.platform_admin_uids || '').split(',').map((s) => String(s).trim()).filter(Boolean);
    const all = [...fromEnv, ...fromCfg];
    return Array.from(new Set(all));
}
function getSeedKey() {
    const envKey = process.env.SEED_ADMIN_KEY;
    const ns = getConfigNamespace();
    const cfgKey = ns.seed_admin_key;
    return envKey || cfgKey;
}
// Trigger: classify on new work order
exports.onWorkOrderCreate = functions.firestore
    .onDocumentCreated('buildings/{buildingId}/work_orders/{workOrderId}', async (event) => {
    const { buildingId, workOrderId } = event.params;
    await (0, classify_1.classifyWorkOrder)(buildingId, workOrderId);
});
// Scheduled: dispatch pending work orders (or chain after classify)
exports.dispatchCron = functions.scheduler
    .onSchedule('every 1 minutes', async () => {
    await (0, dispatch_1.dispatchWorkOrder)();
});
// HTTPS: payment provider webhook
exports.payments = functions.https.onRequest(webhooks_1.paymentWebhook);
// HTTPS: send email/push notifications
exports.sendNotify = functions.https.onRequest(notify_1.notify);
// HTTPS: enhanced notifications with targeting and analytics
exports.sendNotifyEnhanced = functions.https.onRequest(notify_enhanced_1.notifyEnhanced);
// HTTPS: AI resident intake (Hebrew NL -> structured work order)
exports.ai_intake = ai_intake_1.aiIntake;
// Health check endpoint
exports.health = functions.https.onRequest((req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        service: 'vaadly-functions'
    });
});
// ========== MCP HTTP STUBS ==========
exports.mcp_ping = mcp_1.mcpPing;
exports.mcp_tools = mcp_1.mcpTools;
exports.mcp_execute = mcp_1.mcpExecute;
// Helper: ensure caller is an App Owner (for callable functions)
async function ensureAppOwnerFromAuth(auth) {
    const email = String(auth?.token?.email || '').toLowerCase().trim();
    if (!email)
        throw new https_1.HttpsError('unauthenticated', 'Sign in required');
    const snap = await admin
        .firestore()
        .collection('app_owners')
        .where('email', '==', email)
        .where('isActive', '==', true)
        .limit(1)
        .get();
    if (snap.empty)
        throw new https_1.HttpsError('permission-denied', 'Owner access required');
}
// HTTPS: Admin seeding endpoint to create/update a membership
// Protection: requires header x-admin-key == SEED_ADMIN_KEY
exports.seedMembership = functions.https.onRequest(async (req, res) => {
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
        };
        let ref;
        if (id) {
            ref = admin.firestore().collection('memberships').doc(id);
            await ref.set(payload, { merge: true });
        }
        else {
            ref = await admin.firestore().collection('memberships').add(payload);
        }
        res.json({ ok: true, id: ref.id });
    }
    catch (e) {
        console.error('seedMembership error', e);
        res.status(500).json({ error: e?.message || 'internal_error' });
    }
});
// Firestore: Sync memberships -> custom claims
// Keeps rolesByBuilding, buildings list, and platformAdmin (allowlisted) in user claims
exports.syncClaimsOnMembershipWrite = functions.firestore
    .onDocumentWritten('memberships/{id}', async (event) => {
    const after = event.data?.after?.data();
    const before = event.data?.before?.data();
    const userId = (after || before)?.userId;
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
    const rolesByBuilding = {};
    const buildings = [];
    snap.forEach((doc) => {
        const d = doc.data();
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
exports.listUsersForOwner = (0, https_1.onCall)(async (request) => {
    await ensureAppOwnerFromAuth(request.auth);
    // Firestore profiles
    const usersSnap = await admin.firestore().collection('users').get();
    const profiles = usersSnap.docs.map((d) => {
        const u = d.data();
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
    const authInfoByEmail = {};
    let pageToken;
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
exports.generatePasswordResetLinkForOwner = (0, https_1.onCall)(async (request) => {
    await ensureAppOwnerFromAuth(request.auth);
    const email = String(request.data?.email ?? '').toLowerCase().trim();
    if (!email)
        throw new https_1.HttpsError('invalid-argument', 'email required');
    const link = await admin.auth().generatePasswordResetLink(email, {
        url: 'https://vaadly.app/',
        handleCodeInApp: false,
    });
    return { resetLink: link };
});
// HTTP (dev-only): export users as CSV, protected by x-admin-key
exports.exportUsersCsvDev = functions.https.onRequest(async (req, res) => {
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
        const profiles = usersSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
        // Auth info map
        const authInfoByEmail = {};
        let pageToken;
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
    }
    catch (e) {
        console.error('exportUsersCsvDev error', e);
        res.status(500).json({ error: e?.message || 'internal_error' });
    }
});
function csvEscape(value) {
    const s = String(value ?? '');
    if (s.includes(',') || s.includes('"') || s.includes('\n')) {
        return '"' + s.replace(/"/g, '""') + '"';
    }
    return s;
}
//# sourceMappingURL=index.js.map