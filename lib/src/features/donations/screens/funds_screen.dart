import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:tawati_mobile/src/core/providers.dart';
import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/core/widgets/skeleton.dart';
import 'package:tawati_mobile/src/features/donations/models/donation.dart';

const Color _kSoftBg = Color(0xFFF1F5F8);
const Color _kMuted = Color(0xFF9CAFB8);
const Color _kSecondary = Color(0xFF62707B);
const Color _kNameColor = Color(0xFF1A242B);
const Color _kDivider = Color(0xFFF1F5F8);

class FundsScreen extends ConsumerStatefulWidget {
  const FundsScreen({super.key});

  @override
  ConsumerState<FundsScreen> createState() => _FundsScreenState();
}

class _FundsScreenState extends ConsumerState<FundsScreen> {
  List<Fund> _funds = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final funds = await ref.read(donationServiceProvider).getFunds();
      if (!mounted) return;
      setState(() {
        _funds = funds;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_funds.isEmpty) _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  child: _Header(onBack: () => context.pop()),
                ),
              ),
              if (_loading)
                const SliverToBoxAdapter(child: _FundsSkeleton())
              else if (_error != null)
                SliverToBoxAdapter(child: _ErrorState(message: _error!, onRetry: _load))
              else if (_funds.isEmpty)
                const SliverToBoxAdapter(child: _EmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.88,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _FundGridCard(fund: _funds[index]),
                      childCount: _funds.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Material(
              color: _kSoftBg,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onBack,
                child: const Icon(Icons.arrow_forward_rounded, size: 20, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الصناديق',
                  style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
                SizedBox(height: 2),
                Text(
                  'جميع صناديق الدعم في مجتمعك',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, color: _kMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FundGridCard extends StatelessWidget {
  final Fund fund;

  const _FundGridCard({required this.fund});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');
    final balanceText = _toArabicDigits(fmt.format(fund.balance));

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kDivider),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(9)),
                child: const Icon(Icons.account_balance_wallet_outlined, size: 16, color: AppColors.primary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: fund.isPermanent ? AppColors.primaryLight : _kSoftBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  fund.isPermanent ? 'دائم' : 'مؤقت',
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: fund.isPermanent ? AppColors.primary : _kSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            fund.nameAr,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _kNameColor,
              height: 1.25,
            ),
          ),
          const Spacer(),
          const Text(
            'الرصيد',
            style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 8, color: _kMuted),
          ),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  balanceText,
                  style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
                const SizedBox(width: 2),
                const Text(
                  'ج.س',
                  style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 8, color: _kSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FundsSkeleton extends StatelessWidget {
  const _FundsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.88,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => skeletonBox(borderRadius: 16),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
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
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: _kSecondary, height: 1.6),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              onPressed: onRetry,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
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
              child: const Icon(Icons.account_balance_wallet_outlined, size: 28, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            const Text(
              'لا توجد صناديق حالياً',
              style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: _kNameColor),
            ),
            const SizedBox(height: 6),
            const Text(
              'تابعنا لاحقاً للاطلاع على الصناديق المتاحة.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: _kMuted, height: 1.6),
            ),
          ],
        ),
      ),
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
