import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tawati_mobile/src/core/biometric_service.dart';
import 'package:tawati_mobile/src/core/providers.dart';
import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/features/auth/providers/auth_provider.dart';
import 'package:tawati_mobile/src/features/family/models/family.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _biometricEnabled = false;
  List<FamilyMember> _familyMembers = [];
  bool _familyLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
    _loadFamilyMembers();
  }

  Future<void> _loadBiometricState() async {
    final bio = ref.read(biometricServiceProvider);
    final enabled = await bio.isEnabled();
    if (mounted) {
      setState(() => _biometricEnabled = enabled);
    }
  }

  Future<void> _loadFamilyMembers() async {
    try {
      final familyService = ref.read(familyServiceProvider);
      final family = await familyService.getMyFamily();
      if (mounted) {
        setState(() {
          _familyMembers = family.members;
          _familyLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _familyLoading = false);
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    final bio = ref.read(biometricServiceProvider);
    if (value) {
      final authed = await bio.authenticate(reason: 'تفعيل تسجيل الدخول بالبصمة');
      if (!mounted) return;
      if (!authed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل التحقق من البصمة، حاول مرة أخرى', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      await bio.setEnabled(true);
      if (mounted) setState(() => _biometricEnabled = true);
    } else {
      await bio.setEnabled(false);
      if (mounted) setState(() => _biometricEnabled = false);
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'head_of_family':
        return 'رب أسرة';
      case 'family_head':
        return 'رب أسرة';
      case 'super_admin':
      case 'admin':
        return 'مشرف';
      default:
        return 'عضو';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (authState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.textHint),
                const SizedBox(height: 16),
                const Text(
                  'لم يتم تحميل بيانات المستخدم',
                  style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final initials = user.fullNameAr.isNotEmpty ? user.fullNameAr[0] : 'ت';
    final membershipNumber = user.memberNumber ?? '';
    final membershipLevel = _roleLabel(user.role);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(initials, user.fullNameAr, membershipNumber, membershipLevel, user.role),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildInfoCard(user, context),
                  const SizedBox(height: 24),
                  _buildFamilyMembersSection(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('الإعدادات'),
                  const SizedBox(height: 8),
                  _ActionTile(
                    icon: Icons.edit_outlined,
                    title: 'تعديل الملف الشخصي',
                    subtitle: 'تحديث بياناتك الشخصية',
                    onTap: () {},
                  ),
                  _ActionTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'تغيير كلمة المرور',
                    subtitle: 'تحديث الرقم السري',
                    onTap: () {},
                  ),
                  _ActionTile(
                    icon: Icons.phone_in_talk_outlined,
                    title: 'تغيير رقم الجوال',
                    subtitle: 'يتطلب التحقق برمز OTP',
                    onTap: () {},
                  ),
                  SwitchListTile(
                    title: const Text(
                      'تسجيل الدخول via البصمة',
                      style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15),
                    ),
                    subtitle: Text(
                      _biometricEnabled ? 'مفعّل' : 'معطّل',
                      style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                    value: _biometricEnabled,
                    onChanged: _toggleBiometric,
                    secondary: const Icon(Icons.fingerprint, color: Color(0xFF0D9488)),
                    activeColor: const Color(0xFF0D9488),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('التنقل'),
                  const SizedBox(height: 8),
                  _ActionTile(
                    icon: Icons.account_tree_outlined,
                    title: 'شجرة العائلة',
                    subtitle: 'عرض شجرة عائلتك',
                    onTap: () => context.go('/family-tree'),
                  ),
                  _ActionTile(
                    icon: Icons.receipt_long_outlined,
                    title: 'سجل التبرعات',
                    subtitle: 'عرض تبرعاتك السابقة',
                    onTap: () => context.go('/donations'),
                  ),
                  _ActionTile(
                    icon: Icons.assignment_outlined,
                    title: 'استبيان الأفراد',
                    subtitle: 'إكمال بياناتك الإضافية',
                    onTap: () {},
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showLogoutDialog(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: const Text(
                        'تسجيل الخروج',
                        style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String initials, String name, String memberNumber, String level, String role) {
    final isFamilyHead = role == 'head_of_family' || role == 'family_head';
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.85),
            const Color(0xFF0F766E),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 96, height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(initials, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(name, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              if (memberNumber.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text(memberNumber, style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.9), letterSpacing: 0.5)),
                ),
              if (memberNumber.isNotEmpty) const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBadge(level, isFamilyHead),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFF34D399).withOpacity(0.25), borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 12, color: Color(0xFF6EE7B7)),
                        SizedBox(width: 4),
                        Text('نشط', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6EE7B7))),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isPrimary ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.95))),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Text(title, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    );
  }

  Widget _buildInfoCard(dynamic user, BuildContext context) {
    final items = <MapEntry<String, String>>[
      if (user.phone.isNotEmpty) MapEntry('رقم الجوال', user.phone),
      if (user.email != null && user.email!.isNotEmpty) MapEntry('البريد الإلكتروني', user.email!),
      if (user.nationalId != null && user.nationalId!.isNotEmpty) MapEntry('رقم الهوية', user.nationalId!),
      MapEntry('الحالة الاجتماعية', _maritalLabel(user.maritalStatus)),
      MapEntry('النوع', _genderLabel(user.gender)),
      if (user.dateOfBirth != null) MapEntry('تاريخ الميلاد', _formatDate(user.dateOfBirth!)),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('البيانات الشخصية', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
            const Divider(height: 24),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(item.key, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: AppColors.textSecondary)),
                  ),
                  Expanded(
                    child: Text(item.value, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary), textAlign: TextAlign.right),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  String _maritalLabel(String? status) {
    switch (status) {
      case 'single': return 'أعزب/عزباء';
      case 'married': return 'متزوج/متزوجة';
      case 'divorced': return 'مطلق/مطلقة';
      case 'widowed': return 'أرمل/أرملة';
      default: return '—';
    }
  }

  String _genderLabel(String? gender) {
    switch (gender) {
      case 'male': return 'ذكر';
      case 'female': return 'أنثى';
      default: return '—';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildFamilyMembersSection() {
    if (_familyLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_familyMembers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('أفراد العائلة'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.people_outline_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_familyMembers.length} أفراد',
                      style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const Divider(height: 24),
                ..._familyMembers.map((member) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          member.fullNameAr.isNotEmpty ? member.fullNameAr[0] : '?',
                          style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.fullNameAr,
                              style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            Text(
                              _familyMemberRoleLabel(member.role),
                              style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (member.relation != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            member.relation!,
                            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _familyMemberRoleLabel(String role) {
    switch (role) {
      case 'head_of_family':
      case 'family_head':
        return 'رب أسرة';
      case 'family_member':
        return 'عضو';
      default:
        return 'عضو';
    }
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تسجيل الخروج', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
          content: const Text('هل أنت متأكد من تسجيل الخروج؟', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
              child: const Text('تسجيل الخروج', style: TextStyle(fontFamily: 'IBMPlexSansArabic', color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.4)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: AppColors.textHint)),
        trailing: Container(
          padding: const EdgeInsets.all(4),
          child: Icon(Icons.chevron_left, color: AppColors.textHint.withOpacity(0.6), size: 22),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
      ),
    );
  }
}
