import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:flutter_stripe/flutter_stripe.dart' hide PaymentMethod;
import 'package:image_picker/image_picker.dart';

import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/core/providers.dart';
import 'package:tawati_mobile/src/core/widgets/skeleton.dart';
import 'package:tawati_mobile/src/core/media_url.dart';
import 'package:tawati_mobile/src/features/donations/models/donation.dart';

const _kPrimary = Color(0xFF044465);
const _kMuted = Color(0xFF9CAFB8);
const _kParagraph = Color(0xFF62707B);
const _kDark = Color(0xFF1A242B);
const _kSurface = Color(0xFFF1F5F8);
const _kBorder = Color(0xFFF1F5F8);
const _kCardBorder = Color(0x1A9CAFB8);

class CampaignDetailScreen extends ConsumerStatefulWidget {
  final String campaignId;

  const CampaignDetailScreen({super.key, required this.campaignId});

  @override
  ConsumerState<CampaignDetailScreen> createState() =>
      _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends ConsumerState<CampaignDetailScreen> {
  Campaign? _campaign;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
    _connectCampaignSocket();
  }

  @override
  void dispose() {
    final socketService = ref.read(socketServiceProvider);
    socketService.offEvent('campaign:update');
    socketService.leaveCampaign(widget.campaignId);
    super.dispose();
  }

  void _connectCampaignSocket() async {
    final socketService = ref.read(socketServiceProvider);
    socketService.offEvent('campaign:update');
    await socketService.connect();
    socketService.onCampaignUpdate((data) {
      if (!mounted) return;
      final current = _campaign;
      if (current == null) return;
      final collected = data['collected_amount'];
      final target = data['target_amount'];
      setState(() {
        _campaign = current.copyWith(
          collectedAmount: collected is num ? collected.toDouble() : null,
          targetAmount: target is num ? target.toDouble() : null,
        );
      });
    });
    socketService.joinCampaign(widget.campaignId);
  }

