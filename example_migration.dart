/// Example of how to run the multi-tenant migration
///
/// This script demonstrates how to migrate your existing Vaadly data
/// from single-tenant to multi-tenant structure.
///
/// Run with: dart run example_migration.dart
library;

import 'lib/scripts/migrate_to_multi_tenant.dart';

void main() async {
  print('🚀 Starting Vaadly Multi-Tenant Migration');
  print('=========================================');

  try {
    // Initialize Firebase
    await MultiTenantMigrationScript.initialize();

    // IMPORTANT: Replace these with your actual details
    const appOwnerEmail = 'samuel.eskenasy@gmail.com'; // Your email
    const appOwnerName = 'Samuel Eskenasy'; // Your name
    const appOwnerCompany = 'Vaadly'; // Your company

    print('');
    print('⚠️  MIGRATION DETAILS:');
    print('📧 App Owner Email: $appOwnerEmail');
    print('👤 App Owner Name: $appOwnerName');
    print('🏢 Company: $appOwnerCompany');
    print('');

    // Uncomment the next line to run the migration
    // await MultiTenantMigrationScript.migrateToMultiTenant(
    //   appOwnerEmail: appOwnerEmail,
    //   appOwnerName: appOwnerName,
    //   appOwnerCompany: appOwnerCompany,
    // );

    print('✅ Migration script ready to run!');
    print('');
    print('🔧 To actually run the migration:');
    print('   1. Update the details above with your information');
    print('   2. Uncomment the migration call in this script');
    print('   3. Run: dart run example_migration.dart');
    print('');
    print('⚠️  BACKUP WARNING:');
    print('   Make sure you have a Firestore backup before running!');
    print('   This migration will create new collections.');
  } catch (e) {
    print('❌ Migration setup failed: $e');
    print('');
    print('🔧 Troubleshooting:');
    print('   1. Make sure Firebase is configured correctly');
    print('   2. Check your internet connection');
    print('   3. Verify Firestore permissions');
  }
}

/// Example of how to rollback migration (if needed)
Future<void> rollbackExample() async {
  try {
    await MultiTenantMigrationScript.initialize();

    // Replace with actual owner ID from migration output
    const ownerId = 'your-owner-id-here';

    // await MultiTenantMigrationScript.rollbackMigration(ownerId);

    print('✅ Rollback completed');
  } catch (e) {
    print('❌ Rollback failed: $e');
  }
}
