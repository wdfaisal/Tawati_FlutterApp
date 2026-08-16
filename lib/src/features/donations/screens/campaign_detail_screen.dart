import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/core/providers.dart';
import 'package:tawati_mobile/src/core/widgets/skeleton.dart';
import 'package:tawati_mobile/src/features/donations/models/donation.dart';

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
        backgroundColor: AppColors.surface,
        body: _loading
            ? skeletonDetailPage(context)
            : _error != null
                ? _buildError()
                : _buildContent(),
        bottomNavigationBar: _campaign != null && _campaign!.isActive
            ? _buildBottomCta()
            : null,
      ),
    );
  }

  Widget _buildError() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الحملة', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            const Text(
              'حدث خطأ، يرجى المحاولة مرة أخرى',
              style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: AppColors.textSecondary),
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

  Widget _buildContent() {
    final campaign = _campaign!;
    final fmt = NumberFormat('#,##0');
    final progress = campaign.progress;
    final percent = (progress * 100).toInt();

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(campaign),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildProgressCard(campaign, fmt, percent),
                const SizedBox(height: 16),
                _buildAboutSection(campaign),
                const SizedBox(height: 16),
                _buildRecentDonors(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(Campaign campaign) {
    final hasImage = campaign.image != null && campaign.image!.isNotEmpty;
    final baseUrl = 'http://10.237.182.29:3000';

    return SliverAppBar(
      expandedHeight: MediaQuery.of(context).size.height * 0.35,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      leading: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.share_outlined, size: 18),
            ),
            onPressed: () {},
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    '${campaign.image!.startsWith('http') ? '' : baseUrl}$campaign.image',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildHeroGradient(campaign),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    right: 16,
                    left: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'حملة تبرع',
                            style: TextStyle(
                              fontFamily: 'IBMPlexSansArabic',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          campaign.title,
                          style: const TextStyle(
                            fontFamily: 'IBMPlexSansArabic',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (campaign.fundName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            campaign.fundName!,
                            style: const TextStyle(
                              fontFamily: 'IBMPlexSansArabic',
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              )
            : _buildHeroGradient(campaign),
      ),
    );
  }

  Widget _buildHeroGradient(Campaign campaign) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
        ),
        Positioned(
          top: -60, right: -60,
          child: Container(
            width: 180, height: 180,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -40, left: -40,
          child: Container(
            width: 140, height: 140,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 24, right: 24, left: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'حملة تبرع',
                  style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                campaign.title,
                style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              if (campaign.fundName != null) ...[
                const SizedBox(height: 4),
                Text(campaign.fundName!, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: Colors.white70)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard(Campaign campaign, NumberFormat fmt, int percent) {
    final progress = campaign.progress;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('المبلغ المجموع', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(fmt.format(campaign.collectedAmount), style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(width: 4),
                        Text('ج.س', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('الهدف', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('${fmt.format(campaign.targetAmount)} ج.س', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.primaryLight,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 6),
          Row(children: [Text('%$percent من الهدف المكتمل', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary))]),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(Icons.groups_outlined, 'عدد المتبرعين', '${campaign.donorCount ?? 0}'),
              const Spacer(),
              _buildStatItem(Icons.schedule_outlined, 'الأيام المتبقية', campaign.isActive ? '30 يوم' : 'منتهية'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 10, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
      ],
    );
  }

  Widget _buildAboutSection(Campaign campaign) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4, height: 20,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 10),
              const Text('عن الحملة', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            campaign.description ?? 'لا يوجد وصف',
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: AppColors.textSecondary, height: 1.7),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDonors() {
    final donors = [
      {'name': 'فاعل خير', 'amount': '500', 'time': 'منذ 15 دقيقة', 'isKnown': false},
      {'name': 'أحمد محمد آل سعيد', 'amount': '1,200', 'time': 'منذ ساعة', 'isKnown': true},
      {'name': 'فاعل خير', 'amount': '100', 'time': 'منذ 3 ساعات', 'isKnown': false},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('آخر المساهمات', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          ...donors.map((d) => _buildDonorItem(d['name'] as String, d['amount'] as String, d['time'] as String, d['isKnown'] as bool)),
        ],
      ),
    );
  }

  Widget _buildDonorItem(String name, String amount, String time, bool isKnown) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isKnown ? AppColors.primaryLight : AppColors.border,
            child: Icon(Icons.person, size: 16, color: isKnown ? AppColors.primary : AppColors.textHint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(time, style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 10, color: AppColors.textHint)),
              ],
            ),
          ),
          Text('$amount ج.س', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildBottomCta() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: () => _showDonateDialog(),
                icon: const Icon(Icons.favorite, size: 18),
                label: const Text('تبرع الآن', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primaryLight),
              ),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.favorite_border, color: AppColors.primary, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDonateDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DonationBottomSheet(
        campaign: _campaign!,
      ),
    );
  }
}

