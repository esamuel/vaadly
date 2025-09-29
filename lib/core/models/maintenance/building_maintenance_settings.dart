import 'enums.dart';
import 'cost_policy.dart';

class BuildingMaintenanceSettings {
  final ManagementMode managementMode; // appOwnerManaged | committeeManaged
  final String committeePoolId; // e.g., 'default'
  final String appOwnerPoolId; // e.g., 'default_app_owner_pool'
  final CostPolicy costPolicy;

  const BuildingMaintenanceSettings({
    this.managementMode = ManagementMode.committeeManaged,
    this.committeePoolId = 'default',
    this.appOwnerPoolId = 'default_app_owner_pool',
    this.costPolicy = const CostPolicy(),
  });

  factory BuildingMaintenanceSettings.fromJson(Map<String, dynamic> json) {
    return BuildingMaintenanceSettings(
      managementMode: ManagementMode.values.firstWhere(
        (m) => m.toString().split('.').last == (json['managementMode'] as String? ?? 'committeeManaged'),
        orElse: () => ManagementMode.committeeManaged,
      ),
      committeePoolId: json['committeePoolId'] as String? ?? 'default',
      appOwnerPoolId: json['appOwnerPoolId'] as String? ?? 'default_app_owner_pool',
      costPolicy: json['costPolicy'] is Map<String, dynamic>
          ? CostPolicy.fromJson(json['costPolicy'] as Map<String, dynamic>)
          : const CostPolicy(),
    );
  }

  Map<String, dynamic> toJson() => {
        'managementMode': managementMode.toString().split('.').last,
        'committeePoolId': committeePoolId,
        'appOwnerPoolId': appOwnerPoolId,
        'costPolicy': costPolicy.toJson(),
      };
}
