import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:tawati_mobile/src/core/guest_mode.dart';
import 'package:tawati_mobile/src/core/media_url.dart';
import 'package:tawati_mobile/src/core/providers.dart';
import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/core/widgets/skeleton.dart';
import 'package:tawati_mobile/src/features/auth/providers/auth_provider.dart';
import 'package:tawati_mobile/src/features/donations/models/donation.dart';
import 'package:tawati_mobile/src/features/notifications/providers/notifications_provider.dart';

const Color _kSoftBg = Color(0xFFF1F5F8);
const Color _kMuted = Color(0xFF9CAFB8);
const Color _kSecondary = Color(0xFF62707B);
const Color _kNameColor = Color(0xFF1A242B);
const Color _kDivider = Color(0xFFF1F5F8);
const Color _kRed = Color(0xFFEF4444);

class DonationsTab extends ConsumerStatefulWidget {
  /// Opens the app drawer. Only available when the tab lives inside the home
  /// shell; on the standalone `/donations` route the header shows a back button
  /// instead.
  final VoidCallback? onOpenDrawer;

  const DonationsTab({super.key, this.onOpenDrawer});

  @override
  ConsumerState<DonationsTab> createState() => _DonationsTabState();
}

class _DonationsTabState extends ConsumerState<DonationsTab> {
  List<Campaign> _campaigns = [];
  List<Fund> _funds = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final service = ref.read(donationServiceProvider);

    List<Campaign>? campaigns;
    List<Fund>? funds;
    Object? loadError;

    try {
      campaigns = await service.getCampaigns();
    } catch (e) {
      loadError = e;
    }

    try {
      funds = await service.getFunds();
    } catch (_) {
      // الصناديق اختيارية للعرض؛ لا نمنع عرض الحملات عند تعذّر جلبها.
      funds = _funds;
    }

