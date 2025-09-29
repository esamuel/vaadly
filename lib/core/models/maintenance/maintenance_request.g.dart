// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaintenanceRequest _$MaintenanceRequestFromJson(Map<String, dynamic> json) =>
    MaintenanceRequest(
      requestId: json['requestId'] as String,
      buildingId: json['buildingId'] as String,
      unitId: json['unitId'] as String?,
      createdByUserId: json['createdByUserId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: $enumDecodeNullable(_$MaintenanceStatusEnumMap, json['status']) ??
          MaintenanceStatus.draft,
      category: $enumDecode(_$ServiceCategoryEnumMap, json['category']),
      description: json['description'] as String,
      photoUrls: (json['photoUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      priority: json['priority'] as String? ?? 'med',
      managementModeSnapshot:
          $enumDecode(_$ManagementModeEnumMap, json['managementModeSnapshot']),
      committeePoolId: json['committeePoolId'] as String?,
      appOwnerPoolId: json['appOwnerPoolId'] as String?,
      usesAppOwnerPool: json['usesAppOwnerPool'] as bool? ?? false,
      rfq: json['rfq'] as Map<String, dynamic>? ?? const {},
      quotes: (json['quotes'] as List<dynamic>?)
              ?.map((e) => Quote.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      recommendation: json['recommendation'] as Map<String, dynamic>?,
      decision: json['decision'] as Map<String, dynamic>?,
      costPolicySnapshot: CostPolicy.fromJson(
          json['costPolicySnapshot'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MaintenanceRequestToJson(MaintenanceRequest instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'buildingId': instance.buildingId,
      'unitId': instance.unitId,
      'createdByUserId': instance.createdByUserId,
      'createdAt': instance.createdAt.toIso8601String(),
      'status': _$MaintenanceStatusEnumMap[instance.status]!,
      'category': _$ServiceCategoryEnumMap[instance.category]!,
      'description': instance.description,
      'photoUrls': instance.photoUrls,
      'priority': instance.priority,
      'managementModeSnapshot':
          _$ManagementModeEnumMap[instance.managementModeSnapshot]!,
      'committeePoolId': instance.committeePoolId,
      'appOwnerPoolId': instance.appOwnerPoolId,
      'usesAppOwnerPool': instance.usesAppOwnerPool,
      'rfq': instance.rfq,
      'quotes': instance.quotes.map((e) => e.toJson()).toList(),
      'recommendation': instance.recommendation,
      'decision': instance.decision,
      'costPolicySnapshot': instance.costPolicySnapshot.toJson(),
    };

const _$MaintenanceStatusEnumMap = {
  MaintenanceStatus.draft: 'draft',
  MaintenanceStatus.rfq: 'rfq',
  MaintenanceStatus.quotesReceived: 'quotesReceived',
  MaintenanceStatus.approved: 'approved',
  MaintenanceStatus.assigned: 'assigned',
  MaintenanceStatus.inProgress: 'inProgress',
  MaintenanceStatus.completed: 'completed',
  MaintenanceStatus.closed: 'closed',
};

const _$ServiceCategoryEnumMap = {
  ServiceCategory.plumbing: 'plumbing',
  ServiceCategory.electrical: 'electrical',
  ServiceCategory.elevator: 'elevator',
  ServiceCategory.general: 'general',
  ServiceCategory.gardening: 'gardening',
  ServiceCategory.sanitation: 'sanitation',
};

const _$ManagementModeEnumMap = {
  ManagementMode.appOwnerManaged: 'appOwnerManaged',
  ManagementMode.committeeManaged: 'committeeManaged',
};
