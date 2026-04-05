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
    actedAt: _parseDateTime(map['actedAt']) ?? DateTime.now(),
    summary: map['summary'] as String? ?? '',
    fromStatus: map['fromStatus'] as String?,
    toStatus: map['toStatus'] as String?,
    fromPaymentStatus: map['fromPaymentStatus'] as String?,
    toPaymentStatus: map['toPaymentStatus'] as String?,
    note: map['note'] as String?,
    paymentIntentId: map['paymentIntentId'] as String?,
  );
}

class OrderProposal {
  OrderProposal({
    this.vendorPreference,
    this.materialChoice,
    this.schedulePreference,
    this.note,
    this.submittedAt,
  });

  final String? vendorPreference;
  final String? materialChoice;
  final String? schedulePreference;
  final String? note;
  final DateTime? submittedAt;

  bool get isEmpty =>
      (vendorPreference ?? '').trim().isEmpty &&
      (materialChoice ?? '').trim().isEmpty &&
      (schedulePreference ?? '').trim().isEmpty &&
      (note ?? '').trim().isEmpty;

  Map<String, Object?> toMap() => {
    'vendorPreference': vendorPreference,
    'materialChoice': materialChoice,
    'schedulePreference': schedulePreference,
    'note': note,
    'submittedAt': submittedAt?.toIso8601String(),
  };

  factory OrderProposal.fromMap(Map<String, dynamic> map) => OrderProposal(
    vendorPreference: map['vendorPreference'] as String?,
    materialChoice: map['materialChoice'] as String?,
    schedulePreference: map['schedulePreference'] as String?,
    note: map['note'] as String?,
    submittedAt: _parseDateTime(map['submittedAt']),
  );
}

class VendorAssignment {
  VendorAssignment({
    this.vendorId,
    this.vendorName,
    this.contactName,
    this.contactPhone,
    this.region,
  });

  final String? vendorId;
  final String? vendorName;
  final String? contactName;
  final String? contactPhone;
  final String? region;

  bool get isEmpty =>
      (vendorId ?? '').trim().isEmpty &&
      (vendorName ?? '').trim().isEmpty &&
      (contactName ?? '').trim().isEmpty &&
      (contactPhone ?? '').trim().isEmpty &&
      (region ?? '').trim().isEmpty;

  Map<String, Object?> toMap() => {
    'vendorId': vendorId,
    'vendorName': vendorName,
    'contactName': contactName,
    'contactPhone': contactPhone,
    'region': region,
  };

  factory VendorAssignment.fromMap(Map<String, dynamic> map) =>
      VendorAssignment(
        vendorId: map['vendorId'] as String?,
        vendorName: map['vendorName'] as String?,
        contactName: map['contactName'] as String?,
        contactPhone: map['contactPhone'] as String?,
        region: map['region'] as String?,
      );
}

class MaterialSelection {
  MaterialSelection({
    this.code,
    this.label,
    this.tier,
    this.priceBand,
    this.grossMarginBand,
  });

  final String? code;
  final String? label;
  final String? tier;
  final String? priceBand;
  final String? grossMarginBand;

  bool get isEmpty =>
      (code ?? '').trim().isEmpty &&
      (label ?? '').trim().isEmpty &&
      (tier ?? '').trim().isEmpty &&
      (priceBand ?? '').trim().isEmpty &&
      (grossMarginBand ?? '').trim().isEmpty;

  Map<String, Object?> toMap() => {
    'code': code,
    'label': label,
    'tier': tier,
    'priceBand': priceBand,
    'grossMarginBand': grossMarginBand,
  };

  factory MaterialSelection.fromMap(Map<String, dynamic> map) =>
      MaterialSelection(
        code: map['code'] as String?,
        label: map['label'] as String?,
        tier: map['tier'] as String?,
        priceBand: map['priceBand'] as String?,
        grossMarginBand: map['grossMarginBand'] as String?,
      );
}

class DeliveryMilestone {
  DeliveryMilestone({
    required this.code,
    required this.label,
    this.status = 'pending',
    this.targetDate,
    this.note,
    this.updatedAt,
  });

  final String code;
  final String label;
  final String status;
  final DateTime? targetDate;
  final String? note;
  final DateTime? updatedAt;

