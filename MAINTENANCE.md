# Maintenance System (MVP)

This document describes the MVP design and data structures for Vaadly's maintenance workflow with two management modes and shared vendor pools.

Key rules
- Approvals are completely separated:
  - App-owner-managed requests are approved by App Owner only.
  - Committee-managed requests are approved by the Committee only.
- Cost policy threshold default: 500 ILS (configurable per building)
- Quotes include VAT (e.g., 17%) and total is displayed with VAT.
- Additional service categories: gardening, sanitation.
- AppOwner pool is only used when policy triggers (not always visible).

Data model (Firestore)
- app_owners/{ownerId}/vendor_profiles/{vendorId}
- app_owners/{ownerId}/vendor_pools/{poolId}
- buildings/{buildingId}/committee_vendor_pools/{poolId}
- buildings/{buildingId}/settings/maintenance (document)
- buildings/{buildingId}/maintenance_requests/{requestId}

Core entities (Dart)
- ManagementMode: appOwnerManaged | committeeManaged
- ServiceCategory: plumbing, electrical, elevator, general, gardening, sanitation
- CostPolicy: autoCompareThresholdIls=500, minQuotes=2, weights for price/rating/SLA
- VendorProfile: contact details, categories, regions, pricing in ILS (VAT applied in quotes)
- VendorPool: list of vendor IDs and categories, scope app_owner or committee
- MaintenanceRequest: status flow, snapshot of settings, quotes with VAT

Workflow (MVP)
1) Create request: select category, describe issue, upload photos.
2) Determine vendor selection source:
   - appOwnerManaged: use AppOwner pool (policy may add Committee pool later).
   - committeeManaged: use Committee pool; include AppOwner pool only if policy triggers.
3) Manual vendor selection: list matched vendors by category/region.
4) Decision & assignment recorded with separated approvers.

Next phases
- RFQ automation and quote collection via Cloud Functions
- Scoring and recommendations using cost policy weights
- Notifications and SLA tracking

CLI (seeding)
- scripts/seed_vendors.dart seeds demo AppOwner vendors (ILS pricing, VAT via quotes) and default pool.
