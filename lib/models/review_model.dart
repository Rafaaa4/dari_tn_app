class ReviewModel {
  final int? id;
  final int propertyId;
  final String tenantId;
  final int rating;
  final String? comment;
  final String createdAt;
  final String? tenantName;

  const ReviewModel({
    this.id,
    required this.propertyId,
    required this.tenantId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.tenantName,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) => ReviewModel(
        id: map['id'],
        propertyId: map['property_id'],
        tenantId: map['tenant_id'],
        rating: map['rating'],
        comment: map['comment'],
        createdAt: map['created_at'],
        tenantName: map['tenant_name'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'property_id': propertyId,
        'tenant_id': tenantId,
        'rating': rating,
        'comment': comment,
        'created_at': createdAt,
      };
}

class SponsoredAdModel {
  final int? id;
  final int propertyId;
  final String ownerId;
  final String planName;
  final double price;
  final String startDate;
  final String endDate;
  final String status;
  final String createdAt;

  const SponsoredAdModel({
    this.id,
    required this.propertyId,
    required this.ownerId,
    required this.planName,
    required this.price,
    required this.startDate,
    required this.endDate,
    this.status = 'active',
    required this.createdAt,
  });

  factory SponsoredAdModel.fromMap(Map<String, dynamic> map) =>
      SponsoredAdModel(
        id: map['id'],
        propertyId: map['property_id'],
        ownerId: map['owner_id'],
        planName: map['plan_name'],
        price: (map['price'] as num).toDouble(),
        startDate: map['start_date'],
        endDate: map['end_date'],
        status: map['status'] ?? 'active',
        createdAt: map['created_at'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'property_id': propertyId,
        'owner_id': ownerId,
        'plan_name': planName,
        'price': price,
        'start_date': startDate,
        'end_date': endDate,
        'status': status,
        'created_at': createdAt,
      };

  bool get isActive {
    if (status != 'active') return false;
    return DateTime.parse(endDate).isAfter(DateTime.now());
  }
}
