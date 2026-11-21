import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/core/providers.dart';
import 'package:tawati_mobile/src/core/widgets/skeleton.dart';
import 'package:tawati_mobile/src/features/donations/models/donation.dart';

class MyDonationsScreen extends ConsumerStatefulWidget {
  const MyDonationsScreen({super.key});

  @override
  ConsumerState<MyDonationsScreen> createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends ConsumerState<MyDonationsScreen> {
  List<Donation> _donations = [];
  bool _loading = true;
  String? _error;
  String _filter = 'الكل';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final donations = await ref.read(donationServiceProvider).getMyDonations();
      if (mounted) {
        setState(() {
          _donations = donations;
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

  List<Donation> get _filteredDonations {
    switch (_filter) {
      case 'مكتملة':
        return _donations.where((d) => d.isConfirmed).toList();
      case 'قيد المعالجة':
        return _donations.where((d) => d.isPending).toList();
      default:
        return _donations;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');
    final totalAmount = _donations.fold<double>(0, (sum, d) => sum + d.amount);
    final completedCount = _donations.where((d) => d.isConfirmed).length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: _loading
              ? skeletonListPage()
              : _error != null
                  ? _buildError()
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppColors.primary,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        children: [
                          _buildHeader(context),
                          const SizedBox(height: 20),
                          _buildSummaryCard(fmt, totalAmount, completedCount),
                          const SizedBox(height: 20),
                          _buildFilterTabs(),
                          const SizedBox(height: 12),
                          ..._filteredDonations.map((d) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildDonationItem(d, fmt),
                              )),
                          if (_filteredDonations.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(32),
                              child: const Center(
                                child: Text(
                                  'لا توجد تبرعات',
                                  style: TextStyle(
                                    fontFamily: 'IBMPlexSansArabic',
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
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
            color: Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Directionality(
              textDirection: TextDirection.ltr,
              child: Icon(Icons.arrow_forward_rounded, color: AppColors.textPrimary, size: 22),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سجل تبرعاتي',
                style: TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'تابع جميع تبرعاتك ومساهماتك في مكان واحد',
                style: TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
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
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(NumberFormat fmt, double totalAmount, int completedCount) {
    return Container(
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
                      'إجمالي تبرعاتي',
                      style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: Colors.white70),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _toArabicDigits(fmt.format(totalAmount)),
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
              Expanded(child: _buildImpactStat('عدد التبرعات', _toArabicDigits('${_donations.length}'))),
              Expanded(child: _buildImpactStat('مكتملة', _toArabicDigits('$completedCount'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, color: Colors.white70)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['الكل', 'مكتملة', 'قيد المعالجة'];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: filters.map((f) {
          final isSelected = _filter == f;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _filter = f),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: isSelected
                      ? const Border(
                          bottom: BorderSide(color: AppColors.primary, width: 2.5),
                        )
                      : null,
                ),
                child: Text(
                  f,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDonationItem(Donation donation, NumberFormat fmt) {
    final statusConfig = _getStatusConfig(donation.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.water_drop_outlined, size: 24, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  donation.campaignName ?? 'حملة تبرعات',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(donation.createdAt),
                  style: const TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${fmt.format(donation.amount)} ج.س',
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusConfig.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusConfig.color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusConfig.label,
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusConfig.color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ({Color color, String label}) _getStatusConfig(String status) {
    switch (status) {
      case 'confirmed':
        return (color: const Color(0xFF22C55E), label: 'ناجحة');
      case 'pending_manual_review':
        return (color: const Color(0xFFF59E0B), label: 'تحت الإجراء');
      case 'failed':
        return (color: AppColors.error, label: 'فشلت');
      default:
        return (color: AppColors.textHint, label: status);
    }
  }

  String _toArabicDigits(String input) {
    const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    var out = input;
    for (var i = 0; i < western.length; i++) {
      out = out.replaceAll(western[i], eastern[i]);
    }
    return out;
  }

  String _formatDate(DateTime date) {
    final months = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    return '${date.day} ${months[date.month]} ${date.year} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
