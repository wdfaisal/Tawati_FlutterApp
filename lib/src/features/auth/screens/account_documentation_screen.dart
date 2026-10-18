import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class _DocChild {
  String fullName = '';
  String gender = 'male';
  int? age;
  String? nationalId;
  String phone = '';
  DateTime? dateOfBirth;
}

class AccountDocumentationScreen extends ConsumerStatefulWidget {
  const AccountDocumentationScreen({super.key});

  @override
  ConsumerState<AccountDocumentationScreen> createState() => _AccountDocumentationScreenState();
}

class _AccountDocumentationScreenState extends ConsumerState<AccountDocumentationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nationalIdCtrl = TextEditingController();
  DateTime? _dateOfBirth;
  String _maritalStatus = 'single';
  final _spouseNameCtrl = TextEditingController();

  bool _hasChildren = false;
  int _childCount = 0;
  final List<_DocChild> _children = [];

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) {
      _nationalIdCtrl.text = user.nationalId ?? '';
      _dateOfBirth = user.dateOfBirth;
      _maritalStatus = user.maritalStatus ?? 'single';
    }
  }

  @override
  void dispose() {
    _nationalIdCtrl.dispose();
    _spouseNameCtrl.dispose();
    super.dispose();
  }

  bool get _needsSpouse => _maritalStatus == 'married' || _maritalStatus == 'widowed';

  InputDecoration _inputDecoration({
    required String hint,
    IconData? icon,
    Widget? suffix,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', color: AppColors.textHint, fontSize: 14),
      prefixIcon: icon != null ? Icon(icon, color: AppColors.textHint, size: 20) : null,
      suffixIcon: suffix,
      errorText: errorText,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error, width: 2)),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    );
  }

  Widget _sectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _genderSelector(String value, ValueChanged<String> onChanged) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Row(
        children: ['ذكر', 'أنثى'].asMap().entries.map((e) {
          final val = e.value == 'ذكر' ? 'male' : 'female';
          final selected = value == val;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(val),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  e.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : AppColors.textSecondary),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final ok = await ref.read(authProvider.notifier).submitDocumentation(
      nationalId: _nationalIdCtrl.text.trim().isEmpty ? null : _nationalIdCtrl.text.trim(),
      dateOfBirth: _dateOfBirth?.toIso8601String(),
      maritalStatus: _maritalStatus,
      spouseName: _needsSpouse ? _spouseNameCtrl.text.trim() : null,
      children: _children
          .map((c) => {
                'fullName': c.fullName,
                'phone': c.phone.isEmpty ? null : c.phone,
                'gender': c.gender,
                'age': c.age,
                'nationalId': c.nationalId,
                'dateOfBirth': c.dateOfBirth?.toIso8601String(),
                'maritalStatus': 'single',
              })
          .toList(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ بيانات التوثيق بنجاح', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.goNamed('home');
    } else {
      final err = ref.read(authProvider).error ?? 'تعذّر حفظ البيانات، حاول مرة أخرى';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err, style: const TextStyle(fontFamily: 'IBMPlexSansArabic')),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('توثيق الحساب', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('مرحباً ${user?.fullNameAr ?? ''}', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          const SizedBox(height: 4),
                          const Text('أكمل بياناتك التالية لتوثيق حسابك والانضمام إلى شجرة العائلة.', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _sectionCard('البيانات الشخصية', Icons.person_outline, [
                _label('رقم الهوية الوطنية'),
                TextFormField(
                  controller: _nationalIdCtrl,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16),
                  decoration: _inputDecoration(hint: 'رقم الهوية', icon: Icons.badge_outlined),
                ),
                const SizedBox(height: 16),
                _label('تاريخ الميلاد'),
                GestureDetector(
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dateOfBirth ?? DateTime(now.year - 25, 1, 1),
                      firstDate: DateTime(now.year - 120, 1, 1),
                      lastDate: now,
                      helpText: 'اختر تاريخ الميلاد',
                      cancelText: 'إلغاء',
                      confirmText: 'تأكيد',
                    );
                    if (picked != null) setState(() => _dateOfBirth = picked);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppColors.textHint, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _dateOfBirth != null
                              ? '${_dateOfBirth!.year}/${_dateOfBirth!.month.toString().padLeft(2, '0')}/${_dateOfBirth!.day.toString().padLeft(2, '0')}'
                              : 'اختر تاريخ الميلاد',
                          style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15, color: _dateOfBirth != null ? AppColors.textPrimary : AppColors.textHint),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
              _sectionCard('الحالة الاجتماعية', Icons.favorite_border, [
                ...['single', 'married', 'divorced', 'widowed'].map((value) {
                  final labels = {'single': 'أعزب', 'married': 'متزوج', 'divorced': 'مطلق', 'widowed': 'أرمل'};
                  final selected = _maritalStatus == value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => _maritalStatus = value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primaryLight : AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
                        ),
                        child: Row(
                          children: [
                            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: selected ? AppColors.primary : AppColors.textHint, size: 22),
                            const SizedBox(width: 12),
                            Text(labels[value]!, style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15,
                                color: selected ? AppColors.primary : AppColors.textPrimary,
                                fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                if (_needsSpouse) ...[
                  const SizedBox(height: 6),
                  _label(_maritalStatus == 'married' ? 'اسم الزوجة (رباعي)' : 'اسم الزوج (رباعي)'),
                  TextFormField(
                    controller: _spouseNameCtrl,
                    style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16),
                    decoration: _inputDecoration(hint: 'الاسم - الأب - الجد - العائلة'),
                  ),
                ],
              ]),
              _sectionCard('الأبناء', Icons.family_restroom_outlined, [
                Row(
                  children: [
                    const Expanded(
                      child: Text('هل لديك أبناء؟', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ),
                    Switch(
                      value: _hasChildren,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) {
                        setState(() {
                          _hasChildren = v;
                          if (v && _childCount == 0) {
                            _childCount = 1;
                            _updateChildCount(1);
                          } else if (!v) {
                            _childCount = 0;
                            _children.clear();
                          }
                        });
                      },
                    ),
                  ],
                ),
                if (_hasChildren) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _childCount > 1
                            ? () => setState(() { _childCount--; _updateChildCount(_childCount); })
                            : null,
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: _childCount > 1 ? AppColors.primary : AppColors.border),
                          child: const Icon(Icons.remove, color: Colors.white, size: 20),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text('$_childCount', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() { _childCount++; _updateChildCount(_childCount); });
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
                          child: const Icon(Icons.add, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('أبناء', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_children.length, (i) => _buildChildCard(i)),
                ],
              ]),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('حفظ ومتابعة', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateChildCount(int count) {
    while (_children.length < count) {
      _children.add(_DocChild());
    }
    if (count < _children.length) {
      _children.removeRange(count, _children.length);
    }
  }

  Widget _buildChildCard(int index) {
    final child = _children[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('الابن ${index + 1}', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() { _children.removeAt(index); _childCount = _children.length; }),
                icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                visualDensity: VisualDensity.compact,
                tooltip: 'حذف',
              ),
            ],
          ),
          _label('الاسم الرباعي'),
          TextFormField(
            initialValue: child.fullName,
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15),
            decoration: _inputDecoration(hint: 'الاسم - الأب - الجد - العائلة'),
            onChanged: (v) => child.fullName = v,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('النوع'),
                    _genderSelector(child.gender, (v) => setState(() => child.gender = v)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('العمر'),
                    GestureDetector(
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: now,
                          firstDate: DateTime(now.year - 100, 1, 1),
                          lastDate: now,
                          helpText: 'اختر تاريخ الميلاد',
                          cancelText: 'إلغاء',
                          confirmText: 'تأكيد',
                        );
                        if (picked != null) setState(() { child.age = now.year - picked.year; child.dateOfBirth = picked; });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          child.age != null ? '${child.age}' : '--',
                          style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15, color: child.age != null ? AppColors.textPrimary : AppColors.textHint),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _label('رقم الجوال'),
          TextFormField(
            initialValue: child.phone,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15),
            decoration: _inputDecoration(hint: '9XXXXXXXX'),
            onChanged: (v) => child.phone = v,
          ),
          const SizedBox(height: 12),
          _label('رقم الهوية (اختياري)'),
          TextFormField(
            initialValue: child.nationalId,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15),
            decoration: _inputDecoration(hint: 'رقم الهوية'),
            onChanged: (v) => child.nationalId = v,
          ),
        ],
      ),
    );
  }
}
