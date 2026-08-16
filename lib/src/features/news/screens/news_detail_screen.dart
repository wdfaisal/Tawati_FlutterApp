import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:go_router/go_router.dart';

import 'package:tawati_mobile/src/core/media_url.dart';

const _kBlue800 = Color(0xFF1E40AF);
const _kSlate900 = Color(0xFF0F172A);
const _kSlate800 = Color(0xFF1E293B);
const _kSlate700 = Color(0xFF334155);
const _kSlate600 = Color(0xFF475569);
const _kSlate500 = Color(0xFF64748B);
const _kSlate400 = Color(0xFF94A3B8);
const _kSlate300 = Color(0xFFCBD5E1);
const _kSlate100 = Color(0xFFF1F5F9);
const _kSlate50 = Color(0xFFF8FAFC);
const _kBlue50 = Color(0xFFEFF6FF);
const _kEmerald50 = Color(0xFFECFDF5);
const _kEmerald = Color(0xFF059669);

class NewsDetailScreen extends ConsumerWidget {
  final Map<String, dynamic>? newsItem;

  const NewsDetailScreen({super.key, this.newsItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = newsItem ?? _getDummyItem();

    final type = item['type'] as String? ?? '';
    final subType = item['sub_type'] as String? ?? '';
    final isDeath = subType == 'death' || type == 'obituary';

    final label = _labelFor(type, subType);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kSlate50,
        appBar: _buildAppBar(context, isDeath ? 'تفاصيل العزاء' : 'تفاصيل الإعلان'),
        bottomNavigationBar: isDeath ? _buildObituaryFooter(context) : _buildAnnouncementFooter(context),
        body: SingleChildScrollView(
          child: isDeath
              ? _buildObituary(context, item, label)
              : _buildAnnouncement(item, label),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, String title) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: _kSlate900,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 18),
        onPressed: () => context.pop(),
      ),
      title: Text(
        title,
        style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 18, fontWeight: FontWeight.w600, color: _kSlate900),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: GestureDetector(
            onTap: () => _showComingSoon(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kSlate50,
                shape: BoxShape.circle,
                border: Border.all(color: _kSlate100),
              ),
              child: const Icon(Icons.share_outlined, size: 18, color: _kSlate800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementFooter(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _kSlate100)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () => _showComingSoon(context),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: _kBlue800,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E40AF).withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_outlined, size: 18, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'تواصل معنا',
                          style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () => _showComingSoon(context),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: _kSlate100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.share_outlined, size: 17, color: _kSlate800),
                        SizedBox(width: 6),
                        Text(
                          'مشاركة',
                          style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, color: _kSlate700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildObituaryFooter(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _kSlate100)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _showComingSoon(context),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _kSlate100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.share_outlined, size: 20, color: _kSlate800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showComingSoon(context),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: _kBlue800,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E40AF).withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.volunteer_activism_outlined, size: 20, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'تقديم التعازي',
                          style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncement(Map<String, dynamic> item, String label) {
    final title = item['title'] as String? ?? '';
    final subtitle = item['subtitle'] as String? ?? item['description'] as String? ?? '';
    final body = item['body'] as String? ?? item['content'] as String? ?? '';
    final imageUrl = resolveMediaUrl(item['image'] as String?);
    final createdBy = item['created_by'];
    final publisher = createdBy is Map ? (createdBy['full_name'] as String? ?? '') : '';
    final dateText = _dateText((item['published_at'] as String?) ?? (item['created_at'] as String?));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 256,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl.isNotEmpty)
                Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink()),
              if (imageUrl.isEmpty)
                Container(color: _kBlue50),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
                    ],
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: _kSlate400),
              const SizedBox(width: 6),
              Text(
                dateText,
                style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: _kSlate400),
              ),
              const Spacer(),
              if (publisher.isNotEmpty) ...[
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: _kSlate400),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          publisher,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: _kSlate400),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            title,
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 22, fontWeight: FontWeight.w700, color: _kSlate900, height: 1.4),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Divider(height: 1, color: _kSlate100),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            body.isNotEmpty ? body : 'لا يوجد محتوى لهذا الإعلان بعد.',
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15, color: _kSlate600, height: 1.8),
          ),
        ),
        if (subtitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: _kBlue50,
                borderRadius: BorderRadius.circular(10),
                border: const Border(right: BorderSide(color: _kBlue800, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ملاحظة هامة:',
                    style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15, color: _kBlue800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: _kSlate700, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildObituary(BuildContext context, Map<String, dynamic> item, String label) {
    final title = item['title'] as String? ?? '';
    final subtitle = item['subtitle'] as String? ?? item['description'] as String? ?? '';
    final body = item['body'] as String? ?? item['content'] as String? ?? '';
    final imageUrl = resolveMediaUrl(item['image'] as String?);
    final dateText = _fullArabicDate(item['created_at'] as String?);
    final condolence = body.isNotEmpty ? body : subtitle.isNotEmpty ? subtitle : 'بقلوب مؤمنة بقضاء الله وقدره، ننعى فقيدنا الغالي الذي انتقل إلى جوار ربه. اللهم اغفر له وارحمه وأسكنه فسيح جناتك.';
    final hashtags = _deriveHashtags(title);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 288,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl.isNotEmpty)
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(color: _kSlate300),
                ),
              if (imageUrl.isEmpty)
                Container(color: _kSlate300),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: _kSlate100),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'إنا لله وإنا إليه راجعون',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 14,
                      color: _kSlate500.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 22, fontWeight: FontWeight.w700, color: _kSlate900, height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    condolence,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: _kSlate600, height: 1.7),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoRow(
                    icon: Icons.event_outlined,
                    iconBg: _kBlue50,
                    iconColor: _kBlue800,
                    label: 'موعد العزاء',
                    value: dateText,
                    subLine: subtitle.isNotEmpty ? subtitle : null,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildInfoRow(
                      icon: Icons.location_on_outlined,
                      iconBg: _kEmerald50,
                      iconColor: _kEmerald,
                      label: 'مكان العزاء',
                      value: subtitle,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: () => _showComingSoon(context),
            child: Container(
              height: 128,
              decoration: BoxDecoration(
                color: _kSlate300,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _kSlate100),
                image: imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                        onError: (_, _) {},
                      )
                    : null,
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.white),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map_outlined, size: 18, color: _kBlue800),
                      SizedBox(width: 8),
                      Text(
                        'فتح الموقع في الخريطة',
                        style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: _kSlate800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Column(
            children: [
              _buildFundCard(
                context,
                title: 'صندوق الكشف (مباشر)',
                description: 'مساهمة مالية مباشرة مقدمة لعائلة الفقيد تعبيراً عن التكاتف والمواساة.',
                icon: Icons.volunteer_activism_outlined,
                isGradient: false,
              ),
              const SizedBox(height: 16),
              _buildFundCard(
                context,
                title: 'صندوق الوفيات العام',
                description: 'ادعم استدامة خدمات العزاء والوفيات للمجتمع من خلال تبرعك العام.',
                icon: Icons.people_alt_outlined,
                isGradient: true,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in hashtags)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _kSlate100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: _kSlate500),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    String? subLine,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: 22, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: _kSlate400),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.w600, color: _kSlate800),
              ),
              if (subLine != null && subLine.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subLine,
                  style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: _kSlate500),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFundCard(BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required bool isGradient,
  }) {
    final bool isKeshf = !isGradient;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isGradient ? null : Colors.white,
        gradient: isGradient
            ? const LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
              )
            : null,
        borderRadius: BorderRadius.circular(16),
        border: isGradient ? null : Border.all(color: _kSlate200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isGradient ? Colors.white : _kSlate900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isGradient ? Colors.white.withValues(alpha: 0.15) : _kBlue50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: isGradient ? Colors.white : _kBlue800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 14,
              height: 1.6,
              color: isGradient ? Colors.white.withValues(alpha: 0.9) : _kSlate500,
            ),
          ),
          if (isKeshf) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _buildAmountChip('٥٠٠ ريال', selected: false),
                const SizedBox(width: 8),
                _buildAmountChip('٢٠٠ ريال', selected: true),
                const SizedBox(width: 8),
                _buildAmountChip('١٠٠ ريال', selected: false),
              ],
            ),
            const SizedBox(height: 16),
          ] else
            const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showComingSoon(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isGradient ? Colors.white : _kSlate800,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 18,
                    color: isGradient ? _kBlue800 : Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isGradient ? 'التبرع للصندوق العام' : 'تقديم المساهمة',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 14,
                      color: isGradient ? _kBlue800 : Colors.white,
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

  Widget _buildAmountChip(String text, {required bool selected}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kBlue50 : _kSlate50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _kBlue800 : _kSlate100,
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontSize: 10,
            color: selected ? _kBlue800 : _kSlate400,
          ),
        ),
      ),
    );
  }

  List<String> _deriveHashtags(String title) {
    const stopwords = {'بن', 'آل', 'من', 'في', 'عن', 'على', 'إلى', 'بإذن'};
    final result = <String>[];
    for (final raw in title.split(RegExp(r'\s+'))) {
      final word = raw.replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
      if (word.length < 3 || stopwords.contains(word)) continue;
      result.add('#$word');
      if (result.length >= 2) break;
    }
    result.add('#تواتي_عزاء');
    return result;
  }

  String _labelFor(String type, String subType) {
    if (subType == 'death') return 'نعي';
    if (subType == 'wedding') return 'عرس';
    if (subType == 'congratulation') return 'تهنئة';
    switch (type) {
      case 'admin_alert':
      case 'general':
        return 'إعلان';
      case 'important':
        return 'إعلان هام';
      case 'platform_announcement':
        return 'إعلان المنصة';
      case 'social_occasion':
        return 'مناسبة';
      default:
        return 'خبر';
    }
  }

  String _dateText(String? raw) {
    final date = DateTime.tryParse(raw ?? '');
    if (date == null) return raw ?? '';
    return _toArabicDigits(
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
    );
  }

  String _fullArabicDate(String? raw) {
    final date = DateTime.tryParse(raw ?? '');
    if (date == null) return raw ?? '';
    const weekdays = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    return '${weekdays[date.weekday - 1]}، ${_toArabicDigits(date.day.toString())} ${months[date.month - 1]} ${_toArabicDigits(date.year.toString())}';
  }

  String _toArabicDigits(String input) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    return input.split('').map((c) {
      final i = c.codeUnitAt(0) - 48;
      return (i >= 0 && i <= 9) ? arabic[i] : c;
    }).join();
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('قريباً', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Map<String, dynamic> _getDummyItem() {
    return {
      'title': 'عنوان الخبر',
      'subtitle': 'عنوان فرعي للخبر',
      'type': 'news',
      'created_at': '2025-01-01',
      'body': '',
    };
  }
}

const _kSlate200 = Color(0xFFE2E8F0);