    if (!mounted) return;
    setState(() {
      if (campaigns != null) _campaigns = campaigns;
      if (funds != null) _funds = funds;
      _loading = false;
      if (_campaigns.isEmpty && _funds.isEmpty && loadError != null) {
        _error = loadError.toString();
      } else {
        _error = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = ref.watch(authProvider).isVisitor;
    final unreadCount =
        isGuest ? 0 : (ref.watch(notificationsProvider).valueOrNull?.unread ?? 0);
    final canPop = Navigator.of(context).canPop();

    void guard(VoidCallback action) {
      if (isGuest) {
        showGuestLoginPrompt(context);
      } else {
        action();
      }
    }

    final hasData = _campaigns.isNotEmpty || _funds.isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await _loadData();
            if (!isGuest) ref.invalidate(notificationsProvider);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            children: [
              _DonationsHeader(
                onBack: canPop ? () => context.pop() : null,
                onOpenDrawer: canPop ? null : widget.onOpenDrawer,
                onNotifications: () => guard(() => context.push('/notifications')),
                unreadCount: unreadCount,
              ),
              if (_loading)
                const _DonationsSkeleton()
              else if (_error != null)
                _buildError()
              else if (!hasData)
                const _EmptyState()
              else ...[
                const SizedBox(height: 16),
                if (_campaigns.isNotEmpty) _ImpactBanner(campaigns: _campaigns),
                _FundsSection(
                  funds: _funds.where((f) => f.isPermanent).toList(),
                  title: '\u0627\u0644\u0635\u0646\u0627\u062F\u064A\u0642 \u0627\u0644\u062F\u0627\u0626\u0645\u0629',
                  onOpenAll: () => context.push('/funds'),
                ),
                _CampaignsSection(
                  title: '\u062D\u0645\u0644\u0627\u062A \u0627\u0644\u062A\u0628\u0631\u0639',
                  campaigns: _campaigns,
                  emptyMessage: '\u0644\u0627 \u062A\u0648\u062C\u062F \u062D\u0645\u0644\u0627\u062A \u062D\u0627\u0644\u064A\u0627\u064B',
                ),
              ],
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: _kSoftBg, shape: BoxShape.circle),
            child: const Icon(Icons.cloud_off_rounded, size: 28, color: _kMuted),
          ),
          const SizedBox(height: 14),
          Text(
            _error ?? 'حدث خطأ، يرجى المحاولة مرة أخرى',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: _kSecondary, height: 1.6),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonationsHeader extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onNotifications;
  final int unreadCount;

  const _DonationsHeader({
    this.onBack,
    this.onOpenDrawer,
    this.onNotifications,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (onBack != null) ...[
            _CircleButton(icon: Icons.arrow_forward_rounded, onTap: onBack),
            const SizedBox(width: 12),
          ],
          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'التبرعات',
                  textAlign: TextAlign.start,
                  style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
                SizedBox(height: 2),
                Text(
                  'ساهم في دعم الصناديق والمبادرات في مجتمعك',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                  style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, color: _kMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _NotificationsButton(onTap: onNotifications, unreadCount: unreadCount),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CircleButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: _kSoftBg,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _NotificationsButton extends StatelessWidget {
  final VoidCallback? onTap;
  final int unreadCount;

  const _NotificationsButton({this.onTap, this.unreadCount = 0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        children: [
          Positioned.fill(
            child: Material(
              color: _kSoftBg,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: const Icon(Icons.notifications_none_rounded, size: 20, color: AppColors.primary),
              ),
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: BoxDecoration(
                  color: _kRed,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  unreadCount > 9 ? '٩+' : _toArabicDigits('$unreadCount'),
                  style: const TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImpactBanner extends StatelessWidget {
  final List<Campaign> campaigns;

  const _ImpactBanner({required this.campaigns});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');
    final totalRaised = campaigns.fold<double>(0, (sum, c) => sum + c.collectedAmount);
    final activeCount = campaigns.where((c) => c.isActive).length;
    final fundCount = campaigns
        .map((c) => c.fundId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF0F766E)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.volunteer_activism_outlined, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'إجمالي التبرعات',
                        style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: Colors.white70),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _toArabicDigits(fmt.format(totalRaised)),
                            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'ج.س',
                            style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _ImpactStat(label: 'مبادرات نشطة', value: _toArabicDigits('$activeCount'))),
                Expanded(child: _ImpactStat(label: 'صناديق دعم', value: _toArabicDigits('$fundCount'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ImpactStat extends StatelessWidget {
  final String label;
  final String value;

  const _ImpactStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, color: Colors.white70)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.actionLabel = '', this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: _kNameColor),
            ),
          ),
          if (actionLabel.isNotEmpty && onAction != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FundsSection extends StatelessWidget {
  final List<Fund> funds;
  final String title;
  final VoidCallback? onOpenAll;

  const _FundsSection({required this.funds, required this.title, this.onOpenAll});

  @override
  Widget build(BuildContext context) {
    if (funds.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: title,
            actionLabel: onOpenAll != null ? 'عرض الكل' : '',
            onAction: onOpenAll,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const BouncingScrollPhysics(),
              itemCount: funds.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _FundCard(fund: funds[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _FundCard extends StatelessWidget {
  final Fund fund;

  const _FundCard({required this.fund});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');
    final balanceText = _toArabicDigits(fmt.format(fund.balance));

    return Container(
      width: 170,
      height: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kDivider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: fund.isPermanent ? AppColors.primaryLight : _kSoftBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  fund.isPermanent ? 'دائم' : 'مؤقت',
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: fund.isPermanent ? AppColors.primary : _kSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            fund.nameAr,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _kNameColor,
              height: 1.3,
            ),
          ),
          const Spacer(),
          const Text(
            'الرصيد',
            style: TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 10,
              color: _kMuted,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  balanceText,
                  style: const TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'ج.س',
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 10,
                    color: _kSecondary,
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

class _CampaignsSection extends StatelessWidget {
  final String title;
  final List<Campaign> campaigns;
  final String emptyMessage;

  const _CampaignsSection({required this.title, required this.campaigns, this.emptyMessage = ''});

  @override
  Widget build(BuildContext context) {
    if (campaigns.isEmpty && emptyMessage.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title),
          const SizedBox(height: 12),
          if (campaigns.isEmpty)
            _EmptyCard(message: emptyMessage)
          else
            for (final c in campaigns)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: _CampaignCard(campaign: c),
              ),
        ],
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final Campaign campaign;

  const _CampaignCard({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final percent = (campaign.progress * 100).clamp(0, 100).round();
    final fmt = NumberFormat('#,##0');
    final hasImage = campaign.image != null && campaign.image!.isNotEmpty;
    final isActive = campaign.isActive;
    final collected = _toArabicDigits(fmt.format(campaign.collectedAmount));
    final target = _toArabicDigits(fmt.format(campaign.targetAmount));
    final daysLeft = _daysLeftLabel(campaign.endDate);
    final subtitle = (campaign.fundName != null && campaign.fundName!.trim().isNotEmpty)
        ? campaign.fundName!
        : ((campaign.description ?? '').trim());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/campaign/${campaign.id}'),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _kDivider),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                child: SizedBox(
                  height: 148,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasImage)
                        Image.network(
                          resolveMediaUrl(campaign.image),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const _CampaignHeroPlaceholder(),
                        )
                      else
                        const _CampaignHeroPlaceholder(),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.05),
                              Colors.black.withValues(alpha: 0.55),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _StatusBadge(isActive: isActive),
                      ),
                      if (daysLeft != null)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.schedule_rounded, size: 14, color: _kSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  daysLeft,
                                  style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 10, fontWeight: FontWeight.w600, color: _kSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Positioned(
                        right: 12,
                        left: 12,
                        bottom: 12,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.payments_outlined, size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    'تم جمع $collected ج.س',
                                    style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kNameColor,
                        height: 1.35,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'IBMPlexSansArabic',
                          fontSize: 12,
                          color: _kSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _MiniStat(label: 'المستهدف', value: '$target ج.س'),
                        Container(width: 1, height: 28, margin: const EdgeInsets.symmetric(horizontal: 12), color: _kDivider),
                        _MiniStat(label: 'المُجمَّع', value: '$collected ج.س'),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${_toArabicDigits('$percent')}٪',
                            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: campaign.progress.clamp(0.0, 1.0)),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor: _kSoftBg,
                          color: isActive ? AppColors.primary : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isActive ? 'ساهم الآن وكن جزءًا من الأثر' : 'اكتملت الحملة — يمكنك عرض التفاصيل',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, color: _kMuted),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => context.push('/campaign/${campaign.id}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isActive ? AppColors.primary : const Color(0xFFE2E8F0),
                            foregroundColor: isActive ? Colors.white : _kNameColor,
                            elevation: 0,
                            minimumSize: const Size(0, 38),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          child: Text(isActive ? 'تبرع الآن' : 'عرض التفاصيل'),
                        ),
                      ],
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

  static String? _daysLeftLabel(DateTime? endDate) {
    if (endDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final diff = end.difference(today).inDays;
    if (diff < 0) return null;
    if (diff == 0) return 'آخر يوم';
    if (diff == 1) return 'متبقي يوم';
    if (diff == 2) return 'متبقي يومان';
    if (diff <= 10) return 'متبقي $diff أيام';
    return 'متبقي $diff يومًا';
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final bg = isActive ? const Color(0xFF16A34A) : const Color(0xFF64748B);
    final label = isActive ? 'نشطة' : 'مكتملة';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isActive ? Icons.bolt_rounded : Icons.check_circle_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 10, color: _kMuted)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, fontWeight: FontWeight.w700, color: _kNameColor)),
      ],
    );
  }
}

class _CampaignHeroPlaceholder extends StatelessWidget {
  const _CampaignHeroPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0D9488), Color(0xFF044465)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), shape: BoxShape.circle),
            ),
          ),
          Positioned(
            right: -10,
            bottom: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), shape: BoxShape.circle),
            ),
          ),
          const Center(
            child: Icon(Icons.volunteer_activism_rounded, size: 44, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: _kSoftBg, borderRadius: BorderRadius.circular(16)),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: _kMuted),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kDivider),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: _kSoftBg, shape: BoxShape.circle),
              child: const Icon(Icons.volunteer_activism_outlined, size: 28, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            const Text(
              'لا توجد مبادرات حالياً',
              style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: _kNameColor),
            ),
            const SizedBox(height: 6),
            const Text(
              'تابعنا لاحقاً للاطلاع على الصناديق والمبادرات الجديدة.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: _kMuted, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonationsSkeleton extends StatelessWidget {
  const _DonationsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: skeletonBox(height: 132, borderRadius: 18),
        ),
        for (var i = 0; i < 2; i++)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: skeletonBox(height: 168, borderRadius: 20),
          ),
      ],
    );
  }
}

String _toArabicDigits(String input) {
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  final buffer = StringBuffer();
  for (final char in input.split('')) {
    final code = char.codeUnitAt(0) - 0x30;
    buffer.write(code >= 0 && code <= 9 ? digits[code] : char);
  }
  return buffer.toString();
}