  Future<void> _loadDetail() async {
    try {
      final campaign = await ref
          .read(donationServiceProvider)
          .getCampaignDetail(widget.campaignId);
      if (mounted) {
        setState(() {
          _campaign = campaign;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _loading
            ? _buildLoading()
            : _error != null
                ? _buildError()
                : _buildContent(),
        bottomNavigationBar: _campaign != null && _campaign!.isActive
            ? _buildBottomCta()
            : null,
      ),
    );
  }

  Widget _buildHeaderBar() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        color: Colors.transparent,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Transform.rotate(
                angle: math.pi,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0x66000000),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_rounded, size: 16, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _campaign?.title ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (_campaign?.fundName != null)
                    Text(
                      _campaign!.fundName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 12,
                        color: Colors.white70,
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

  Widget _buildError() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: _kMuted),
            const SizedBox(height: 12),
            const Text(
              'حدث خطأ، يرجى المحاولة مرة أخرى',
              style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: _kParagraph),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _loadDetail,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          skeletonBox(height: 240, borderRadius: 0, margin: EdgeInsets.zero),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Transform.translate(
              offset: const Offset(0, -56),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    skeletonLine(width: 180, height: 18, margin: EdgeInsets.zero),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              skeletonLine(width: 60, height: 12, margin: EdgeInsets.zero),
                              const SizedBox(height: 8),
                              skeletonLine(width: 120, height: 22, margin: EdgeInsets.zero),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              skeletonLine(width: 80, height: 12, margin: EdgeInsets.zero),
                              const SizedBox(height: 8),
                              skeletonLine(width: 120, height: 20, margin: EdgeInsets.zero),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    skeletonLine(height: 12, borderRadius: 6, margin: EdgeInsets.zero),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        skeletonCircle(size: 36),
                        const SizedBox(width: 10),
                        Expanded(child: skeletonLine(height: 12, margin: EdgeInsets.zero)),
                        const SizedBox(width: 16),
                        skeletonCircle(size: 36),
                        const SizedBox(width: 10),
                        Expanded(child: skeletonLine(height: 12, margin: EdgeInsets.zero)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final campaign = _campaign!;
    final fmt = NumberFormat('#,##0');
    final percent = (campaign.progress * 100).toInt();

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(campaign),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Transform.translate(
                        offset: const Offset(0, -56),
                        child: _buildProgressCard(campaign, fmt, percent),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: _buildAboutSection(campaign, fmt),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                      child: _buildRecentDonors(campaign),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildHeaderBar(),
              ),
            ],
          ),
        ),
        if (_campaign != null && _campaign!.isActive)
          _buildBottomCta(),
      ],
    );
  }

  Widget _buildHero(Campaign campaign) {
    final hasImage = campaign.image != null && campaign.image!.isNotEmpty;

    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.network(
              resolveMediaUrl(campaign.image),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _heroFallback(),
            ),
          if (!hasImage) _heroFallback(),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x33000000), Color(0x00000000)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [_kPrimary, Color(0xFF02304A)],
        ),
      ),
    );
  }

  Widget _buildProgressCard(Campaign campaign, NumberFormat fmt, int percent) {
    final progress = campaign.progress;
    final remaining = campaign.targetAmount - campaign.collectedAmount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF044465).withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('المبلغ المستهدف', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: _kMuted)),
                    const SizedBox(height: 2),
                    Text(
                      '${fmt.format(campaign.targetAmount)} ج.س',
                      style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('تم جمع', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: _kMuted)),
                    const SizedBox(height: 2),
                    Text(
                      '${fmt.format(campaign.collectedAmount)} ج.س',
                      style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: _kSurface,
              valueColor: const AlwaysStoppedAnimation(_kPrimary),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'متبقي ${fmt.format(remaining < 0 ? 0 : remaining)} ج.س',
                style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: _kMuted),
              ),
              const Spacer(),
              Text(
                '$percent% اكتمل',
                style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: _kPrimary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: _kBorder),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatItem(Icons.groups_outlined, 'عدد المتبرعين', _toArabicDigits(campaign.donorCount ?? 0)),
              const Spacer(),
              _buildStatItem(Icons.schedule_outlined, 'الأيام المتبقية', _daysLeftLabel(campaign)),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(color: _kSurface, shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: _kPrimary),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, color: _kMuted)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w700, color: _kDark)),
          ],
        ),
      ],
    );
  }

  Widget _buildAboutSection(Campaign campaign, NumberFormat fmt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 24,
              decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(999)),
            ),
            const SizedBox(width: 8),
            const Text('حول الحملة', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, color: _kPrimary)),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          campaign.description ?? 'لا يوجد وصف',
          style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: _kParagraph, height: 1.8),
        ),
        const SizedBox(height: 20),
        const Divider(height: 1, color: _kBorder),
        const SizedBox(height: 16),
        const Text('مبالغ سريعة', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: _kMuted)),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final amount in const [10000, 20000, 50000, 100000])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => _showDonateDialog(initialAmount: amount.toDouble()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _kSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(fmt.format(amount), style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
                          const SizedBox(height: 2),
                          const Text('ج.س', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 9, color: _kMuted)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentDonors(Campaign campaign) {
    final donations = campaign.latestDonations;
    final fmt = NumberFormat('#,##0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 24,
              decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(999)),
            ),
            const SizedBox(width: 8),
            const Text('آخر المساهمات', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, color: _kPrimary)),
            const Spacer(),
            GestureDetector(
              onTap: () => _showComingSoon(),
              child: const Text('عرض الكل', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: _kMuted)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (donations.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder),
            ),
            child: Column(
              children: [
                const Icon(Icons.handshake_outlined, size: 40, color: _kMuted),
                const SizedBox(height: 8),
                const Text('لا توجد مساهمات بعد، كن أول المتبرعين', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: _kParagraph)),
              ],
            ),
          )
        else
          ...donations.asMap().entries.map(
                (e) => _buildDonorItem(e.key, e.value, fmt),
              ),
      ],
    );
  }

  Widget _buildDonorItem(int index, RecentDonation donation, NumberFormat fmt) {
    final isFirst = index == 0;
    final name = donation.isAnonymous ? 'فاعل خير' : donation.userName;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isFirst ? _kSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isFirst ? _kCardBorder : _kBorder),
      ),
      child: Row(
        children: [
          Text(
            '${fmt.format(donation.amount)} ج.س',
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(name, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: _kDark)),
              const SizedBox(height: 2),
              Text(_timeAgo(donation.createdAt), style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 10, color: _kMuted)),
            ],
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kSurface,
              shape: BoxShape.circle,
              border: Border.all(color: isFirst ? Colors.white : _kSurface, width: 2),
            ),
            child: Icon(Icons.person, size: 20, color: _kPrimary),
          ),
        ],
      ),
    );
  }

  String _daysLeftLabel(Campaign campaign) {
    final end = campaign.endDate;
    if (!campaign.isActive || end == null) return 'منتهية';
    final days = end.difference(DateTime.now()).inDays;
    if (days < 0) return 'منتهية';
    if (days == 0) return 'آخر يوم';
    if (days == 1) return 'يوم واحد';
    return '${_toArabicDigits(days)} يوم';
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${_toArabicDigits(diff.inMinutes)} دقيقة';
    if (diff.inHours < 24) return 'منذ ${_toArabicDigits(diff.inHours)} ساعة';
    if (diff.inDays < 7) return 'منذ ${_toArabicDigits(diff.inDays)} يوم';
    return 'منذ ${_toArabicDigits((diff.inDays / 30).floor())} شهر';
  }

  String _toArabicDigits(num value) {
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return value.toString().split('').map((c) {
      final index = int.tryParse(c);
      return index == null ? c : arabic[index];
    }).join();
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('قريباً', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildBottomCta() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _showDonateDialog(),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kPrimary, width: 1.5),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 18, color: _kPrimary),
                      SizedBox(width: 8),
                      Text(
                        'تبرع الآن',
                        style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => _showComingSoon(),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x339CAFB8)),
                ),
                child: const Icon(Icons.share_outlined, size: 20, color: _kMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDonateDialog({double? initialAmount}) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x4D000000),
      sheetAnimationStyle: AnimationStyle(
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutCubic,
      ),
      builder: (context) => DonationBottomSheet(
        campaign: _campaign!,
        initialAmount: initialAmount,
      ),
    );
    if (mounted) _loadDetail();
    if (result != null && mounted) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: const Color(0x4D000000),
        sheetAnimationStyle: AnimationStyle(
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeOutCubic,
        ),
        builder: (context) => DonationResultSheet(
          resultType: result['type'] as String,
          amount: result['amount'] as double,
          anonymous: result['anonymous'] as bool? ?? false,
        ),
      );
    }
  }
}

