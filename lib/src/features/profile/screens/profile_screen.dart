import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:go_router/go_router.dart';

import 'package:tawati_mobile/src/core/providers.dart';
import 'package:tawati_mobile/src/features/auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isDarkMode = false;
  bool _biometricEnabled = false;
  int _myAnnouncementsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
    _loadMyAnnouncementsCount();
  }

  Future<void> _loadBiometricState() async {
    final bio = ref.read(biometricServiceProvider);
    final enabled = await bio.isEnabled();
    if (mounted) {
      setState(() => _biometricEnabled = enabled);
    }
  }

  Future<void> _loadMyAnnouncementsCount() async {
    try {
      final items = await ref.read(newsServiceProvider).getMyNews(limit: 100);
      if (mounted) {
        setState(() => _myAnnouncementsCount = items.length);
      }
    } catch (_) {}
  }

  Future<void> _toggleBiometric(bool value) async {
    final bio = ref.read(biometricServiceProvider);
    if (value) {
      final authed = await bio.authenticate(reason: 'تفعيل تسجيل الدخول via البصمة');
      if (!authed) return;
      await bio.setEnabled(true);
      setState(() => _biometricEnabled = true);
    } else {
      await bio.setEnabled(false);
      setState(() => _biometricEnabled = false);
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}';
    }
    return parts.first[0];
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'تسجيل الخروج',
          style: TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'هل أنت متأكد من تسجيل الخروج؟',
          style: TextStyle(
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'إلغاء',
              style: TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                color: Color(0xFF64748B),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'تسجيل الخروج',
              style: TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        context.goNamed('splash');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final userName = user?.fullNameAr ?? 'المستخدم';
    final userPhone = user?.phone ?? '';
    final nationalId = user?.nationalId ?? '';
    final familyName = ''; // Available via family service
    final familyHeadName = user?.familyHeadId ?? '';
    final role = user?.role ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        title: const Text(
          'الملف الشخصي',
          style: TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: const Color(0xFF0D9488),
                    child: Text(
                      _getInitials(userName),
                      style: const TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userPhone,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 15,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  if (nationalId.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'الهوية: $nationalId',
                      style: const TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionCard(
              title: 'معلومات العائلة',
              icon: Icons.family_restroom,
              children: [
                _buildInfoTile('اسم العائلة', familyName),
                _buildInfoTile('رب الأسرة', familyHeadName),
                _buildInfoTile('الدور', role),
              ],
            ),
            _buildSectionCard(
              title: 'نشاطي',
              icon: Icons.dashboard_outlined,
              children: [
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.campaign_outlined, color: Color(0xFF0D9488), size: 20),
                  ),
                  title: const Text(
                    'إعلاناتي',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    '$_myAnnouncementsCount إعلان منشور',
                    style: const TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_myAnnouncementsCount',
                      style: const TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                  ),
                  onTap: () => context.push('/my-announcements'),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.volunteer_activism_outlined, color: Color(0xFF0D9488), size: 20),
                  ),
                  title: const Text(
                    'تبرعاتي',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 15,
                    ),
                  ),
                  subtitle: const Text(
                    'سجل التبرعات والمساهمات',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xFF94A3B8),
                  ),
                  onTap: () => context.push('/my-donations'),
                ),
              ],
            ),
            _buildSectionCard(
              title: 'الإعدادات',
              icon: Icons.settings,
              children: [
                SwitchListTile(
                  title: const Text(
                    'الوضع الداكن',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    _isDarkMode ? 'مفعّل' : 'معطّل',
                    style: const TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  value: _isDarkMode,
                  onChanged: (value) {
                    setState(() => _isDarkMode = value);
                  },
                  secondary: Icon(
                    _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: const Color(0xFF0D9488),
                  ),
                  activeColor: const Color(0xFF0D9488),
                ),
                SwitchListTile(
                    title: const Text(
                      'تسجيل الدخول via البصمة',
                      style: TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      _biometricEnabled ? 'مفعّل' : 'معطّل',
                      style: const TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    value: _biometricEnabled,
                    onChanged: _toggleBiometric,
                    secondary: const Icon(
                      Icons.fingerprint,
                      color: Color(0xFF0D9488),
                    ),
                    activeColor: const Color(0xFF0D9488),
                  ),
                ListTile(
                  leading: const Icon(
                    Icons.language,
                    color: Color(0xFF0D9488),
                  ),
                  title: const Text(
                    'تغيير اللغة',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 15,
                    ),
                  ),
                  subtitle: const Text(
                    'العربية',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xFF94A3B8),
                  ),
                  onTap: () {},
                ),
              ],
            ),
            _buildSectionCard(
              title: 'الدعم',
              icon: Icons.help_outline,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.email_outlined,
                    color: Color(0xFF0D9488),
                  ),
                  title: const Text(
                    'تواصل معنا',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 15,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xFF94A3B8),
                  ),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(
                    Icons.question_answer_outlined,
                    color: Color(0xFF0D9488),
                  ),
                  title: const Text(
                    'الأسئلة الشائعة',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 15,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xFF94A3B8),
                  ),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'تسجيل الخروج',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'الإصدار 1.0.0',
              style: TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 12,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: const Color(0xFF0D9488)),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return ListTile(
      dense: true,
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 13,
          color: Color(0xFF94A3B8),
        ),
      ),
      subtitle: Text(
        value.isNotEmpty ? value : '-',
        style: const TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 15,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }
}
