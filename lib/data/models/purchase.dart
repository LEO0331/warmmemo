class Purchase {
  Purchase({
    required this.planName,
    required this.priceLabel,
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
  }) : createdAt = createdAt ?? DateTime.now();

  final String? id;
  final String? userId;
  final String? docPath;
  final String planName;
  final String priceLabel;
  final String status; // pending | received | complete
  final DateTime createdAt;
  final String? companyName;
  final String? contactNumber;
  final String? agentName;
  final String? notes;
  final String? paymentProvider; // stripe | ecpay
  final String? paymentStatus; // awaiting_checkout | checkout_created | paid | failed
  final String? invoiceId;
  final String? checkoutUrl;
  final String? paymentCurrency;

  Purchase copyWith({
    String? id,
    String? status,
    String? companyName,
    String? contactNumber,
    String? agentName,
    String? notes,
    String? userId,
    String? docPath,
    String? paymentProvider,
    String? paymentStatus,
    String? invoiceId,
    String? checkoutUrl,
    String? paymentCurrency,
  }) {
    return Purchase(
      userId: userId ?? this.userId,
      id: id ?? this.id,
      docPath: docPath ?? this.docPath,
      planName: planName,
      priceLabel: priceLabel,
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
        'paymentProvider': paymentProvider,
        'paymentStatus': paymentStatus,
        'invoiceId': invoiceId,
        'checkoutUrl': checkoutUrl,
        'paymentCurrency': paymentCurrency,
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
      );
}
