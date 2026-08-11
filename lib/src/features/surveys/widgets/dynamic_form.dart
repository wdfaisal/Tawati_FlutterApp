import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/features/surveys/models/survey_template.dart';

class DynamicForm extends StatefulWidget {
  final SurveyTemplate template;
  final void Function(Map<String, dynamic> answers)? onSubmit;

  const DynamicForm({
    super.key,
    required this.template,
    this.onSubmit,
  });

  @override
  State<DynamicForm> createState() => _DynamicFormState();
}

class _DynamicFormState extends State<DynamicForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _answers = {};
  final Map<String, String?> _filePaths = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    for (final field in widget.template.fields) {
      if (field.fieldType == 'multi_select') {
        _answers[field.fieldKey] = <String>[];
      } else if (field.fieldType == 'date') {
        _answers[field.fieldKey] = null;
      } else if (field.fieldType == 'file_upload') {
        _answers[field.fieldKey] = null;
      } else {
        _answers[field.fieldKey] = '';
      }
    }
  }

  bool _isVisible(SurveyField field) {
    if (field.conditionalLogic == null) return true;
    final triggerValue = _answers[field.conditionalLogic!.dependsOn];
    return triggerValue?.toString() == field.conditionalLogic!.showWhenValue;
  }

  void _onChanged(String key, dynamic value) {
    setState(() => _answers[key] = value);
  }

  Future<void> _pickFile(String fieldKey) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _filePaths[fieldKey] = file.path);
    }
  }

  Future<void> _pickDate(String fieldKey) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (date != null) _onChanged(fieldKey, date.toIso8601String().split('T')[0]);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final result = Map<String, dynamic>.from(_answers);
    _filePaths.forEach((key, value) {
      result[key] = value;
    });
    widget.onSubmit?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    final visibleFields = widget.template.fields.where(_isVisible).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            ...visibleFields.map((f) => _buildField(f)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('حفظ', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(SurveyField field) {
    final validator = _buildValidator(field);
    switch (field.fieldType) {
      case 'text':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            decoration: InputDecoration(labelText: field.labelAr),
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
            validator: validator,
            onChanged: (v) => _onChanged(field.fieldKey, v),
          ),
        );
      case 'number':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: field.labelAr),
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
            validator: validator,
            onChanged: (v) => _onChanged(field.fieldKey, v),
          ),
        );
      case 'phone':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: field.labelAr, prefixText: '+249 '),
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
            validator: validator,
            onChanged: (v) => _onChanged(field.fieldKey, v),
          ),
        );
      case 'date':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () => _pickDate(field.fieldKey),
            child: InputDecorator(
              decoration: InputDecoration(labelText: field.labelAr),
              child: Text(
                _answers[field.fieldKey]?.toString().isEmpty == false
                    ? _answers[field.fieldKey].toString()
                    : 'اختر تاريخاً',
                style: TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  color: _answers[field.fieldKey]?.toString().isEmpty == false ? AppColors.textPrimary : AppColors.textHint,
                ),
              ),
            ),
          ),
        );
      case 'select':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: field.labelAr),
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', color: AppColors.textPrimary),
            items: (field.options ?? []).map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
            value: _answers[field.fieldKey]?.toString().isEmpty == false ? _answers[field.fieldKey].toString() : null,
            onChanged: (v) => _onChanged(field.fieldKey, v),
            validator: validator,
          ),
        );
      case 'radio':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(field.labelAr, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: AppColors.textPrimary)),
              ...(field.options ?? []).map((o) => RadioListTile<String>(
                title: Text(o, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14)),
                value: o,
                groupValue: _answers[field.fieldKey],
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => _onChanged(field.fieldKey, v),
              )),
            ],
          ),
        );
      case 'multi_select':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(field.labelAr, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: AppColors.textPrimary)),
              ...(field.options ?? []).map((o) => CheckboxListTile(
                title: Text(o, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14)),
                value: (_answers[field.fieldKey] as List<String>?)?.contains(o) ?? false,
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.trailing,
                onChanged: (checked) {
                  final list = List<String>.from(_answers[field.fieldKey] as List<String>? ?? []);
                  if (checked == true) {
                    list.add(o);
                  } else {
                    list.remove(o);
                  }
                  _onChanged(field.fieldKey, list);
                },
              )),
            ],
          ),
        );
      case 'file_upload':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(field.labelAr, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _pickFile(field.fieldKey),
                icon: const Icon(Icons.upload_file),
                label: Text(
                  _filePaths[field.fieldKey] != null ? 'تم اختيار ملف' : 'اختر ملفاً',
                  style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13),
                ),
              ),
            ],
          ),
        );
      default:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            decoration: InputDecoration(labelText: field.labelAr),
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
            onChanged: (v) => _onChanged(field.fieldKey, v),
          ),
        );
    }
  }

  String? Function(String?)? _buildValidator(SurveyField field) {
    final validation = field.validation;
    if (validation == null) return null;

    return (value) {
      if (validation.required == true && (value == null || value.isEmpty)) {
        return '${field.labelAr} مطلوب';
      }
      if (value != null && value.isNotEmpty) {
        if (validation.min != null && field.fieldType == 'number') {
          final num = double.tryParse(value);
          if (num != null && num < validation.min!) {
            return '${field.labelAr} يجب أن يكون ${validation.min} على الأقل';
          }
        }
        if (validation.max != null && field.fieldType == 'number') {
          final num = double.tryParse(value);
          if (num != null && num > validation.max!) {
            return '${field.labelAr} يجب أن يكون ${validation.max} على الأكثر';
          }
        }
        if (validation.regex != null) {
          final regex = RegExp(validation.regex!);
          if (!regex.hasMatch(value)) {
            return '${field.labelAr} غير صحيح';
          }
        }
      }
      return null;
    };
  }
}
