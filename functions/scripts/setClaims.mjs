#!/usr/bin/env node

import admin from 'firebase-admin';

function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i++) {
    const [k, v] = argv[i].split('=');
    const key = k.replace(/^--/, '');
    args[key] = v === undefined ? true : v;
  }
  return args;
}

async function main() {
  try {
    const args = parseArgs(process.argv);
    const { uid, email, buildingId, role, platformAdmin } = args;

    if (!uid && !email) {
      console.error('Error: provide --uid=<uid> or --email=<email>');
      process.exit(1);
    }

    if (!buildingId && role === 'committee') {
      console.error('Error: --buildingId is required when --role=committee');
      process.exit(1);
    }

    // Initialize Admin SDK using Application Default Credentials
    // Set GOOGLE_APPLICATION_CREDENTIALS to your service account JSON path before running.
    if (!admin.apps.length) {
      const projectId = process.env.GOOGLE_CLOUD_PROJECT || process.env.GCLOUD_PROJECT || args.projectId;
      const options = { credential: admin.credential.applicationDefault() };
      if (projectId) options.projectId = projectId;
      admin.initializeApp(options);
    }

    // Resolve user
    let userRecord;
    if (uid) {
      userRecord = await admin.auth().getUser(uid);
    } else if (email) {
      userRecord = await admin.auth().getUserByEmail(email);
    }

    const currentClaims = (userRecord.customClaims || {});
    const rolesByBuilding = { ...(currentClaims.rolesByBuilding || {}) };

    // Apply role mapping
    if (role === 'committee' && buildingId) {
      rolesByBuilding[buildingId] = 'committee';
    }

    const nextClaims = {
      ...currentClaims,
      ...(platformAdmin !== undefined ? { platformAdmin: String(platformAdmin).toLowerCase() === 'true' } : {}),
      rolesByBuilding,
    };

    await admin.auth().setCustomUserClaims(userRecord.uid, nextClaims);

    // Force token refresh
    await admin.auth().revokeRefreshTokens(userRecord.uid);

    console.log('✅ Claims set successfully for', userRecord.uid);
    console.log('   platformAdmin:', nextClaims.platformAdmin === true);
    console.log('   rolesByBuilding:', nextClaims.rolesByBuilding);
    console.log('ℹ️ Ask the user to sign out and sign back in to refresh their ID token.');

  } catch (err) {
    console.error('❌ Failed to set claims:', err?.message || err);
    process.exit(1);
  }
}

main();

