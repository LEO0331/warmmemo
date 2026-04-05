class Vendor {
  Vendor({
    this.id,
    required this.name,
    this.contactName,
    this.contactPhone,
    this.serviceRegion,
    this.isActive = true,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  final String? id;
  final String name;
  final String? contactName;
  final String? contactPhone;
  final String? serviceRegion;
  final bool isActive;
  final DateTime updatedAt;

  Vendor copyWith({
    String? id,
    String? name,
    String? contactName,
    String? contactPhone,
    String? serviceRegion,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return Vendor(
      id: id ?? this.id,
      name: name ?? this.name,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      serviceRegion: serviceRegion ?? this.serviceRegion,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
    'name': name,
    'nameLower': name.trim().toLowerCase(),
    'contactName': contactName,
    'contactPhone': contactPhone,
    'serviceRegion': serviceRegion,
    'isActive': isActive,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Vendor.fromMap(Map<String, dynamic> map, {String? id}) => Vendor(
    id: id,
    name: map['name'] as String? ?? '',
    contactName: map['contactName'] as String?,
    contactPhone: map['contactPhone'] as String?,
    serviceRegion: map['serviceRegion'] as String?,
    isActive: map['isActive'] as bool? ?? true,
    updatedAt:
        DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
  );
}
