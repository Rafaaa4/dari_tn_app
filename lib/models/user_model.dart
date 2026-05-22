class UserModel {
  final String? id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final String? profileImage;
  final String status;
  final String createdAt;

  const UserModel({
    this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    this.profileImage,
    this.status = 'active',
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'],
        fullName: map['full_name'],
        email: map['email'],
        phone: map['phone'],
        role: map['role'],
        profileImage: map['profile_image'],
        status: map['status'] ?? 'active',
        createdAt: map['created_at'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'role': role,
        'profile_image': profileImage,
        'status': status,
        'created_at': createdAt,
      };

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? role,
    String? profileImage,
    String? status,
  }) =>
      UserModel(
        id: id ?? this.id,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        role: role ?? this.role,
        profileImage: profileImage ?? this.profileImage,
        status: status ?? this.status,
        createdAt: createdAt,
      );

  bool get isOwner => role == 'owner';
  bool get isTenant => role == 'tenant';
  bool get isAdmin => role == 'admin';
  bool get isActive => status == 'active';
}
