class JoinRequest {
  final String id;
  final String headFullName;
  final String headPhone;
  final int? headAge;
  final String? headNationalId;
  final String? headMaritalStatus;
  final String? headGender;
  final String? headSpouseName;
  final List<FamilyMemberData> familyMembers;
  final Map<String, dynamic>? surveyAnswers;
  final List<String> documents;
  final String status;
  final String? reviewerName;
  final String? reviewNotes;
  final DateTime createdAt;

  JoinRequest({
    required this.id,
    required this.headFullName,
    required this.headPhone,
    this.headAge,
    this.headNationalId,
    this.headMaritalStatus,
    this.headGender,
    this.headSpouseName,
    required this.familyMembers,
    this.surveyAnswers,
    required this.documents,
    required this.status,
    this.reviewerName,
    this.reviewNotes,
    required this.createdAt,
  });

  factory JoinRequest.fromJson(Map<String, dynamic> json) => JoinRequest(
    id: json['_id'] ?? json['id'] ?? '',
    headFullName: json['head_full_name'] ?? '',
    headPhone: json['head_phone'] ?? '',
    headAge: json['head_age'] as int?,
    headNationalId: json['head_national_id'] as String?,
    headMaritalStatus: json['head_marital_status'] as String?,
    headGender: json['head_gender'] as String?,
    headSpouseName: json['head_spouse_name'] as String?,
    familyMembers: (json['family_members'] as List<dynamic>?)
        ?.map((e) => FamilyMemberData.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    surveyAnswers: json['survey_answers'] != null
        ? Map<String, dynamic>.from(json['survey_answers'] as Map)
        : null,
    documents: List<String>.from(json['documents'] ?? []),
    status: json['status'] ?? 'pending_review',
    reviewerName: json['reviewer_id'] is Map
        ? (json['reviewer_id'] as Map)['full_name']?.toString()
        : null,
    reviewNotes: json['review_notes'] as String?,
    createdAt: DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
  );

  String get statusLabel {
    switch (status) {
      case 'pending_review': return 'قيد الانتظار';
      case 'approved': return 'تم القبول';
      case 'rejected': return 'مرفوض';
      case 'modification_requested': return 'يحتاج تعديل';
      case 'documents_requested': return 'يطلب مستندات';
      default: return status;
    }
  }

  String get typeLabel {
    final members = familyMembers;
    return members.isEmpty ? 'عائلة جديدة' : 'انضمام لعائلة';
  }
}

class FamilyMemberData {
  final String fullName;
  final String? gender;
  final int? age;
  final String? nationalId;
  final String? maritalStatus;
  final String? spouseName;

  FamilyMemberData({
    required this.fullName,
    this.gender,
    this.age,
    this.nationalId,
    this.maritalStatus,
    this.spouseName,
  });

  factory FamilyMemberData.fromJson(Map<String, dynamic> json) => FamilyMemberData(
    fullName: json['full_name'] ?? '',
    gender: json['gender'] as String?,
    age: json['age'] as int?,
    nationalId: json['national_id'] as String?,
    maritalStatus: json['marital_status'] as String?,
    spouseName: json['spouse_name'] as String?,
  );

  String get genderLabel => gender == 'male' ? 'ذكر' : 'أنثى';
}
