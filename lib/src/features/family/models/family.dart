class Family {
  final String id;
  final String name;
  final String? headId;
  final String? headName;
  final List<FamilyMember> members;
  final List<String> ancestors;
  final int? memberCount;
  final String? treeLevel;
  final DateTime createdAt;

  Family({
    required this.id,
    required this.name,
    this.headId,
    this.headName,
    required this.members,
    required this.ancestors,
    this.memberCount,
    this.treeLevel,
    required this.createdAt,
  });

  factory Family.fromJson(Map<String, dynamic> json) => Family(
    id: json['_id'] ?? json['id'] ?? '',
    name: json['name'] ?? '',
    headId: json['head_id'],
    headName: json['head_name'],
    members: (json['members'] as List<dynamic>?)
            ?.map((e) => FamilyMember.fromJson(e)).toList() ?? [],
    ancestors: List<String>.from(json['ancestors'] ?? []),
    memberCount: json['member_count'],
    treeLevel: json['tree_level'],
    createdAt: DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
  );
}

class FamilyMember {
  final String id;
  final String fullNameAr;
  final String role;
  final String? gender;
  final String? maritalStatus;
  final String? relation;

  FamilyMember({
    required this.id,
    required this.fullNameAr,
    required this.role,
    this.gender,
    this.maritalStatus,
    this.relation,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
    id: json['_id'] ?? json['id'] ?? '',
    fullNameAr: json['full_name_ar'] ?? json['full_name'] ?? '',
    role: json['role'] ?? json['role_type'] ?? 'member',
    gender: json['gender'],
    maritalStatus: json['marital_status'],
    relation: json['relation'],
  );
}
