class VerificationLog {
  VerificationLog({
    required this.actor,
    required this.actedAt,
    required this.summary,
    this.fromStatus,
    this.toStatus,
    this.fromPaymentStatus,
    this.toPaymentStatus,
    this.note,
    this.paymentIntentId,
  });

  final String actor;
  final DateTime actedAt;
  final String summary;
  final String? fromStatus;
  final String? toStatus;
  final String? fromPaymentStatus;
  final String? toPaymentStatus;
  final String? note;
  final String? paymentIntentId;

  Map<String, Object?> toMap() => {
        'actor': actor,
        'actedAt': actedAt.toIso8601String(),
        'summary': summary,
        'fromStatus': fromStatus,
        'toStatus': toStatus,
        'fromPaymentStatus': fromPaymentStatus,
        'toPaymentStatus': toPaymentStatus,
        'note': note,
        'paymentIntentId': paymentIntentId,
      };

  factory VerificationLog.fromMap(Map<String, dynamic> map) => VerificationLog(
        actor: map['actor'] as String? ?? '-',
        actedAt: DateTime.tryParse(map['actedAt'] as String? ?? '') ?? DateTime.now(),
        summary: map['summary'] as String? ?? '',
        fromStatus: map['fromStatus'] as String?,
        toStatus: map['toStatus'] as String?,
        fromPaymentStatus: map['fromPaymentStatus'] as String?,
        toPaymentStatus: map['toPaymentStatus'] as String?,
        note: map['note'] as String?,
        paymentIntentId: map['paymentIntentId'] as String?,
      );
}

class Purchase {
  Purchase({
    required this.planName,
    required this.priceLabel,
    required this.priceAmount,
    required this.status,
    this.userId,
    this.id,
    this.docPath,
    DateTime? createdAt,
    this.companyName,
    this.contactNumber,
    this.agentName,
    this.notes,
    this.paymentProvider,
    this.paymentStatus,
    this.invoiceId,
    this.checkoutUrl,
    this.paymentCurrency,
    this.paidAt,
    this.paymentIntentId,
    this.verifiedBy,
    this.verifiedAt,
    this.verificationNote,
    this.verificationLogs = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  final String? id;
  final String? userId;
  final String? docPath;
  final String planName;
  final String priceLabel;
  final int priceAmount;
  final String status; // pending | received | complete
  final DateTime createdAt;
  final String? companyName;
  final String? contactNumber;
  final String? agentName;
  final String? notes;
  final String? paymentProvider; // stripe | ecpay
  final String? paymentStatus; // awaiting_checkout | checkout_created | paid | failed | cancelled | expired
  final String? invoiceId;
  final String? checkoutUrl;
  final String? paymentCurrency;
  final DateTime? paidAt;
  final String? paymentIntentId;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? verificationNote;
  final List<VerificationLog> verificationLogs;

  Purchase copyWith({
    String? id,
    String? status,
    String? companyName,
    String? contactNumber,
    String? agentName,
    String? notes,
    String? userId,
    String? docPath,
    int? priceAmount,
    String? paymentProvider,
    String? paymentStatus,
    String? invoiceId,
    String? checkoutUrl,
    String? paymentCurrency,
    DateTime? paidAt,
    String? paymentIntentId,
    String? verifiedBy,
    DateTime? verifiedAt,
    String? verificationNote,
    List<VerificationLog>? verificationLogs,
  }) {
    return Purchase(
      userId: userId ?? this.userId,
      id: id ?? this.id,
      docPath: docPath ?? this.docPath,
      planName: planName,
      priceLabel: priceLabel,
      priceAmount: priceAmount ?? this.priceAmount,
      status: status ?? this.status,
      createdAt: createdAt,
      companyName: companyName ?? this.companyName,
      contactNumber: contactNumber ?? this.contactNumber,
      agentName: agentName ?? this.agentName,
      notes: notes ?? this.notes,
      paymentProvider: paymentProvider ?? this.paymentProvider,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      invoiceId: invoiceId ?? this.invoiceId,
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
      paymentCurrency: paymentCurrency ?? this.paymentCurrency,
      paidAt: paidAt ?? this.paidAt,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verificationNote: verificationNote ?? this.verificationNote,
      verificationLogs: verificationLogs ?? this.verificationLogs,
    );
  }

  Map<String, Object?> toMap() => {
        'planName': planName,
        'priceLabel': priceLabel,
        'priceAmount': priceAmount,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'userId': userId,
        'companyName': companyName,
        'contactNumber': contactNumber,
        'agentName': agentName,
        'notes': notes,
        'paymentProvider': paymentProvider,
        'paymentStatus': paymentStatus,
        'invoiceId': invoiceId,
        'checkoutUrl': checkoutUrl,
        'paymentCurrency': paymentCurrency,
        'paidAt': paidAt?.toIso8601String(),
        'paymentIntentId': paymentIntentId,
        'verifiedBy': verifiedBy,
        'verifiedAt': verifiedAt?.toIso8601String(),
        'verificationNote': verificationNote,
        'verificationLogs': verificationLogs.map((item) => item.toMap()).toList(),
      };

  factory Purchase.fromMap(
    Map<String, dynamic> map, {
    String? id,
    String? userId,
    String? docPath,
  }) =>
      Purchase(
        id: id,
        userId: userId ?? map['userId'] as String?,
        docPath: docPath,
        planName: map['planName'] as String? ?? '',
        priceLabel: map['priceLabel'] as String? ?? '',
        priceAmount: (map['priceAmount'] as num?)?.toInt() ??
            _parsePriceAmount(map['priceLabel'] as String?),
        status: map['status'] as String? ?? 'pending',
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
        companyName: map['companyName'] as String?,
        contactNumber: map['contactNumber'] as String?,
        agentName: map['agentName'] as String?,
        notes: map['notes'] as String?,
        paymentProvider: map['paymentProvider'] as String?,
        paymentStatus: map['paymentStatus'] as String?,
        invoiceId: map['invoiceId'] as String?,
        checkoutUrl: map['checkoutUrl'] as String?,
        paymentCurrency: map['paymentCurrency'] as String?,
        paidAt: DateTime.tryParse(map['paidAt'] as String? ?? ''),
        paymentIntentId: map['paymentIntentId'] as String?,
        verifiedBy: map['verifiedBy'] as String?,
        verifiedAt: DateTime.tryParse(map['verifiedAt'] as String? ?? ''),
        verificationNote: map['verificationNote'] as String?,
        verificationLogs: (map['verificationLogs'] as List<dynamic>? ?? const [])
            .map((item) => VerificationLog.fromMap((item as Map).cast<String, dynamic>()))
            .toList(),
      );

  static int _parsePriceAmount(String? label) {
    if (label == null) return 0;
    final digits = label.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }
}
