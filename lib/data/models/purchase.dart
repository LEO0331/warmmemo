class Purchase {
  Purchase({
    required this.planName,
    required this.priceLabel,
    required this.status,
    this.userId,
    this.id,
    DateTime? createdAt,
    this.companyName,
    this.contactNumber,
    this.agentName,
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();

  final String? id;
  final String? userId;
  final String planName;
  final String priceLabel;
  final String status; // pending | received | complete
  final DateTime createdAt;
  final String? companyName;
  final String? contactNumber;
  final String? agentName;
  final String? notes;

  Purchase copyWith({
    String? id,
    String? status,
    String? companyName,
    String? contactNumber,
    String? agentName,
    String? notes,
    String? userId,
  }) {
    return Purchase(
      userId: userId ?? this.userId,
      id: id ?? this.id,
      planName: planName,
      priceLabel: priceLabel,
      status: status ?? this.status,
      createdAt: createdAt,
      companyName: companyName ?? this.companyName,
      contactNumber: contactNumber ?? this.contactNumber,
      agentName: agentName ?? this.agentName,
      notes: notes ?? this.notes,
    );
  }

  Map<String, Object?> toMap() => {
        'planName': planName,
        'priceLabel': priceLabel,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'userId': userId,
        'companyName': companyName,
        'contactNumber': contactNumber,
        'agentName': agentName,
        'notes': notes,
      };

  factory Purchase.fromMap(Map<String, dynamic> map, {String? id, String? userId}) => Purchase(
        id: id,
        userId: userId ?? map['userId'] as String?,
        planName: map['planName'] as String? ?? '',
        priceLabel: map['priceLabel'] as String? ?? '',
        status: map['status'] as String? ?? 'pending',
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
        companyName: map['companyName'] as String?,
        contactNumber: map['contactNumber'] as String?,
        agentName: map['agentName'] as String?,
        notes: map['notes'] as String?,
      );
}
