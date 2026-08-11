class Initiative {
  final String id;
  final String title;
  final String? description;
  final String type;
  final String? image;
  final String? location;
  final DateTime? startDate;
  final DateTime? endDate;
  final int maxParticipants;
  final String status;
  final int participantCount;
  final bool isRegistered;
  final String? createdByName;
  final DateTime createdAt;

  Initiative({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.image,
    this.location,
    this.startDate,
    this.endDate,
    required this.maxParticipants,
    required this.status,
    required this.participantCount,
    this.isRegistered = false,
    this.createdByName,
    required this.createdAt,
  });

  factory Initiative.fromJson(Map<String, dynamic> json) => Initiative(
    id: json['_id'] ?? json['id'] ?? '',
    title: json['title'] ?? '',
    description: json['description'],
    type: json['type'] ?? 'activity',
    image: json['image'],
    location: json['location'],
    startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date']) : null,
    endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null,
    maxParticipants: json['capacity'] ?? json['max_participants'] ?? 0,
    status: json['status'] ?? 'active',
    participantCount: json['participant_count'] ?? json['participantCount'] ?? 0,
    isRegistered: json['is_registered'] == true,
    createdByName: json['created_by_name'],
    createdAt: DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
  );

  bool get isFull => maxParticipants > 0 && participantCount >= maxParticipants;
  bool get isPast => endDate != null && endDate!.isBefore(DateTime.now());
}
