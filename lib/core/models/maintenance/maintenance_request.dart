import 'package:json_annotation/json_annotation.dart';
import 'enums.dart';
import 'quote.dart';
import 'cost_policy.dart';

part 'maintenance_request.g.dart';

@JsonSerializable(explicitToJson: true)
class MaintenanceRequest {
  final String requestId;
  final String buildingId;
  final String? unitId;
  final String createdByUserId;
  final DateTime createdAt;
  final MaintenanceStatus status;
  final ServiceCategory category;
  final String description;
  final List<String> photoUrls;
  final String priority; // low|med|high simple string for now

  // Snapshot of building settings for audit/tracking
  final ManagementMode managementModeSnapshot;
  final String? committeePoolId;
  final String? appOwnerPoolId;
  final bool usesAppOwnerPool; // whether policy allowed pulling vendors

  final Map<String, dynamic> rfq; // { sentToVendorIds:[], min_quotes:int, dueAt:timestamp }
  final List<Quote> quotes;

  final Map<String, dynamic>? recommendation; // { vendorId, score, reason }
  final Map<String, dynamic>? decision; // { chosenVendorId, decidedByUserId, decidedAt }

  final CostPolicy costPolicySnapshot;

  const MaintenanceRequest({
    required this.requestId,
    required this.buildingId,
    this.unitId,
    required this.createdByUserId,
    required this.createdAt,
    this.status = MaintenanceStatus.draft,
    required this.category,
    required this.description,
    this.photoUrls = const [],
    this.priority = 'med',
    required this.managementModeSnapshot,
    this.committeePoolId,
    this.appOwnerPoolId,
    this.usesAppOwnerPool = false,
    this.rfq = const {},
    this.quotes = const [],
    this.recommendation,
    this.decision,
    required this.costPolicySnapshot,
  });

  factory MaintenanceRequest.fromJson(Map<String, dynamic> json) => _$MaintenanceRequestFromJson(json);
  Map<String, dynamic> toJson() => _$MaintenanceRequestToJson(this);
}