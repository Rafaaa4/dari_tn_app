class PropertyModel {
  final int? id;
  final String ownerId;
  final String title;
  final String description;
  final String type;
  final String city;
  final String? address;
  final double price;
  final String priceType;
  final int rooms;
  final int bathrooms;
  final double? surface;
  final String? conditions;
  final String? contact;
  final bool isAvailable;
  final bool isSponsored;
  final String status;
  final int views;
  final String createdAt;

  // Joined fields
  final List<String> images;
  final String? ownerName;
  final double? avgRating;
  final int? reviewCount;

  const PropertyModel({
    this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.type,
    required this.city,
    this.address,
    required this.price,
    this.priceType = 'month',
    this.rooms = 1,
    this.bathrooms = 1,
    this.surface,
    this.conditions,
    this.contact,
    this.isAvailable = true,
    this.isSponsored = false,
    this.status = 'pending',
    this.views = 0,
    required this.createdAt,
    this.images = const [],
    this.ownerName,
    this.avgRating,
    this.reviewCount,
  });

  factory PropertyModel.fromMap(Map<String, dynamic> map) => PropertyModel(
        id: map['id'],
        ownerId: map['owner_id'],
        title: map['title'],
        description: map['description'],
        type: map['type'],
        city: map['city'],
        address: map['address'],
        price: (map['price'] as num).toDouble(),
        priceType: map['price_type'] ?? 'month',
        rooms: map['rooms'] ?? 1,
        bathrooms: map['bathrooms'] ?? 1,
        surface:
            map['surface'] != null ? (map['surface'] as num).toDouble() : null,
        conditions: map['conditions'],
        contact: map['contact'],
        isAvailable: map['is_available'] ?? true,
        isSponsored: map['is_sponsored'] ?? false,
        status: map['status'] ?? 'pending',
        views: map['views'] ?? 0,
        createdAt: map['created_at'],
        ownerName: map['owner_name'],
        avgRating: map['avg_rating'] != null
            ? (map['avg_rating'] as num).toDouble()
            : null,
        reviewCount: map['review_count'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'owner_id': ownerId,
        'title': title,
        'description': description,
        'type': type,
        'city': city,
        'address': address,
        'price': price,
        'price_type': priceType,
        'rooms': rooms,
        'bathrooms': bathrooms,
        'surface': surface,
        'conditions': conditions,
        'contact': contact,
        'is_available': isAvailable,
        'is_sponsored': isSponsored,
        'status': status,
        'views': views,
        'created_at': createdAt,
      };

  PropertyModel copyWith({
    String? ownerId,
    String? title,
    String? description,
    String? type,
    String? city,
    Object? address = _sentinel,
    double? price,
    String? priceType,
    int? rooms,
    int? bathrooms,
    Object? surface = _sentinel,
    Object? conditions = _sentinel,
    Object? contact = _sentinel,
    List<String>? images,
    bool? isSponsored,
    bool? isAvailable,
    String? status,
    int? views,
    String? createdAt,
  }) =>
      PropertyModel(
        id: id,
        ownerId: ownerId ?? this.ownerId,
        title: title ?? this.title,
        description: description ?? this.description,
        type: type ?? this.type,
        city: city ?? this.city,
        address: address == _sentinel ? this.address : address as String?,
        price: price ?? this.price,
        priceType: priceType ?? this.priceType,
        rooms: rooms ?? this.rooms,
        bathrooms: bathrooms ?? this.bathrooms,
        surface: surface == _sentinel ? this.surface : surface as double?,
        conditions:
            conditions == _sentinel ? this.conditions : conditions as String?,
        contact: contact == _sentinel ? this.contact : contact as String?,
        isAvailable: isAvailable ?? this.isAvailable,
        isSponsored: isSponsored ?? this.isSponsored,
        status: status ?? this.status,
        views: views ?? this.views,
        createdAt: createdAt ?? this.createdAt,
        images: images ?? this.images,
        ownerName: ownerName,
        avgRating: avgRating,
        reviewCount: reviewCount,
      );

  String get priceLabel {
    switch (priceType) {
      case 'day':
        return '/jour';
      case 'week':
        return '/semaine';
      default:
        return '/mois';
    }
  }

  bool get isPublished => status == 'published';
}

const Object _sentinel = Object();
