class User {
  final String id;
  final String phone;
  final String fullNameAr;
  final String? fullNameEn;
  final String? email;
  final String role;
  final String? familyId;
  final String? familyHeadId;
  final String? avatar;
  final String status;
  final String? memberNumber;
  final String? nationalId;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? maritalStatus;
  final String? membershipLevel;
  final DateTime? joinedAt;
  final DateTime createdAt;

  User({
    required this.id,
    required this.phone,
    required this.fullNameAr,
    this.fullNameEn,
    this.email,
    required this.role,
    this.familyId,
    this.familyHeadId,
    this.avatar,
    required this.status,
    this.memberNumber,
    this.nationalId,
    this.dateOfBirth,
    this.gender,
    this.maritalStatus,
    this.membershipLevel,
    this.joinedAt,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['_id'] ?? json['id'] ?? '',
    phone: json['phone'] ?? '',
    fullNameAr: json['full_name_ar'] ?? json['full_name'] ?? '',
    fullNameEn: json['full_name_en'],
    email: json['email'],
    role: json['role'] ?? json['role_type'] ?? 'member',
    familyId: json['family_id'],
    familyHeadId: json['family_head_id'],
    avatar: json['avatar'] ?? json['profile_picture'],
    status: json['status'] ?? 'active',
    memberNumber: json['member_number'] ?? json['membership_number'],
    nationalId: json['national_id'],
    dateOfBirth: json['date_of_birth'] != null ? DateTime.tryParse(json['date_of_birth']) : null,
    gender: json['gender'],
    maritalStatus: json['marital_status'],
    membershipLevel: json['membership_level'],
    joinedAt: json['joined_at'] != null ? DateTime.tryParse(json['joined_at']) : null,
    createdAt: DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'full_name_ar': fullNameAr,
    'full_name_en': fullNameEn,
    'email': email,
    'national_id': nationalId,
    'date_of_birth': dateOfBirth?.toIso8601String(),
    'gender': gender,
    'marital_status': maritalStatus,
  };

  bool get isActive => status == 'active';
  bool get isAdmin => role == 'super_admin' || role == 'admin';
  bool get isFamilyHead => role == 'head_of_family';

  String get membershipLabel => membershipLevel ?? 'عضو';
}
