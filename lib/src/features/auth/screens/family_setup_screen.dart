import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tawati_mobile/src/core/error_handler.dart';
import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/features/auth/providers/auth_provider.dart';

class _ChildEntry {
  String fullName = '';
  String gender = 'male';
  String maritalStatus = 'single';
  String? age;
}

class FamilySetupScreen extends ConsumerStatefulWidget {
  final String userId;

  const FamilySetupScreen({super.key, required this.userId});

  @override
  ConsumerState<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends ConsumerState<FamilySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _spouseCtrl = TextEditingController();
  final _children = <_ChildEntry>[];
  bool _isLoading = false;

  @override
  void dispose() {
    _spouseCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).setupFamily(
        userId: widget.userId,
        spouseName: _spouseCtrl.text.trim(),
        children: _children
            .where((c) => c.fullName.trim().isNotEmpty)
            .map((c) => {
                  'fullName': c.fullName.trim(),
                  'gender': c.gender,
                  'maritalStatus': c.maritalStatus,
                  if (c.age != null && c.age!.isNotEmpty) 'age': int.tryParse(c.age!),
                })
            .toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تم إنشاء عائلتك بنجاح', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      final name = ref.read(authProvider).user?.fullNameAr ?? '';
      context.goNamed('welcome', extra: {'name': name});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(friendlyError(e), style: const TextStyle(fontFamily: 'IBMPlexSansArabic')),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'إعداد العائلة',
            style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.family_restroom, size: 40, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'أنشئ عائلتك الجديدة',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'كابن متزوج، أنشئ عائلتك المستقلة المرتبطة بعائلة والدك',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 32),

                const Text('اسم الزوجة (رباعي) *', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _spouseCtrl,
                  style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'الاسم - الأب - الجد - العائلة',
                    hintStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', color: AppColors.textHint),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty || v.trim().split(' ').length < 4) {
                      return 'أدخل اسم الزوجة رباعياً';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),
                Row(
                  children: [
                    const Expanded(
                      child: Text('الأبناء (اختياري)', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(() => _children.add(_ChildEntry())),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('إضافة ابن'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        textStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_children.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.child_care_outlined, size: 40, color: AppColors.textHint),
                        SizedBox(height: 8),
                        Text('يمكنك إضافة أبنائك لاحقاً', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: AppColors.textHint)),
                      ],
                    ),
                  )
                else
                  ..._children.asMap().entries.map((entry) {
                    final index = entry.key;
                    final child = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('الابن ${index + 1}', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                                onPressed: () => setState(() => _children.removeAt(index)),
                              ),
                            ],
                          ),
                          TextFormField(
                            initialValue: child.fullName,
                            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15),
                            decoration: InputDecoration(
                              labelText: 'الاسم الرباعي',
                              labelStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: AppColors.textSecondary),
                              hintText: 'الاسم - الأب - الجد - العائلة',
                              hintStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', color: AppColors.textHint, fontSize: 13),
                              filled: true,
                              fillColor: AppColors.surface,
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
                            onChanged: (v) => child.fullName = v,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: child.gender,
                                  decoration: _childFieldDecoration('النوع'),
                                  style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: AppColors.textPrimary),
                                  items: const [
                                    DropdownMenuItem(value: 'male', child: Text('ذكر', style: TextStyle(fontFamily: 'IBMPlexSansArabic'))),
                                    DropdownMenuItem(value: 'female', child: Text('أنثى', style: TextStyle(fontFamily: 'IBMPlexSansArabic'))),
                                  ],
                                  onChanged: (v) => setState(() => child.gender = v ?? 'male'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: child.maritalStatus,
                                  decoration: _childFieldDecoration('الحالة'),
                                  style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: AppColors.textPrimary),
                                  items: const [
                                    DropdownMenuItem(value: 'single', child: Text('أعزب', style: TextStyle(fontFamily: 'IBMPlexSansArabic'))),
                                    DropdownMenuItem(value: 'married', child: Text('متزوج', style: TextStyle(fontFamily: 'IBMPlexSansArabic'))),
                                    DropdownMenuItem(value: 'divorced', child: Text('مطلق', style: TextStyle(fontFamily: 'IBMPlexSansArabic'))),
                                    DropdownMenuItem(value: 'widowed', child: Text('أرمل', style: TextStyle(fontFamily: 'IBMPlexSansArabic'))),
                                  ],
                                  onChanged: (v) => setState(() => child.maritalStatus = v ?? 'single'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  initialValue: child.age,
                                  keyboardType: TextInputType.number,
                                  textDirection: TextDirection.ltr,
                                  style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14),
                                  decoration: _childFieldDecoration('العمر'),
                                  onChanged: (v) => child.age = v,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('إنشاء العائلة', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _childFieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}