class DonationBottomSheet extends ConsumerStatefulWidget {
  final Campaign campaign;

  const DonationBottomSheet({
    super.key,
    required this.campaign,
  });

  @override
  ConsumerState<DonationBottomSheet> createState() =>
      _DonationBottomSheetState();
}

class _DonationBottomSheetState extends ConsumerState<DonationBottomSheet> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isManual = true;
  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final amount = double.parse(_amountController.text);

      if (_isManual) {
        final manualMethods = widget.campaign.paymentMethods
            .where((m) => m.type == 'manual')
            .toList();
        if (manualMethods.isEmpty) {
          if (mounted) {
            setState(() => _submitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('لا توجد طريقة دفع يدوية متاحة لهذه الحملة', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
        await ref.read(donationServiceProvider).createManualDonation(
              campaignId: widget.campaign.id,
              amount: amount,
              paymentMethodId: manualMethods.first.id,
            );
        if (mounted) {
          Navigator.of(context).pop();
          _showSuccessDialog(true);
        }
      } else {
        await _handleStripePayment(amount);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        String message = 'فشل التبرع';
        try {
          if (e is Exception) {
            final dioErr = e as dynamic;
            if (dioErr.response?.data?['message'] != null) {
              message = dioErr.response!.data['message'] as String;
            }
          }
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message, style: const TextStyle(fontFamily: 'IBMPlexSansArabic')),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleStripePayment(double amount) async {
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.post('/payments/stripe/create-intent', data: {
      'campaign_id': widget.campaign.id,
      'amount': amount,
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
      Navigator.of(context).pop();
      _showSuccessDialog(false);
    }
  }

  void _showSuccessDialog(bool isManual) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تم التسجيل', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
        content: Text(
          isManual
              ? 'شكراً لك! تم تسجيل تبرعك وسيتم مراجعته من قبل الإدارة.'
              : 'شكراً لك! تم تأكيد تبرعك بنجاح.',
          style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('حسناً', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
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
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [10000, 20000, 50000, 100000].map((amount) {
                  final f = NumberFormat('#,##0');
                  return GestureDetector(
                    onTap: () => _amountController.text = amount.toString(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primaryLight),
                      ),
                      child: Text('${f.format(amount)} ج.س', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('طريقة الدفع', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isManual = true),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isManual ? AppColors.primaryLight : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _isManual ? AppColors.primary : AppColors.border, width: _isManual ? 2 : 1),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.account_balance_outlined, color: _isManual ? AppColors.primary : AppColors.textHint),
                            const SizedBox(height: 8),
                            Text('تحويل يدوي', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, fontWeight: FontWeight.w600, color: _isManual ? AppColors.primary : AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isManual = false),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: !_isManual ? AppColors.primaryLight : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: !_isManual ? AppColors.primary : AppColors.border, width: !_isManual ? 2 : 1),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.credit_card_outlined, color: !_isManual ? AppColors.primary : AppColors.textHint),
                            const SizedBox(height: 8),
                            Text('Stripe', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, fontWeight: FontWeight.w600, color: !_isManual ? AppColors.primary : AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_isManual) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('أرقام الحسابات للتحويل:', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      _buildAccountRow('البنك الأهلي', 'SA00 0000 0000 0000 0000'),
                      const SizedBox(height: 4),
                      _buildAccountRow('بنك الراجحي', 'SA00 0000 0000 0000 0000'),
                      const SizedBox(height: 8),
                      const Text('ملاحظة: يتم مراجعة التحويلات يدوياً من قبل الإدارة', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
                  child: const Text('سيتم توجيهك لصفحة الدفع الآمن عبر Stripe. يتم تأكيد التبرع فوراً.', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: AppColors.textSecondary)),
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
    );
  }

  Widget _buildAccountRow(String bankName, String accountNumber) {
    return Row(
      children: [
        const Icon(Icons.account_balance, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text('$bankName: $accountNumber', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: AppColors.textPrimary)),
        ),
      ],
    );
  }
}
