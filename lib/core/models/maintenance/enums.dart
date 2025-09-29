import 'package:json_annotation/json_annotation.dart';

part 'enums.g.dart';

@JsonEnum(alwaysCreate: true)
enum ManagementMode {
  appOwnerManaged,
  committeeManaged,
}

@JsonEnum(alwaysCreate: true)
enum ServiceCategory {
  plumbing,
  electrical,
  elevator,
  general,
  gardening,
  sanitation,
}

@JsonEnum(alwaysCreate: true)
enum MaintenanceStatus {
  draft,
  rfq,
  quotesReceived,
  approved,
  assigned,
  inProgress,
  completed,
  closed,
}

String enumToString(Object e) => e.toString().split('.').last;

T enumFromString<T>(List<T> values, String? value, T fallback) {
  if (value == null) return fallback;
  return values.firstWhere(
    (v) => enumToString(v as Object) == value,
    orElse: () => fallback,
  );
}