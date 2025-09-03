class AppOwner {
  final String id;
  final String name;
  final String email;
  final String company;
  final String? phone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String subscriptionTier; // starter, professional, enterprise
  final Map<String, dynamic> settings;
  final List<String> buildingIds; // buildings owned by this app owner

  AppOwner({
    required this.id,
    required this.name,
    required this.email,
    required this.company,
    this.phone,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.subscriptionTier,
    this.settings = const {},
    this.buildingIds = const [],
  });

  // Factory constructor from Map
  factory AppOwner.fromMap(Map<String, dynamic> data, String id) {
    return AppOwner(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      company: data['company'] ?? '',
      phone: data['phone'],
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      isActive: data['isActive'] ?? true,
      subscriptionTier: data['subscriptionTier'] ?? 'starter',
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
      buildingIds: List<String>.from(data['buildingIds'] ?? []),
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'company': company,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'subscriptionTier': subscriptionTier,
      'settings': settings,
      'buildingIds': buildingIds,
    };
  }

  // Helper method to parse DateTime from Firestore data
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    if (value.runtimeType.toString().contains('Timestamp')) {
      return (value as dynamic).toDate() as DateTime;
    }
    return DateTime.now();
  }

  // Copy with method
  AppOwner copyWith({
    String? id,
    String? name,
    String? email,
    String? company,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? subscriptionTier,
    Map<String, dynamic>? settings,
    List<String>? buildingIds,
  }) {
    return AppOwner(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      settings: settings ?? this.settings,
      buildingIds: buildingIds ?? this.buildingIds,
    );
  }

  @override
  String toString() {
    return 'AppOwner(id: $id, name: $name, company: $company, tier: $subscriptionTier)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppOwner && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum SubscriptionTier {
  starter,
  professional,
  enterprise,
}

extension SubscriptionTierExtension on SubscriptionTier {
  String get displayName {
    switch (this) {
      case SubscriptionTier.starter:
        return 'Starter';
      case SubscriptionTier.professional:
        return 'Professional';
      case SubscriptionTier.enterprise:
        return 'Enterprise';
    }
  }
}