  DeliveryMilestone copyWith({
    String? code,
    String? label,
    String? status,
    DateTime? targetDate,
    String? note,
    DateTime? updatedAt,
  }) {
    return DeliveryMilestone(
      code: code ?? this.code,
      label: label ?? this.label,
      status: status ?? this.status,
      targetDate: targetDate ?? this.targetDate,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
    'code': code,
    'label': label,
    'status': status,
    'targetDate': targetDate?.toIso8601String(),
    'note': note,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory DeliveryMilestone.fromMap(Map<String, dynamic> map) =>
      DeliveryMilestone(
        code: map['code'] as String? ?? '',
        label: map['label'] as String? ?? '',
        status: map['status'] as String? ?? 'pending',
        targetDate: _parseDateTime(map['targetDate']),
        note: map['note'] as String?,
        updatedAt: _parseDateTime(map['updatedAt']),
      );
}

List<DeliveryMilestone> defaultDeliveryMilestones() {
  return [
    DeliveryMilestone(code: 'design_confirmed', label: '設計確認'),
    DeliveryMilestone(code: 'in_production', label: '製作中'),
    DeliveryMilestone(code: 'delivered', label: '已交付'),
  ];
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
    this.proposal,
    this.vendorAssignment,
    this.materialSelection,
    this.deliverySchedule = const [],
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
  final String? paymentProvider; // stripe | ecpay | linepay
  final String?
  paymentStatus; // awaiting_checkout | checkout_created | paid | failed | cancelled | expired
  final String? invoiceId;
  final String? checkoutUrl;
  final String? paymentCurrency;
  final DateTime? paidAt;
  final String? paymentIntentId;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? verificationNote;
  final List<VerificationLog> verificationLogs;

  // V2: business-oriented workflow extension
  final OrderProposal? proposal;
  final VendorAssignment? vendorAssignment;
  final MaterialSelection? materialSelection;
  final List<DeliveryMilestone> deliverySchedule;

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
    OrderProposal? proposal,
    VendorAssignment? vendorAssignment,
    MaterialSelection? materialSelection,
    List<DeliveryMilestone>? deliverySchedule,
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
      proposal: proposal ?? this.proposal,
      vendorAssignment: vendorAssignment ?? this.vendorAssignment,
      materialSelection: materialSelection ?? this.materialSelection,
      deliverySchedule: deliverySchedule ?? this.deliverySchedule,
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
    'proposal': proposal?.isEmpty == true ? null : proposal?.toMap(),
    'vendorAssignment': vendorAssignment?.isEmpty == true
        ? null
        : vendorAssignment?.toMap(),
    'materialSelection': materialSelection?.isEmpty == true
        ? null
        : materialSelection?.toMap(),
    'deliverySchedule': deliverySchedule.map((item) => item.toMap()).toList(),
  };

  factory Purchase.fromMap(
    Map<String, dynamic> map, {
    String? id,
    String? userId,
    String? docPath,
  }) => Purchase(
    id: id,
    userId: userId ?? map['userId'] as String?,
    docPath: docPath,
    planName: map['planName'] as String? ?? '',
    priceLabel: map['priceLabel'] as String? ?? '',
    priceAmount:
        (map['priceAmount'] as num?)?.toInt() ??
        _parsePriceAmount(map['priceLabel'] as String?),
    status: map['status'] as String? ?? 'pending',
    createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
    companyName: map['companyName'] as String?,
    contactNumber: map['contactNumber'] as String?,
    agentName: map['agentName'] as String?,
    notes: map['notes'] as String?,
    paymentProvider: map['paymentProvider'] as String?,
    paymentStatus: map['paymentStatus'] as String?,
    invoiceId: map['invoiceId'] as String?,
    checkoutUrl: map['checkoutUrl'] as String?,
    paymentCurrency: map['paymentCurrency'] as String?,
    paidAt: _parseDateTime(map['paidAt']),
    paymentIntentId: map['paymentIntentId'] as String?,
    verifiedBy: map['verifiedBy'] as String?,
    verifiedAt: _parseDateTime(map['verifiedAt']),
    verificationNote: map['verificationNote'] as String?,
    verificationLogs: (map['verificationLogs'] as List<dynamic>? ?? const [])
        .map(
          (item) =>
              VerificationLog.fromMap((item as Map).cast<String, dynamic>()),
        )
        .toList(),
    proposal: map['proposal'] is Map
        ? OrderProposal.fromMap(
            (map['proposal'] as Map).cast<String, dynamic>(),
          )
        : null,
    vendorAssignment: map['vendorAssignment'] is Map
        ? VendorAssignment.fromMap(
            (map['vendorAssignment'] as Map).cast<String, dynamic>(),
          )
        : null,
    materialSelection: map['materialSelection'] is Map
        ? MaterialSelection.fromMap(
            (map['materialSelection'] as Map).cast<String, dynamic>(),
          )
        : null,
    deliverySchedule: (map['deliverySchedule'] as List<dynamic>? ?? const [])
        .map(
          (item) =>
              DeliveryMilestone.fromMap((item as Map).cast<String, dynamic>()),
        )
        .toList(),
  );

  static int _parsePriceAmount(String? label) {
    if (label == null) return 0;
    final digits = label.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }
}

DateTime? _parseDateTime(Object? value) {
  if (value == null) return null;
  if (value is String) return DateTime.tryParse(value);
  if (value is DateTime) return value;
  final dynamic dynamicValue = value;
  try {
    final maybeDate = dynamicValue.toDate?.call();
    if (maybeDate is DateTime) return maybeDate;
  } catch (_) {
    // Ignore if this is not a Timestamp-like object.
  }
  return null;
}
