# Model Context Protocol (MCP) Specification

This document defines the MCP layer for Vaadly: a typed, auditable tool interface used by a server-side orchestrator to automate maintenance, vendors, payments, and governance. MCP runs server-side (Cloud Functions or Cloud Run). The Flutter app never holds MCP secrets.

## Transport, Auth, Tenancy
- Transport: WebSocket (preferred) or HTTP+SSE. JSON messages with request/response IDs.
- Auth: Firebase ID token on connection; server derives `role`, `tier`, `appOwnerId`, `buildingIds[]`, `residentId` from custom claims.
- Tenancy: Every tool validates inputs and applies row-level filters by `appOwnerId` and `buildingId`. Residents restricted to their own record.
- Idempotency: All writes require `idempotencyKey` to dedupe retries.

## Errors and Auditing
- Errors: `UNAUTHENTICATED`, `FORBIDDEN`, `INVALID_ARGUMENT`, `NOT_FOUND`, `CONFLICT`, `RATE_LIMITED`, `INTERNAL`.
- Audit log per call: `{tool, actor, tier, appOwnerId, buildingId?, residentId?, inputHash, outputHash, redactions, latencyMs, result}`. Redact PII and tokens.

## Tool Catalog (v1)
- getBuilding
  - Input: `{ buildingId: string }`
  - Output: `{ building: {...} }`
  - Access: T1/T2 for allowed buildings; T3 read building-public fields.
- listUnits
  - Input: `{ buildingId: string, cursor?: string, limit?: number }`
  - Output: `{ units: [...], nextCursor?: string }`
  - Access: T1/T2 only.
- getResident
  - Input: `{ residentId: string }`
  - Output: `{ resident: {...} }`
  - Access: T1/T2 by building; T3 self only.
- listVendors
  - Input: `{ category?: enum, region?: string, scope?: 'owner'|'committee', buildingId?: string }`
  - Output: `{ vendors: [...] }`
  - Access: T1 owner scope; T2 building scope; T3 none.
- createMaintenanceRequest
  - Input: `{ idempotencyKey: string, buildingId: string, unitId?: string, createdByUserId: string, category: enum, description: string, managementMode: enum, costPolicy?: {...} }`
  - Output: `{ requestId: string, status: 'created' }`
  - Access: T1/T2; T3 allowed for own unit/building.
- assignVendor
  - Input: `{ idempotencyKey: string, requestId: string, vendorId: string }`
  - Output: `{ status: 'assigned' }`
  - Access: T1/T2 only (policy-gated).
- scheduleVisit
  - Input: `{ idempotencyKey: string, requestId: string, scheduledFor: string, note?: string }`
  - Output: `{ status: 'scheduled' }`
  - Access: T1/T2 only.
- updateRequestStatus
  - Input: `{ idempotencyKey: string, requestId: string, status: enum, reason?: string }`
  - Output: `{ status: 'ok' }`
  - Access: T1/T2; T3 may mark own request as `cancelled` (policy-gated).
- getMaintenanceStats
  - Input: `{ buildingId: string, window?: '7d'|'30d'|'90d' }`
  - Output: `{ totals: {...}, breakdowns: {...} }`
  - Access: T1/T2; T3 summary only.
- createOwnerVendor (T1)
  - Input: `{ idempotencyKey: string, vendor: {...} }`
  - Output: `{ vendorId: string }`
- createCommitteeVendor (T2)
  - Input: `{ idempotencyKey: string, buildingId: string, vendor: {...} }`
  - Output: `{ vendorId: string }`
- createInvoice
  - Input: `{ idempotencyKey: string, buildingId: string, residentId?: string, requestId?: string, currency: string, amount: number, lineItems: [{desc, amount}] }`
  - Output: `{ invoiceId: string, status: 'created' }`
  - Access: T1/T2; T3 none.
- approveAndPay
  - Input: `{ idempotencyKey: string, invoiceId: string, paymentMethodId?: string, amount?: number }`
  - Output: `{ paymentId: string, status: 'paid' }`
  - Access: T1/T2; caps + approvals per policy.
- startVote (T2/T1)
  - Input: `{ idempotencyKey: string, buildingId: string, topic: string, options: [string], closesAt: string, quorum?: number }`
  - Output: `{ voteId: string }`
- castVote (T3)
  - Input: `{ idempotencyKey: string, voteId: string, option: string }`
  - Output: `{ status: 'recorded' }`

## Schemas and Enums (alignment)
- Categories: reuse `ServiceCategory` from `lib/core/models/maintenance/enums.dart`.
- Status: reuse `MaintenanceStatus`, `ManagementMode` enums.
- Pricing: accept `PricingRequest` shape from `lib/core/models/pricing_calculator.dart` if needed.

## Deployment & Dev
- Location: Prefer `functions/` (Node 20). Alternative: Cloud Run for scale.
- Local dev: `npm ci && npm run build`; run Firebase emulator; orchestrator connects to MCP server.
- CI: Add a job to build/test MCP server; independent from Flutter CI.

