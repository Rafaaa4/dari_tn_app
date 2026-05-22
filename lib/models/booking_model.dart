class BookingModel {
  final int? id;
  final int propertyId;
  final String tenantId;
  final String ownerId;
  final String startDate;
  final String endDate;
  final double totalPrice;
  final String status;
  final String paymentStatus;
  final String createdAt;

  // Joined fields
  final String? propertyTitle;
  final String? propertyCity;
  final String? tenantName;
  final String? ownerName;

  const BookingModel({
    this.id,
    required this.propertyId,
    required this.tenantId,
    required this.ownerId,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    this.status = 'pending',
    this.paymentStatus = 'unpaid',
    required this.createdAt,
    this.propertyTitle,
    this.propertyCity,
    this.tenantName,
    this.ownerName,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map) => BookingModel(
        id: map['id'],
        propertyId: map['property_id'],
        tenantId: map['tenant_id'],
        ownerId: map['owner_id'],
        startDate: map['start_date'],
        endDate: map['end_date'],
        totalPrice: (map['total_price'] as num).toDouble(),
        status: map['status'] ?? 'pending',
        paymentStatus: map['payment_status'] ?? 'unpaid',
        createdAt: map['created_at'],
        propertyTitle: map['property_title'],
        propertyCity: map['property_city'],
        tenantName: map['tenant_name'],
        ownerName: map['owner_name'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'property_id': propertyId,
        'tenant_id': tenantId,
        'owner_id': ownerId,
        'start_date': startDate,
        'end_date': endDate,
        'total_price': totalPrice,
        'status': status,
        'payment_status': paymentStatus,
        'created_at': createdAt,
      };

  int get daysCount {
    final start = DateTime.parse(startDate);
    final end = DateTime.parse(endDate);
    return end.difference(start).inDays;
  }
}
