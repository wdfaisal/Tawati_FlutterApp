import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tawati_mobile/src/core/legal.dart';
import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/core/theme/theme_controller.dart';
import 'package:tawati_mobile/src/features/auth/screens/login_sheet.dart';

class GuestSettingsScreen extends ConsumerWidget {
  const GuestSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'الإعدادات',
            style: TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _LoginHeroCard(
              onLogin: () => showLoginSheet(context),
            ),
            const SizedBox(height: 20),
            const _SectionTitle(title: 'عام'),
            const SizedBox(height: 8),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.palette_outlined,
                  iconColor: AppColors.primary,
                  title: 'مظهر التطبيق',
                  subtitle: ThemeModeStorage.label(themeMode),
                  onTap: () => _showThemePicker(context, ref, themeMode),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _SectionTitle(title: 'حول المنصة والمستندات'),
            const SizedBox(height: 8),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: const Color(0xFF0D9488),
                  title: 'حول منصة تواتي',
                  subtitle: 'تعريف بالمنصة وخدماتها',
                  onTap: () => _showAboutSheet(context),
                ),
                _divider(isDark),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: const Color(0xFF2563EB),
                  title: 'سياسة الخصوصية',
                  subtitle: 'وثائق الخصوصية لتواتي ولجان الإحسان والشكاوى',
                  onTap: () => context.push('/privacy-policy'),
                ),
                _divider(isDark),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  iconColor: const Color(0xFF7C3AED),
                  title: 'الشروط والأحكام',
                  subtitle: 'شروط استخدام منصة تواتي',
                  onTap: () => context.push('/terms'),
                ),
                _divider(isDark),
                _SettingsTile(
                  icon: Icons.support_agent_outlined,
                  iconColor: const Color(0xFFEA580C),
                  title: 'الشكاوى والاقتراحات',
                  subtitle: 'التواصل مع لجان الإحسان والشكاوى والدعم',
                  onTap: () => _contactSupport(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? scheme.surfaceContainerHighest.withValues(alpha: 0.35)
                    : AppColors.primaryLight.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white12 : AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 20, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'أنت في وضع الزائر. سجّل الدخول للوصول إلى الهوية الرقمية، شجرة العائلة، المجموعات، وبقية خدمات الأعضاء.',
                      style: TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 12.5,
                        height: 1.7,
                        color: scheme.onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _divider(bool isDark) => Divider(
        height: 1,
        indent: 56,
        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
      );

  Future<void> _showThemePicker(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                  const SizedBox(height: 14),
                  const Text(
                    'مظهر التطبيق',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'اختر المظهر المناسب لك',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final mode in const [
                    ThemeMode.light,
                    ThemeMode.dark,
                    ThemeMode.system,
                  ])
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                            color: scheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.family_restroom_rounded, color: scheme.primary),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'حول منصة تواتي',
                            style: TextStyle(
                              fontFamily: 'IBMPlexSansArabic',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
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
                        color: scheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
                      ),
                      child: const Text(
                        'تواتي — لجان الإحسان والشكاوى',
                        style: TextStyle(
                          fontFamily: 'IBMPlexSansArabic',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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

class _LoginHeroCard extends StatelessWidget {
  final VoidCallback onLogin;
  const _LoginHeroCard({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [scheme.primary, scheme.primary.withValues(alpha: 0.78)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.settings_suggest_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'الإعدادات العامة للتطبيق',
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'خصّص مظهر التطبيق واطّلع على معلومات المنصة ومستندات الخصوصية. سجّل الدخول للوصول إلى حسابك وخدمات الأعضاء.',
            style: TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 12.5,
              height: 1.7,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: scheme.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.login_rounded, size: 20),
              label: const Text('تسجيل الدخول للمنصة'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardTheme.color : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 12,
          height: 1.4,
          color: scheme.onSurface.withValues(alpha: 0.65),
        ),
      ),
      trailing: Icon(Icons.chevron_left_rounded, color: scheme.onSurface.withValues(alpha: 0.4)),
    );
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? scheme.primary : Colors.grey.withValues(alpha: 0.25),
              width: selected ? 1.5 : 1,
            ),
            color: selected ? scheme.primary.withValues(alpha: 0.08) : null,
          ),
          child: Row(
            children: [
              Icon(ThemeModeStorage.icon(mode), color: selected ? scheme.primary : null),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ThemeModeStorage.label(mode),
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: scheme.primary, size: 20),
            ],
          ),
        ),
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
      style: TextStyle(
        fontFamily: 'IBMPlexSansArabic',
        fontSize: 13.5,
        height: 1.8,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
      ),
    );
  }
}
