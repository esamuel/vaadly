import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions/v2';

// Lightweight HTTP stubs to introduce an MCP-compatible surface without external deps.
// Real tool execution will be added incrementally.

const TOOL_CATALOG = [
  'getBuilding',
  'listUnits',
  'getResident',
  'listVendors',
  'createMaintenanceRequest',
  'assignVendor',
  'scheduleVisit',
  'updateRequestStatus',
  'getMaintenanceStats',
  'createOwnerVendor',
  'createCommitteeVendor',
  'createInvoice',
  'approveAndPay',
  'startVote',
  'castVote',
];

export const mcpPing = functions.https.onRequest((req, res) => {
  res.json({
    ok: true,
    service: 'vaadly-mcp',
    status: 'ready',
    timestamp: new Date().toISOString(),
  });
});

export const mcpTools = functions.https.onRequest((_req, res) => {
  res.json({ tools: TOOL_CATALOG });
});

export const mcpExecute = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'method_not_allowed' });
    return;
  }

  const { tool, input, idempotencyKey } = (req.body || {}) as {
    tool?: string;
    input?: Record<string, unknown>;
    idempotencyKey?: string;
  };

  if (!tool || !TOOL_CATALOG.includes(tool)) {
    res.status(400).json({ error: 'invalid_tool' });
    return;
  }

  // Verify Firebase ID token and derive auth context
  let authCtx: AuthContext;
  try {
    authCtx = await verifyAuth(req);
  } catch (e: any) {
    res.status(401).json({ error: 'UNAUTHENTICATED', message: e?.message || 'invalid token' });
    return;
  }

  // Basic idempotency key requirement for mutating tools (per MCP_SPEC)
  const mutating = [
    'createMaintenanceRequest',
    'assignVendor',
    'scheduleVisit',
    'updateRequestStatus',
    'createOwnerVendor',
    'createCommitteeVendor',
    'createInvoice',
    'approveAndPay',
    'startVote',
    'castVote',
  ].includes(tool);

  if (mutating && !idempotencyKey) {
    res.status(400).json({ error: 'idempotency_key_required' });
    return;
  }

  try {
    switch (tool) {
      case 'getBuilding': {
        const buildingId = String((input as any)?.buildingId || '').trim();
        if (!buildingId) {
          res.status(400).json({ error: 'INVALID_ARGUMENT', message: 'buildingId required' });
          return;
        }
        // Tenant scoping: platformAdmin may access any; others must be a member of the building
        const allowed = authCtx.platformAdmin || authCtx.buildings.includes(buildingId);
        if (!allowed) {
          res.status(403).json({ error: 'FORBIDDEN', message: 'access denied for building' });
          return;
        }

        const doc = await admin.firestore().doc(`buildings/${buildingId}`).get();
        if (!doc.exists) {
          res.status(404).json({ error: 'NOT_FOUND', message: 'building not found' });
          return;
        }
        const building = { id: doc.id, ...(doc.data() as any) };
        res.json({ building });
        return;
      }
      case 'createMaintenanceRequest': {
        const b = (input as any) || {};
        const buildingId = String(b.buildingId || '').trim();
        const unitId = b.unitId ? String(b.unitId).trim() : undefined;
        const category = String(b.category || '').trim();
        const description = String(b.description || '').trim();
        const managementMode = b.managementMode ? String(b.managementMode) : undefined;

        if (!buildingId || !category || !description) {
          res.status(400).json({ error: 'INVALID_ARGUMENT', message: 'buildingId, category, description required' });
          return;
        }

        // Tenant scoping: require membership or platform admin
        const allowed = authCtx.platformAdmin || authCtx.buildings.includes(buildingId);
        if (!allowed) {
          res.status(403).json({ error: 'FORBIDDEN', message: 'access denied for building' });
          return;
        }

        // Idempotency key already validated above for mutating tools. Use per-user key to avoid collisions.
        const idemKey = `${authCtx.uid}:${idempotencyKey}`;
        const db = admin.firestore();
        const idemRef = db.collection('idempotency').doc(idemKey);

        const result = await db.runTransaction(async (tx) => {
          const idemSnap = await tx.get(idemRef);
          if (idemSnap.exists) {
            const data = idemSnap.data() as any;
            return { reused: true, requestId: data.requestId as string };
          }

          const reqRef = db.collection('buildings').doc(buildingId).collection('maintenance_requests').doc();
          const payload: any = {
            requestId: reqRef.id,
            buildingId,
            unitId: unitId ?? null,
            createdByUserId: authCtx.uid,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            status: 'pending',
            category,
            description,
          };
          if (managementMode) payload.managementMode = managementMode;

          tx.set(reqRef, payload, { merge: true });
          tx.set(idemRef, {
            requestId: reqRef.id,
            tool: 'createMaintenanceRequest',
            uid: authCtx.uid,
            buildingId,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });

          // lightweight audit log
          const auditRef = db.collection('buildings').doc(buildingId).collection('audit').doc();
          tx.set(auditRef, {
            type: 'mcp.createMaintenanceRequest',
            actorUid: authCtx.uid,
            requestId: reqRef.id,
            idempotencyKey,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          return { reused: false, requestId: reqRef.id };
        });

        res.json({ requestId: result.requestId, status: result.reused ? 'duplicate' : 'created' });
        return;
      }
      default:
        // Not yet implemented tools fall back to stub response
        res.status(501).json({
          status: 'NOT_IMPLEMENTED',
          message: 'MCP execute stub ready. AuthZ, tenancy, and tool handlers will be added incrementally.',
          echo: { tool, input: input ?? null },
        });
        return;
    }
  } catch (e: any) {
    console.error('mcp_execute error', e);
    res.status(500).json({ error: 'INTERNAL', message: e?.message || 'internal error' });
  }
});

// ========== Helpers ==========
type AuthContext = {
  uid: string;
  platformAdmin: boolean;
  buildings: string[];
  rolesByBuilding: Record<string, string>;
};

async function verifyAuth(req: any): Promise<AuthContext> {
  const authz = String(req.header('Authorization') || req.header('authorization') || '').trim();
  if (!authz.toLowerCase().startsWith('bearer ')) {
    throw new Error('missing bearer token');
  }
  const token = authz.substring(7).trim();
  const decoded = await admin.auth().verifyIdToken(token);
  const platformAdmin = Boolean(decoded.platformAdmin === true);
  const buildings = Array.isArray((decoded as any).buildings) ? ((decoded as any).buildings as any[]).map(String) : [];
  const rolesByBuilding = typeof (decoded as any).rolesByBuilding === 'object' && (decoded as any).rolesByBuilding
    ? (decoded as any).rolesByBuilding as Record<string, string>
    : {};

  return {
    uid: decoded.uid,
    platformAdmin,
    buildings,
    rolesByBuilding,
  };
}
