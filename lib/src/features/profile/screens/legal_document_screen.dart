import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tawati_mobile/src/core/legal.dart';

enum LegalDocumentType { privacy, terms }

class LegalDocumentScreen extends StatelessWidget {
  final LegalDocumentType type;

  const LegalDocumentScreen({super.key, required this.type});

  bool get _isPrivacy => type == LegalDocumentType.privacy;

  String get _title => _isPrivacy ? 'سياسة الخصوصية' : 'الشروط والأحكام';
  String get _url => _isPrivacy ? LegalLinks.privacyPolicyUrl : LegalLinks.termsUrl;

  @override
  Widget build(BuildContext context) {
    final sections = _isPrivacy ? _privacySections : _termsSections;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D9488),
          foregroundColor: Colors.white,
          title: Text(
            _title,
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _InfoBanner(
              text: _isPrivacy
                  ? 'توضح هذه الصفحة ملخصًا لكيفية تعامل تطبيق تواتي مع بياناتك. للاطلاع على النسخة المنشورة والمعتمدة، استخدم الرابط أدناه.'
                  : 'توضح هذه الصفحة ملخصًا لشروط استخدام تطبيق تواتي. للاطلاع على النسخة المنشورة والمعتمدة، استخدم الرابط أدناه.',
            ),
            const SizedBox(height: 12),
            for (final section in sections) ...[
              _SectionCard(title: section.title, body: section.body),
              const SizedBox(height: 12),
            ],
            _ActionCard(
              icon: Icons.open_in_new_rounded,
              title: 'فتح النسخة الكاملة على الويب',
              subtitle: _url,
              onTap: () => _openUrl(context, _url),
            ),
            const SizedBox(height: 10),
            _ActionCard(
              icon: Icons.email_outlined,
              title: 'التواصل بخصوص الخصوصية/الشروط',
              subtitle: LegalLinks.supportEmail,
              onTap: () => _openMail(context, LegalLinks.supportEmail, LegalLinks.supportSubject),
            ),
            const SizedBox(height: 16),
            const Text(
              'ملاحظة: يجب تحديث الروابط والنصوص المعتمدة نهائيًا قبل النشر الإنتاجي بما يتوافق مع سياسات المتاجر والأنظمة المعمول بها.',
              style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: Color(0xFF64748B), height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الرابط', style: TextStyle(fontFamily: 'IBMPlexSansArabic'))),
      );
    }
  }

  Future<void> _openMail(BuildContext context, String email, String subject) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': subject},
    );
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح تطبيق البريد', style: TextStyle(fontFamily: 'IBMPlexSansArabic'))),
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

class _InfoBanner extends StatelessWidget {
  final String text;
  const _InfoBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D9488).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF0D9488), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: Color(0xFF0F172A), height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String body;
  const _SectionCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: Color(0xFF334155), height: 1.7),
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
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF0D9488)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}
