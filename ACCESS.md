# Access Model and Onboarding

This document summarizes how access, onboarding, and recovery work for the App Owner, Committee, and Residents. Keep this as a quick reference when supporting clients.

## Overview
- App Owner issues links per building:
  - Management (Committee) portal: `#/manage/{buildingCode}`
  - Resident portal: `#/building/{buildingCode}`
- Committee Chair uses the management link to create an account and becomes building admin.
- Residents use the resident link to sign in and access their unit data.

## Roles and Access
- `App Owner`: Full platform control. Can view users (email/name), manage building access, but cannot view passwords.
- `Building Committee`: Admin access to their building (vendor pool, finances, residents, settings).
- `Resident`: Read access to their building and unit-specific features.

## Credentials and Security
- Emails and names are stored in Firestore (`users` collection).
- Passwords are stored ONLY in Firebase Auth as secure hashes (never visible to anyone, including the App Owner).

## App Owner Capabilities (Support Actions)
- Reset: Send a password reset email to any user account.
- Grant access: Give a user committee admin rights for a building (adds `buildingAccess[buildingId] = 'admin'`).
- Re-invite: Generate the management link for a building and resend it to the committee.
- Audit: Review who has access and last login timestamps.

## Committee Onboarding Flow
1) Chair opens `#/manage/{buildingCode}`.
2) Enters email + password; if the email exists, the flow signs in instead of creating a duplicate.
3) Profile is created/updated and committee admin access is granted for the building.
4) Chair lands in the committee dashboard and completes building data.

## Resident Access Flow
1) Resident opens `#/building/{buildingCode}`.
2) Signs in (or creates account). Screen clearly shows the building name.
3) Access is limited to their building (`buildingAccess[buildingId] = 'read'`) and their unit (`unitAccess[unitId] = buildingId`).
4) If they forget the password, they can request a reset link.

## Shared Email Across Buildings
- A single email can be a resident in Building A and a committee admin in Building B.
- The app routes by current building context: admin access → committee dashboard; read access → resident dashboard.

## Recovery Options
- Password reset email (recommended, secure, auditable).
- Re-send the management or resident link for the building.
- Assign/replace committee admin by granting access to a different email.

## Operational Notes
- App Owner can manage emails and access; passwords remain private to users.
- All links use the canonical hosted origin: `https://vaadly-project.web.app`.

