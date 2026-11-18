import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tawati_mobile/src/core/legal.dart';
import 'package:tawati_mobile/src/core/providers.dart';
import 'package:tawati_mobile/src/features/auth/providers/auth_provider.dart';

class AccountDeletionScreen extends ConsumerStatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  ConsumerState<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends ConsumerState<AccountDeletionScreen> {
  bool _confirmed = false;
  bool _submitting = false;

  Future<void> _submitRequest() async {
    if (!_confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تأكيد رغبتك في حذف الحساب أولاً', style: TextStyle(fontFamily: 'IBMPlexSansArabic'))),
      );
      return;
    }
    final user = ref.read(authProvider).user;
    final name = user?.fullNameAr ?? '';
    final phone = user?.phone ?? '';
    final userId = user?.id ?? '';

    setState(() => _submitting = true);
    try {
      await ref.read(apiClientProvider).post('/auth/account-deletion-request', data: {
        'confirm': true,
        'reason': 'user_requested_in_app',
      });
      if (!mounted) return;
      setState(() => _submitting = false);
      await showDialog<void>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تم استلام طلب الحذف', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w600)),
            content: const Text(
              'تم تسجيل طلب حذف حسابك وسيتم مراجعته والتحقق من الهوية وتنفيذه وفق سياسة الخصوصية والأنظمة المعمول بها. قد نحتفظ ببعض السجلات المالية أو النظامية للمدة المطلوبة.',
              style: TextStyle(fontFamily: 'IBMPlexSansArabic', height: 1.6),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('حسنًا', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
              ),
            ],
          ),
        ),
      );
      return;
    } catch (_) {
      // Fallback to email-based request if API is unavailable (e.g. older backend/not deployed).
    }

    final uri = Uri(
      scheme: 'mailto',
      path: LegalLinks.supportEmail,
      queryParameters: {
        'subject': LegalLinks.deleteAccountSubject,
        'body': LegalLinks.deleteAccountBody(name: name, phone: phone, userId: userId),
      },
    );
    final ok = await launchUrl(uri);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      showDialog<void>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تم إعداد طلب الحذف', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w600)),
            content: const Text(
              'تم فتح تطبيق البريد لإرسال طلب حذف الحساب. سيقوم فريق الدعم بمراجعة الطلب والتحقق من الهوية وتنفيذه وفق سياسة الخصوصية والأنظمة المعمول بها. قد نحتفظ ببعض السجلات المالية أو النظامية للمدة المطلوبة.',
              style: TextStyle(fontFamily: 'IBMPlexSansArabic', height: 1.6),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('حسنًا', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر إرسال الطلب الآن. يمكنك مراسلتنا مباشرة على ${LegalLinks.supportEmail} لطلب حذف الحساب.',
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
          ),
        ),
      );
    }
  }

  Future<void> _openWebPolicy() async {
    final uri = Uri.parse(LegalLinks.accountDeletionUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFB91C1C),
          foregroundColor: Colors.white,
          title: const Text('حذف الحساب', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w600)),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFB91C1C)),
                      SizedBox(width: 8),
                      Text('إجراء مهم ولا يمكن التراجع عنه بسهولة', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w700, color: Color(0xFF7F1D1D))),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'عند حذف حسابك: سيتم إيقاف الوصول إلى حسابك وبياناتك الشخصية داخل التطبيق وفق الإجراءات المعتمدة. قد نحتفظ ببعض السجلات للمدة المطلوبة نظامًا (مثل السجلات المالية/المعاملات) مع تقييد استخدامها للأغراض النظامية والامتثال.',
                    style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: Color(0xFF7F1D1D), height: 1.7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'ما الذي سيحدث؟',
              items: const [
                'التحقق من هوية صاحب الحساب قبل تنفيذ الطلب.',
                'حذف أو إخفاء الهوية لبيانات الحساب غير المطلوبة نظامًا.',
                'الاحتفاظ بالسجلات المالية/النظامية الضرورية للمدة المطلوبة عند الحاجة.',
                'إشعارك بنتيجة الطلب عبر وسيلة التواصل المتاحة.',
              ],
            ),
            const SizedBox(height: 12),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: _openWebPolicy,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: const Row(
                    children: [
                      Icon(Icons.open_in_new_rounded, color: Color(0xFF0D9488)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('سياسة حذف الحساب (ويب)', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                            SizedBox(height: 2),
                            Text(LegalLinks.accountDeletionUrl, style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: CheckboxListTile(
                value: _confirmed,
                onChanged: (v) => setState(() => _confirmed = v ?? false),
                activeColor: const Color(0xFFB91C1C),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'أؤكد أنني أريد تقديم طلب حذف حسابي وأفهم أن بعض السجلات قد تُحتفظ بها للمدة المطلوبة نظامًا.',
                  style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: Color(0xFF0F172A), height: 1.6),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submitRequest,
                icon: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.delete_forever_outlined),
                label: const Text('إرسال طلب حذف الحساب', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB91C1C),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFFCA5A5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('إلغاء والعودة', style: TextStyle(fontFamily: 'IBMPlexSansArabic', color: Color(0xFF64748B))),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<String> items;
  const _InfoCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
          const SizedBox(height: 10),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 6, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: Color(0xFF334155), height: 1.6))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