class DonationResultSheet extends StatelessWidget {
  final String resultType;
  final double amount;
  final bool anonymous;

  const DonationResultSheet({
    super.key,
    required this.resultType,
    required this.amount,
    this.anonymous = false,
  });

  @override
  Widget build(BuildContext context) {
    final isReview = resultType == 'review';
    final fmt = NumberFormat('#,##0');
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: (isReview ? AppColors.warning : AppColors.success).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isReview ? Icons.schedule : Icons.check_circle_outline,
                      size: 38,
                      color: isReview ? AppColors.warning : AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isReview ? 'عملية التبرع قيد المراجعة' : 'تم تأكيد تبرعك بنجاح',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${fmt.format(amount)} ج.س',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isReview
                        ? 'تم استلام طلبك بنجاح، وسيقوم فريق الإدارة بمراجعته وتأكيده خلال وقت قصير. ستصلك إشعارات فور تأكيد التبرع.'
                        : (anonymous
                            ? 'شكراً لك على مساهمتك، ستظهر مساهمتك باسم فاعل خير في سجل المساهمات.'
                            : 'شكراً لك على مساهمتك، سيظهر اسمك في سجل المساهمات.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: AppColors.textSecondary, height: 1.7),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('تم'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DonationBottomSheet extends ConsumerStatefulWidget {
  final Campaign campaign;
  final double? initialAmount;

  const DonationBottomSheet({
    super.key,
    required this.campaign,
    this.initialAmount,
  });

  @override
  ConsumerState<DonationBottomSheet> createState() =>
      _DonationBottomSheetState();
}

class _DonationBottomSheetState extends ConsumerState<DonationBottomSheet> {
  final _amountController = TextEditingController();
  final _transactionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  PaymentMethod? _selectedMethod;
  bool _anonymous = false;
  bool _submitting = false;
  String? _receiptPath;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final methods = widget.campaign.paymentMethods;
    PaymentMethod? firstManual;
    for (final method in methods) {
      if (method.type == 'manual') {
        firstManual = method;
        break;
      }
    }
    _selectedMethod = firstManual ?? (methods.isEmpty ? null : methods.first);
    final initial = widget.initialAmount;
    if (initial != null && initial > 0) {
      _amountController.text = initial.toString();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transactionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final method = _selectedMethod;
    if (method == null) {
      setState(() => _errorMessage = 'لا توجد طرق دفع متاحة لهذه الحملة');
      return;
    }

    if (method.type == 'manual' && method.requiresReceipt && _receiptPath == null) {
      setState(() => _errorMessage = 'يرجى إرفاق إشعار الدفع لإتمام التبرع');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final amount = double.parse(_amountController.text);

      if (method.type == 'manual') {
        String? referenceNumber;
        String? receiptImage;
        final txNumber = _transactionController.text.trim();
        if (method.requiresTransactionNumber && txNumber.isNotEmpty) {
          referenceNumber = txNumber;
        }
        if (method.requiresReceipt) {
          receiptImage = await ref
              .read(donationServiceProvider)
              .uploadReceipt(filePath: _receiptPath!);
        }
        await ref.read(donationServiceProvider).createManualDonation(
              campaignId: widget.campaign.id,
              amount: amount,
              paymentMethodId: method.id,
              referenceNumber: referenceNumber,
              receiptImage: receiptImage,
              isAnonymous: _anonymous,
            );
        if (mounted) {
          Navigator.of(context).pop({
            'type': 'review',
            'amount': amount,
            'anonymous': _anonymous,
          });
        }
      } else {
        await _handleStripePayment(amount);
      }
    } catch (e) {
      if (mounted) {
        String message = 'فشل التبرع';
        try {
          if (e is Exception) {
            final dioErr = e as dynamic;
            if (dioErr.response?.data?['message'] != null) {
              message = dioErr.response!.data['message'] as String;
            }
          }
        } catch (_) {}
        setState(() {
          _submitting = false;
          _errorMessage = message;
        });
      }
    }
  }

  Future<void> _handleStripePayment(double amount) async {
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.post('/payments/stripe/create-intent', data: {
      'campaign_id': widget.campaign.id,
      'amount': amount,
      'is_anonymous': _anonymous,
    });
    final clientSecret = response.data['data']['clientSecret'] as String;

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Tawati',
        returnURL: 'stripe_return://tawati',
      ),
    );

    await Stripe.instance.presentPaymentSheet();
    await Stripe.instance.confirmPaymentSheetPayment();

    if (mounted) {
      Navigator.of(context).pop({
        'type': 'success',
        'amount': amount,
        'anonymous': _anonymous,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: AppColors.textHint, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('تبرع الآن', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(widget.campaign.title, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'المبلغ (جنيه سوداني)',
                      prefixIcon: Icon(Icons.monetization_on_outlined),
                    ),
                    style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'يرجى إدخال المبلغ';
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) return 'يرجى إدخال مبلغ صحيح';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('طريقة الدفع', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  _PaymentMethodPicker(
                    methods: widget.campaign.paymentMethods,
                    selected: _selectedMethod,
                    onChanged: (method) => setState(() => _selectedMethod = method),
                  ),
                  const SizedBox(height: 12),
                  _buildMethodInfoBox(),
                  if (_selectedMethod?.type == 'manual' &&
                      _selectedMethod!.requiresTransactionNumber) ...[
                    const SizedBox(height: 12),
                    _buildTransactionField(),
                  ],
                  if (_selectedMethod?.type == 'manual' &&
                      _selectedMethod!.requiresReceipt) ...[
                    const SizedBox(height: 12),
                    _buildReceiptPicker(),
                  ],
                  const SizedBox(height: 16),
                  _buildAnonymousToggle(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: Color(0xFFEF4444)),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _errorMessage = null),
                            child: const Icon(Icons.close, size: 16, color: Color(0xFFEF4444)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('تأكيد التبرع'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodInfoBox() {
    final method = _selectedMethod;
    if (method == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'لا توجد طرق دفع متاحة لهذه الحملة حالياً',
          style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: AppColors.warning),
        ),
      );
    }
    final isManual = method.type == 'manual';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isManual ? Icons.account_balance_outlined : Icons.bolt_outlined,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.displayNameAr,
                  style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                if (isManual && method.accountHolderName.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'اسم صاحب الحساب: ${method.accountHolderName}',
                    style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: AppColors.textPrimary),
                  ),
                ],
                if (isManual && method.accountNumber.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'رقم الحساب: ${method.accountNumber}',
                    style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                    textDirection: TextDirection.ltr,
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  isManual
                      ? 'قم بالتحويل عبر هذه الطريقة وسيتم مراجعة التبرع وتأكيده من قبل الإدارة خلال وقت قصير.'
                      : 'سيتم توجيهك لصفحة الدفع الآمن، ويتم تأكيد التبرع فوراً.',
                  style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionField() {
    return TextFormField(
      controller: _transactionController,
      keyboardType: TextInputType.text,
      decoration: const InputDecoration(
        labelText: 'رقم العملية',
        hintText: 'أدخل رقم العملية الخاص بالتحويل',
        prefixIcon: Icon(Icons.numbers),
      ),
      style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'يرجى إدخال رقم العملية';
        return null;
      },
    );
  }

  Widget _buildReceiptPicker() {
    final path = _receiptPath;
    return GestureDetector(
      onTap: _pickReceipt,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: path == null ? AppColors.primary : AppColors.success,
            width: path == null ? 1.5 : 1,
          ),
        ),
        child: path == null
            ? Row(
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 22, color: AppColors.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('إرفاق إشعار الدفع', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        SizedBox(height: 2),
                        Text('اضغط لاختيار صورة إشعار الدفع', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const Icon(Icons.add_photo_alternate_outlined, color: AppColors.textHint),
                ],
              )
            : Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(path),
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تم إرفاق إشعار الدفع', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success)),
                        SizedBox(height: 2),
                        Text('اضغط لتغيير الصورة', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _receiptPath = null),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.close, size: 18, color: AppColors.textHint),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _pickReceipt() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    setState(() => _receiptPath = file.path);
  }

  Widget _buildAnonymousToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_off_outlined, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('إخفاء اسمي', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text('سيظهر اسمك في سجل المساهمات باسم فاعل خير', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: _anonymous,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
            onChanged: (value) => setState(() => _anonymous = value),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodPicker extends StatelessWidget {
  final List<PaymentMethod> methods;
  final PaymentMethod? selected;
  final ValueChanged<PaymentMethod> onChanged;

  const _PaymentMethodPicker({
    required this.methods,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final current = selected;
    return GestureDetector(
      onTap: () => _openPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(_iconFor(current), size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                current?.displayNameAr ?? 'اختر طريقة الدفع',
                style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(PaymentMethod? method) {
    if (method == null) return Icons.help_outline;
    return method.type == 'manual'
        ? Icons.account_balance_outlined
        : Icons.credit_card_outlined;
  }

  void _openPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x4D000000),
      sheetAnimationStyle: AnimationStyle(
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutCubic,
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Text(
                  'اختر طريقة الدفع',
                  style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
              ...methods.map((method) {
                final isSelected = method.id == selected?.id;
                return InkWell(
                  onTap: () {
                    onChanged(method);
                    Navigator.of(sheetContext).pop();
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryLight.withValues(alpha: 0.6) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 1.5 : 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _iconFor(method),
                            size: 20,
                            color: isSelected ? Colors.white : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                method.displayNameAr,
                                style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                method.type == 'manual'
                                    ? 'تحويل يدوي يُراجع من الإدارة'
                                    : 'دفع إلكتروني فوري',
                                style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                        else
                          Icon(Icons.circle_outlined, color: AppColors.textHint, size: 20),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
          ),
        );
      },
    );
  }
}
