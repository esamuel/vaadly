# Data Model Decision: Flat Top-Level Collections

Decision date: 2025-09-05

Summary
We standardize on a flat Firestore data model using top-level collections, consistent with docs/VAADLY_FIRESTORE_SPEC.md. We will deprecate per-building subcollections for core entities.

Canonical collections
- users
- buildings
- memberships
- tickets
- invoices
- payments
- vendors
- announcements
- (optional) chats

Rationale
- Simpler, consistent security rules and queries (filter by buildingId).
- Easier indexing, aggregation, and cross-building analytics for App Owners.
- Matches Cloud Function triggers and claims sync logic.

Impacts
- Client services should query by buildingId field instead of nested collection paths.
- Firestore rules remain aligned with the spec. Any rules that refer to nested subcollections are considered legacy and will be removed.
- Cloud Functions should watch top-level collections.

Migration plan (legacy -> flat)
1) Audit usages
   - Identify reads/writes to buildings/{buildingId}/(residents|units|maintenance|work_orders|finances|announcements|settings)
2) Data backfill
   - For each legacy subcollection doc, write a new doc to the corresponding top-level collection with buildingId field preserved.
3) Dual-write window (if needed)
   - Temporarily write to both locations to avoid downtime. Prefer short window in dev.
4) Cutover
   - Update client code and functions to use only top-level collections.
   - Remove legacy reads.
5) Cleanup
   - Delete legacy subcollections; remove legacy paths from rules.

Next actions
- Refactor core/services and lib/services/* to use flat collections.
- Add composite indexes (see spec) for tickets, invoices, payments, memberships.
- Remove nested subcollection rules from firestore.rules once refactor completes.

