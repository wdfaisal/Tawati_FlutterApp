import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tawati_mobile/src/core/legal.dart';

enum LegalDocumentType { privacy, terms }

const _kPrimary = Color(0xFF044465);
const _kMuted = Color(0xFF9CAFB8);
const _kSecondary = Color(0xFF62707B);
const _kSurface = Color(0xFFF1F5F8);
const _kDark = Color(0xFF1A242B);
const _kBorder = Color(0xFFE5EBF0);

class LegalDocumentScreen extends StatelessWidget {
  final LegalDocumentType type;

  const LegalDocumentScreen({super.key, required this.type});

  bool get _isPrivacy => type == LegalDocumentType.privacy;
  String get _title => _isPrivacy ? 'سياسة الخصوصية' : 'الشروط والأحكام';
  String get _subtitle => _isPrivacy
      ? 'كيف نتعامل مع بياناتك ونحمي خصوصيتك'
      : 'القواعد والشروط المنظمة لاستخدام التطبيق';
  String get _url =>
      _isPrivacy ? LegalLinks.privacyPolicyUrl : LegalLinks.termsUrl;
  IconData get _headerIcon =>
      _isPrivacy ? Icons.privacy_tip_outlined : Icons.gavel_outlined;

  @override
  Widget build(BuildContext context) {
    final sections = _isPrivacy ? _privacySections : _termsSections;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _buildHeader(context),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  children: [
                    _HeroCard(
                      icon: _headerIcon,
                      title: _title,
                      text: _isPrivacy
                          ? 'توضح هذه الصفحة ملخصًا لكيفية تعامل تطبيق تواتي مع بياناتك. للاطلاع على النسخة المنشورة والمعتمدة، استخدم الرابط أدناه.'
                          : 'توضح هذه الصفحة ملخصًا لشروط استخدام تطبيق تواتي. للاطلاع على النسخة المنشورة والمعتمدة، استخدم الرابط أدناه.',
                    ),
                    const SizedBox(height: 20),
                    for (var i = 0; i < sections.length; i++) ...[
                      _SectionCard(
                        index: i + 1,
                        title: sections[i].title,
                        body: sections[i].body,
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 8),
                    _ActionCard(
                      icon: Icons.open_in_new_rounded,
                      title: 'فتح النسخة الكاملة على الويب',
                      subtitle: _url,
                      onTap: () => _openUrl(context, _url),
                    ),
                    const SizedBox(height: 10),
                    _ActionCard(
                      icon: Icons.mail_outline_rounded,
                      title: 'التواصل بخصوص الخصوصية/الشروط',
                      subtitle: LegalLinks.supportEmail,
                      onTap: () => _openMail(
                        context,
                        LegalLinks.supportEmail,
                        LegalLinks.supportSubject,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _kSurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 18, color: _kSecondary),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'ملاحظة: يجب تحديث الروابط والنصوص المعتمدة نهائيًا قبل النشر الإنتاجي بما يتوافق مع سياسات المتاجر والأنظمة المعمول بها.',
                              style: TextStyle(
                                fontFamily: 'IBMPlexSansArabic',
                                fontSize: 12,
                                color: _kSecondary,
                                height: 1.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          decoration: const BoxDecoration(
            color: _kSurface,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Directionality(
              textDirection: TextDirection.ltr,
              child: Icon(Icons.arrow_forward_rounded,
                  color: _kDark, size: 22),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _title,
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _kDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _subtitle,
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 12,
                  color: _kSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر فتح الرابط',
              style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
        ),
      );
    }
  }

  Future<void> _openMail(
      BuildContext context, String email, String subject) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': subject},
    );
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر فتح تطبيق البريد',
              style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
        ),
      );
    }
  }

  List<_DocSection> get _privacySections => const [
        _DocSection(
          title: 'البيانات التي نجمعها',
          body:
              'قد نجمع بيانات الحساب والتعريف (مثل الاسم ورقم الهاتف والمعرّفات المرتبطة بالحساب)، وبيانات الاستخدام اللازمة لتشغيل ميزات التطبيق، والمحتوى الذي تقدمه (مثل الصور أو إيصالات التبرع عند الحاجة)، وبيانات تقنية مثل رموز الإشعارات وسجلات الأعطال بما يلزم لتحسين الخدمة.',
        ),
        _DocSection(
          title: 'كيف نستخدم البيانات',
          body:
              'نستخدم البيانات لإنشاء الحساب والتحقق منه، وإدارة العضوية والعائلة، وعرض المحتوى والخدمات (الأخبار، المبادرات، التبرعات)، وإرسال الإشعارات المهمة، وتعزيز الأمان ومنع إساءة الاستخدام، والامتثال للمتطلبات النظامية والمالية عند الاقتضاء.',
        ),
        _DocSection(
          title: 'المشاركة والاحتفاظ',
          body:
              'لا نبيع بياناتك الشخصية. قد نشارك بيانات محدودة مع مزودي خدمات موثوقين لتشغيل التطبيق (مثل الاستضافة، الإشعارات، ومعالجة المدفوعات عند استخدامها) وفق ما تقتضيه الخدمة. نحتفظ بالبيانات للمدة اللازمة للأغراض المذكورة، وقد نحتفظ ببعض السجلات المالية أو النظامية للمدة المطلوبة نظامًا.',
        ),
        _DocSection(
          title: 'حقوقك وحذف الحساب',
          body:
              'يمكنك طلب الوصول إلى بياناتك أو تصحيحها أو حذف حسابك من داخل التطبيق (صفحة حذف الحساب) أو عبر قنوات الدعم. قد يستغرق تنفيذ الطلب وقتًا معقولًا، وقد نحتفظ ببيانات محدودة عندما يكون ذلك مطلوبًا أو مسموحًا به نظامًا (مثل السجلات المالية).',
        ),
        _DocSection(
          title: 'بيانات القُصّر',
          body:
              'قد تتضمن شجرة العائلة بيانات لأفراد قُصّر ضمن سياق عائلي. تتم إدارة هذه البيانات بواسطة ولي الأمر/مسؤولي العائلة وفق صلاحيات النظام، ولا تُنشأ حسابات مستقلة للقُصّر إلا وفق الضوابط المعتمدة.',
        ),
      ];

  List<_DocSection> get _termsSections => const [
        _DocSection(
          title: 'قبول الشروط',
          body:
              'باستخدامك لتطبيق تواتي، فإنك توافق على هذه الشروط وسياسة الخصوصية. إذا لم توافق، يرجى عدم استخدام التطبيق.',
        ),
        _DocSection(
          title: 'الحساب والأهلية',
          body:
              'يخضع إنشاء الحساب والانضمام لإجراءات التحقق والموافقة المعتمدة داخل المنصة. أنت مسؤول عن دقة المعلومات التي تقدمها وعن الحفاظ على سرية بيانات الدخول الخاصة بك.',
        ),
        _DocSection(
          title: 'الاستخدام المقبول',
          body:
              'يلتزم المستخدم بعدم إساءة استخدام التطبيق، وعدم نشر محتوى مخالف أو مضلل، واحترام خصوصية الآخرين. تحتفظ إدارة المنصة بحق اتخاذ إجراءات مناسبة عند المخالفة وفق السياسات المعتمدة.',
        ),
        _DocSection(
          title: 'التبرعات والمدفوعات',
          body:
              'قد يتيح التطبيق المساهمة في حملات/صناديق وفق الوسائل المتاحة. تخضع عمليات الدفع لشروط مزودي الدفع المعتمدين، وقد تتطلب بعض التبرعات اليدوية مراجعة وتأكيدًا. يرجى مراجعة تفاصيل كل حملة قبل المساهمة.',
        ),
        _DocSection(
          title: 'التغييرات والتواصل',
          body:
              'قد نقوم بتحديث هذه الشروط أو سياساتنا من وقت لآخر. سيتم نشر النسخ المعتمدة عبر القنوات الرسمية، ويمكنك التواصل معنا لأي استفسارات عبر بيانات الدعم.',
        ),
      ];
}

class _DocSection {
  final String title;
  final String body;
  const _DocSection({required this.title, required this.body});
}

class _HeroCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _HeroCard(
      {required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF044465), Color(0xFF033A57)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final int index;
  final String title;
  final String body;
  const _SectionCard(
      {required this.index, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 13,
              color: _kSecondary,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _kPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 12,
                        color: _kMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: _kMuted),
            ],
          ),
        ),
      ),
    );
  }
}
