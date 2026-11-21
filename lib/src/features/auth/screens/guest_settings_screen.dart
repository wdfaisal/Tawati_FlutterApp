import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tawati_mobile/src/core/legal.dart';
import 'package:tawati_mobile/src/core/theme/theme_controller.dart';
import 'package:tawati_mobile/src/features/auth/screens/login_sheet.dart';

const _kPrimary = Color(0xFF044465);
const _kMuted = Color(0xFF9CAFB8);
const _kSecondary = Color(0xFF62707B);
const _kSurface = Color(0xFFF1F5F8);
const _kDark = Color(0xFF1A242B);

class GuestSettingsScreen extends ConsumerWidget {
  const GuestSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              _buildHeader(context),
              const SizedBox(height: 28),
              _buildMenuList(context, ref, themeMode),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'الإصدار 1.0.0',
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 12,
                    color: _kMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 36),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _kSurface, width: 4),
              color: _kSurface,
            ),
            child: const Center(
              child: Icon(Icons.person_outline_rounded, size: 46, color: _kPrimary),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'الإعدادات',
            style: TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'أنت في وضع الزائر',
            style: TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 14,
              color: _kMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: _kSurface, borderRadius: BorderRadius.circular(20)),
            child: const Text(
              'زائر',
              style: TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _kSecondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => showLoginSheet(context),
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.login_rounded, size: 16, color: _kPrimary),
                  SizedBox(width: 6),
                  Text(
                    'تسجيل الدخول',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _kPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList(BuildContext context, WidgetRef ref, ThemeMode themeMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildMenuTile(
            icon: ThemeModeStorage.icon(themeMode),
            title: 'مظهر التطبيق',
            subtitle: ThemeModeStorage.label(themeMode),
            onTap: () => _showThemePicker(context, ref, themeMode),
          ),
          _buildMenuTile(
            icon: Icons.family_restroom_rounded,
            title: 'حول منصة تواتي',
            onTap: () => _showAboutSheet(context),
          ),
          _buildMenuTile(
            icon: Icons.privacy_tip_outlined,
            title: 'سياسة الخصوصية',
            onTap: () => context.push('/privacy-policy'),
          ),
          _buildMenuTile(
            icon: Icons.description_outlined,
            title: 'الشروط والأحكام',
            onTap: () => context.push('/terms'),
          ),
          _buildMenuTile(
            icon: Icons.support_agent_outlined,
            title: 'الشكاوى والاقتراحات',
            onTap: () => _contactSupport(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
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
                color: _kSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: _kPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _kDark,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 12,
                        color: _kMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_left, size: 22, color: _kMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _showThemePicker(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'مظهر التطبيق',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final mode in const [ThemeMode.light, ThemeMode.dark, ThemeMode.system])
                    _ThemeOptionTile(
                      mode: mode,
                      selected: current == mode,
                      onTap: () async {
                        await ref.read(themeModeProvider.notifier).setMode(mode);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAboutSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.62,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _kSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.family_restroom_rounded, color: _kPrimary),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'حول منصة تواتي',
                            style: TextStyle(
                              fontFamily: 'IBMPlexSansArabic',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _kPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _AboutParagraph(
                      'تواتي منصة رقمية لخدمة العائلة، تيسّر التواصل، ومتابعة الأخبار والمناسبات والمبادرات، والمساهمة في صناديق التبرعات بما يعزز روح التكافل والترابط.',
                    ),
                    const SizedBox(height: 10),
                    const _AboutParagraph(
                      'توفّر المنصة قنوات للتواصل مع اللجان، وطلبات الإحسان، واستقبال الشكاوى والاقتراحات، وذلك وفق السياسات والإجراءات المعتمدة لدى الجهة المشغّلة.',
                    ),
                    const SizedBox(height: 10),
                    const _AboutParagraph(
                      'يمكنك الاطلاع على مستندات سياسة الخصوصية والشروط والأحكام من قسم المستندات، كما يمكنك التواصل مع فريق الدعم ولجان الإحسان والشكاوى عبر قنوات التواصل المتاحة.',
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _kSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kSurface),
                      ),
                      child: const Text(
                        'تواتي — لجان الإحسان والشكاوى',
                        style: TextStyle(
                          fontFamily: 'IBMPlexSansArabic',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kDark,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _contactSupport(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: LegalLinks.supportEmail,
      queryParameters: {'subject': 'تواصل / شكوى - منصة تواتي'},
    );
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر فتح تطبيق البريد', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
        ),
      );
    }
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final ThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected ? _kPrimary.withValues(alpha: 0.06) : _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? _kPrimary.withValues(alpha: 0.3) : _kSurface),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(ThemeModeStorage.icon(mode), color: selected ? _kPrimary : _kSecondary),
        title: Text(
          ThemeModeStorage.label(mode),
          style: TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? _kPrimary : _kDark,
          ),
        ),
        trailing: selected ? const Icon(Icons.check_circle_rounded, color: _kPrimary, size: 20) : null,
        onTap: onTap,
      ),
    );
  }
}

class _AboutParagraph extends StatelessWidget {
  final String text;
  const _AboutParagraph(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'IBMPlexSansArabic',
        fontSize: 13.5,
        height: 1.8,
        color: _kSecondary,
      ),
    );
  }
}
