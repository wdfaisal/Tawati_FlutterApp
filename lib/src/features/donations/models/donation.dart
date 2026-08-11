class Campaign {
  final String id;
  final String fundId;
  final String? fundName;
  final String title;
  final String? description;
  final String? image;
  final double targetAmount;
  final double collectedAmount;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  final List<String> availablePaymentMethods;
  final int? donorCount;

  Campaign({
    required this.id,
    required this.fundId,
    this.fundName,
    required this.title,
    this.description,
    this.image,
    required this.targetAmount,
    required this.collectedAmount,
    required this.startDate,
    this.endDate,
    required this.status,
    required this.availablePaymentMethods,
    this.donorCount,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) => Campaign(
    id: json['_id'] ?? json['id'] ?? '',
    fundId: Campaign._id(json['fund_id']),
    fundName: Campaign._name(json['fund_id'], json['fund_name'], 'name_ar'),
    title: json['title'] ?? '',
    description: json['description'],
    image: json['image'],
    targetAmount: (json['target_amount'] ?? 0).toDouble(),
    collectedAmount: (json['collected_amount'] ?? 0).toDouble(),
    startDate: DateTime.tryParse(json['start_date'] ?? '') ?? DateTime.now(),
    endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null,
    status: json['status'] ?? 'active',
    availablePaymentMethods: (json['available_payment_methods'] as List<dynamic>?)
            ?.map((e) => e is String ? e : (e as Map<String, dynamic>)['_id'] as String? ?? '')
            .toList() ??
        [],
    donorCount: json['donor_count'],
  );

  Campaign copyWith({
    double? collectedAmount,
    double? targetAmount,
    int? donorCount,
    String? status,
  }) {
    return Campaign(
      id: id,
      fundId: fundId,
      fundName: fundName,
      title: title,
      description: description,
      image: image,
      targetAmount: targetAmount ?? this.targetAmount,
      collectedAmount: collectedAmount ?? this.collectedAmount,
      startDate: startDate,
      endDate: endDate,
      status: status ?? this.status,
      availablePaymentMethods: availablePaymentMethods,
      donorCount: donorCount ?? this.donorCount,
    );
  }

  static String _id(dynamic field) => field is String ? field : (field as Map<String, dynamic>?)?['_id'] as String? ?? '';

  static String? _name(dynamic field, dynamic direct, String key) =>
      direct as String? ?? (field is Map ? field[key] as String? : null);

  double get progress => targetAmount > 0 ? (collectedAmount / targetAmount).clamp(0, 1) : 0;
  bool get isActive => status == 'active';
}

class Donation {
  final String id;
  final String campaignId;
  final String? campaignName;
  final String userId;
  final String? userName;
  final double amount;
  final String paymentMethodId;
  final String? paymentMethodName;
  final String status;
  final String? referenceNumber;
  final DateTime? transferDate;
  final bool isAnonymous;
  final DateTime createdAt;

  Donation({
    required this.id,
    required this.campaignId,
    this.campaignName,
    required this.userId,
    this.userName,
    required this.amount,
    required this.paymentMethodId,
    this.paymentMethodName,
    required this.status,
    this.referenceNumber,
    this.transferDate,
    required this.isAnonymous,
    required this.createdAt,
  });

  factory Donation.fromJson(Map<String, dynamic> json) => Donation(
    id: json['_id'] ?? json['id'] ?? '',
    campaignId: Campaign._id(json['campaign_id']),
    campaignName: Campaign._name(json['campaign_id'], json['campaign_name'], 'title'),
    userId: Campaign._id(json['user_id']),
    userName: Campaign._name(json['user_id'], json['user_name'], 'full_name'),
    amount: (json['amount'] ?? 0).toDouble(),
    paymentMethodId: Campaign._id(json['payment_method_id']),
    paymentMethodName: Campaign._name(json['payment_method_id'], json['payment_method_name'], 'display_name_ar'),
    status: json['status'] ?? 'pending_manual_review',
    referenceNumber: json['reference_number'],
    transferDate: json['transfer_date'] != null ? DateTime.tryParse(json['transfer_date']) : null,
    isAnonymous: json['is_anonymous'] ?? false,
    createdAt: DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
  );

  bool get isPending => status == 'pending_manual_review';
  bool get isConfirmed => status == 'confirmed';
}

class PaymentMethod {
  final String id;
  final String type;
  final String providerKey;
  final String displayNameAr;
  final bool isActive;
  final int sortOrder;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.providerKey,
    required this.displayNameAr,
    required this.isActive,
    required this.sortOrder,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) => PaymentMethod(
    id: json['_id'] ?? json['id'] ?? '',
    type: json['type'] ?? 'manual',
    providerKey: json['provider_key'] ?? '',
    displayNameAr: json['display_name_ar'] ?? '',
    isActive: json['is_active'] ?? true,
    sortOrder: json['sort_order'] ?? 0,
  );
}
