class SurveyField {
  final String fieldKey;
  final String labelAr;
  final String? labelEn;
  final String fieldType;
  final List<String>? options;
  final SurveyValidation? validation;
  final int order;
  final ConditionalLogic? conditionalLogic;

  SurveyField({
    required this.fieldKey,
    required this.labelAr,
    this.labelEn,
    required this.fieldType,
    this.options,
    this.validation,
    required this.order,
    this.conditionalLogic,
  });

  factory SurveyField.fromJson(Map<String, dynamic> json) => SurveyField(
    fieldKey: json['field_key'] ?? '',
    labelAr: json['label_ar'] ?? '',
    labelEn: json['label_en'],
    fieldType: json['field_type'] ?? 'text',
    options: json['options'] != null ? List<String>.from(json['options']) : null,
    validation: json['validation'] != null ? SurveyValidation.fromJson(json['validation']) : null,
    order: json['order'] ?? 0,
    conditionalLogic: json['conditional_logic'] != null ? ConditionalLogic.fromJson(json['conditional_logic']) : null,
  );
}

class SurveyValidation {
  final bool? required;
  final double? min;
  final double? max;
  final String? regex;

  SurveyValidation({this.required, this.min, this.max, this.regex});

  factory SurveyValidation.fromJson(Map<String, dynamic> json) => SurveyValidation(
    required: json['required'],
    min: json['min']?.toDouble(),
    max: json['max']?.toDouble(),
    regex: json['regex'],
  );
}

class ConditionalLogic {
  final String dependsOn;
  final String showWhenValue;

  ConditionalLogic({required this.dependsOn, required this.showWhenValue});

  factory ConditionalLogic.fromJson(Map<String, dynamic> json) => ConditionalLogic(
    dependsOn: json['depends_on'] ?? '',
    showWhenValue: json['show_when_value'] ?? '',
  );
}

class SurveyTemplate {
  final String id;
  final String name;
  final String targetType;
  final List<SurveyField> fields;
  final bool isActive;
  final DateTime? createdAt;

  SurveyTemplate({
    required this.id,
    required this.name,
    required this.targetType,
    required this.fields,
    required this.isActive,
    this.createdAt,
  });

  factory SurveyTemplate.fromJson(Map<String, dynamic> json) => SurveyTemplate(
    id: json['_id'] ?? json['id'] ?? '',
    name: json['name'] ?? '',
    targetType: json['target_type'] ?? '',
    fields: (json['fields'] as List<dynamic>?)?.map((e) => SurveyField.fromJson(e)).toList() ?? [],
    isActive: json['is_active'] ?? true,
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
  );
}
