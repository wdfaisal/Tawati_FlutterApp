import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tawati_mobile/src/core/providers.dart';
import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/features/auth/providers/auth_provider.dart';
import 'package:tawati_mobile/src/features/family/models/family.dart';

const _kPrimary = Color(0xFF044465);
const _kMuted = Color(0xFF9CAFB8);
const _kSecondary = Color(0xFF62707B);
const _kSurface = Color(0xFFF1F5F8);
const _kDark = Color(0xFF1A242B);

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _biometricEnabled = false;
  List<FamilyMember> _familyMembers = [];
  bool _familyLoading = true;
  int _donationsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
    _loadFamilyMembers();
    _loadDonationsCount();
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

  Future<void> _loadDonationsCount() async {
    try {
      final donations = await ref.read(donationServiceProvider).getMyDonations();
      if (mounted) setState(() => _donationsCount = donations.length);
    } catch (_) {
      // ignore: counts stay at zero when the endpoint is unavailable
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
    final contactLine = (user.email != null && user.email!.isNotEmpty) ? user.email! : user.phone;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              _buildHeader(user, initials, contactLine),
              const SizedBox(height: 28),
              _buildStatsRow(),
              const SizedBox(height: 28),
              _buildMenuList(),
            ],
          ),
          Positioned(
            left: 24,
            bottom: 24,
            child: _buildAddFab(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(dynamic user, String initials, String contactLine) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 36),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _kSurface, width: 4),
                  color: _kSurface,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 38, fontWeight: FontWeight.w700, color: _kPrimary),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _showSettingsSheet,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kPrimary,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.add, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            user.fullNameAr,
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          if (contactLine.isNotEmpty)
            Text(
              contactLine,
              style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: _kMuted),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (user.memberNumber != null && user.memberNumber!.isNotEmpty)
                _buildInfoPill(user.memberNumber!),
              if (user.memberNumber != null && user.memberNumber!.isNotEmpty) const SizedBox(width: 8),
              _buildInfoPill(_roleLabel(user.role)),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _showSettingsSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: _kSurface, width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: const Text(
                'تعديل الملف الشخصي',
                style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: _kSurface, borderRadius: BorderRadius.circular(20)),
      child: Text(
        text,
        style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, fontWeight: FontWeight.w500, color: _kSecondary),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.campaign_outlined,
              count: 0,
              label: 'إعلاناتي',
              onTap: () => _comingSoon(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.people_alt_outlined,
              count: 0,
              label: 'مناسباتي',
              onTap: () => _comingSoon(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.favorite_outline,
              count: _donationsCount,
              label: 'تبرعاتي',
              onTap: () => context.go('/donations'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required int count,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Icon(icon, size: 20, color: _kPrimary),
            ),
            const SizedBox(height: 10),
            Text(
              _toArabicDigits(count),
              style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 17, fontWeight: FontWeight.w600, color: _kPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: _kSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildMenuTile(
            icon: Icons.person_outline_rounded,
            title: 'المعلومات الشخصية',
            onTap: _showPersonalInfoSheet,
          ),
          _buildMenuTile(
            icon: Icons.campaign_outlined,
            title: 'الإعلانات الخاصة بي',
            onTap: () => _comingSoon(),
          ),
          _buildMenuTile(
            icon: Icons.volunteer_activism_outlined,
            title: 'سجل تبرعاتي',
            onTap: () => context.pushNamed('myDonations'),
          ),
          _buildMenuTile(
            icon: Icons.people_alt_outlined,
            title: 'مناسباتي',
            onTap: () => _comingSoon(),
          ),
          _buildMenuTile(
            icon: Icons.account_tree_outlined,
            title: 'شجرة العائلة',
            onTap: () => context.go('/family-tree'),
          ),
          _buildMenuTile(
            icon: Icons.assignment_outlined,
            title: 'استبيان الأفراد',
            onTap: () => _comingSoon(),
          ),
          _buildMenuTile(
            icon: Icons.settings_outlined,
            title: 'الإعدادات',
            onTap: _showSettingsSheet,
          ),
          _buildMenuTile(
            icon: Icons.support_agent_outlined,
            title: 'مركز المساعدة',
            onTap: _showHelpSheet,
          ),
          _buildMenuTile(
            icon: Icons.logout_rounded,
            title: 'تسجيل الخروج',
            isDanger: true,
            onTap: () => _showLogoutDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kSurface, width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDanger ? const Color(0xFFFEF2F2) : _kSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDanger ? const Color(0xFFEF4444) : _kPrimary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDanger ? const Color(0xFFEF4444) : _kDark,
                ),
              ),
            ),
            Icon(Icons.chevron_left,
              size: 22,
              color: isDanger ? const Color(0xFFEF4444) : _kMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddFab() {
    return GestureDetector(
      onTap: _showAddSheet,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _kPrimary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: const Icon(Icons.add, size: 26, color: Colors.white),
      ),
    );
  }

  void _comingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('قريباً', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPersonalInfoSheet() {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null) return;

    final items = <MapEntry<String, String>>[
      if (user.phone.isNotEmpty) MapEntry('رقم الجوال', user.phone),
      if (user.email != null && user.email!.isNotEmpty) MapEntry('البريد الإلكتروني', user.email!),
      if (user.nationalId != null && user.nationalId!.isNotEmpty) MapEntry('رقم الهوية', user.nationalId!),
      MapEntry('الحالة الاجتماعية', _maritalLabel(user.maritalStatus)),
      MapEntry('النوع', _genderLabel(user.gender)),
      if (user.dateOfBirth != null) MapEntry('تاريخ الميلاد', _formatDate(user.dateOfBirth!)),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'المعلومات الشخصية',
                          style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 17, fontWeight: FontWeight.w700, color: _kPrimary),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: _kMuted),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 110,
                            child: Text(item.key, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: _kMuted)),
                          ),
                          Expanded(
                            child: Text(
                              item.value,
                              style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: _kDark),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFamilyMembersBlock(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyMembersBlock() {
    if (_familyLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_familyMembers.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 28, color: _kSurface),
        const Text(
          'أفراد العائلة',
          style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15, fontWeight: FontWeight.w700, color: _kDark),
        ),
        const SizedBox(height: 8),
        ..._familyMembers.map(
          (member) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _kSurface,
                  child: Text(
                    member.fullNameAr.isNotEmpty ? member.fullNameAr[0] : '?',
                    style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullNameAr,
                        style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: _kDark),
                      ),
                      Text(
                        _familyMemberRoleLabel(member.role),
                        style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: _kMuted),
                      ),
                    ],
                  ),
                ),
                if (member.relation != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _kSurface, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      member.relation!,
                      style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, color: _kPrimary, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الإعدادات',
                  style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 17, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
                const SizedBox(height: 12),
                _buildSheetTile(
                  icon: Icons.edit_outlined,
                  title: 'تعديل الملف الشخصي',
                  subtitle: 'تحديث بياناتك الشخصية',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _comingSoon();
                  },
                ),
                _buildSheetTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'تغيير كلمة المرور',
                  subtitle: 'تحديث الرقم السري',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _comingSoon();
                  },
                ),
                _buildSheetTile(
                  icon: Icons.phone_in_talk_outlined,
                  title: 'تغيير رقم الجوال',
                  subtitle: 'يتطلب التحقق برمز OTP',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _comingSoon();
                  },
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SwitchListTile(
                    title: const Text(
                      'تسجيل الدخول بالبصمة',
                      style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: _kDark),
                    ),
                    subtitle: Text(
                      _biometricEnabled ? 'مفعّل' : 'معطّل',
                      style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: _kMuted),
                    ),
                    secondary: const Icon(Icons.fingerprint, color: _kPrimary),
                    activeThumbColor: _kPrimary,
                    value: _biometricEnabled,
                    onChanged: (value) {
                      Navigator.of(ctx).pop();
                      _toggleBiometric(value);
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHelpSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مركز المساعدة',
                  style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 17, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
                const SizedBox(height: 12),
                _buildSheetTile(
                  icon: Icons.email_outlined,
                  title: 'تواصل معنا',
                  subtitle: 'مراسلة فريق الدعم',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _comingSoon();
                  },
                ),
                _buildSheetTile(
                  icon: Icons.question_answer_outlined,
                  title: 'الأسئلة الشائعة',
                  subtitle: 'إجابات عن الاستفسارات المتكررة',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _comingSoon();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إضافة محتوى',
                  style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 17, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
                const SizedBox(height: 12),
                _buildSheetTile(
                  icon: Icons.campaign_outlined,
                  title: 'إعلان جديد',
                  subtitle: 'نشر إعلان لأفراد العائلة',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    context.push('/add-announcement');
                  },
                ),
                _buildSheetTile(
                  icon: Icons.bed_outlined,
                  title: 'خبر وفاء',
                  subtitle: 'نشر نعي لفقيد من العائلة',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    context.push('/add-obituary');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: _kPrimary),
        ),
        title: Text(title, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: _kDark)),
        subtitle: Text(subtitle, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: _kMuted)),
        trailing: const Icon(Icons.chevron_left, size: 22, color: _kMuted),
        onTap: onTap,
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

  String _familyMemberRoleLabel(String role) {
    switch (role) {
      case 'head_of_family':
      case 'family_head':
        return 'رب أسرة';
      default:
        return 'عضو';
    }
  }

  String _toArabicDigits(num value) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    return value.toString().split('').map((c) {
      final i = c.codeUnitAt(0) - 48;
      return (i >= 0 && i <= 9) ? arabic[i] : c;
    }).join();
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
