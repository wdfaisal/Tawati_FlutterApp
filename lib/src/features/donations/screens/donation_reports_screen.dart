import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/theme/app_theme.dart';
import '../services/admin_donation_service.dart';

class DonationReportsScreen extends ConsumerStatefulWidget {
  const DonationReportsScreen({super.key});

  @override
  ConsumerState<DonationReportsScreen> createState() => _DonationReportsScreenState();
}

class _DonationReportsScreenState extends ConsumerState<DonationReportsScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  Map<String, dynamic>? _report;
  bool _loading = true;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _loading = true);
    try {
      final service = ref.read(adminDonationServiceProvider);
      final data = await service.getDonationReports(from: _fromDate, to: _toDate);
      if (!mounted) return;
      setState(() {
        _report = data;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (_fromDate ?? now.subtract(const Duration(days: 365))) : (_toDate ?? now),
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          if (_toDate != null && _toDate!.isBefore(picked)) _toDate = null;
        } else {
          _toDate = picked;
          if (_fromDate != null && _fromDate!.isAfter(picked)) _fromDate = null;
        }
      });
      _loadReport();
    }
  }

  void _clearDates() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    _loadReport();
  }

  Future<void> _exportReport() async {
    if (_report == null) return;
    setState(() => _exporting = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      _showPrintPreview();
      setState(() => _exporting = false);
    }
  }

  void _showPrintPreview() {
    final totals = _report!['totals'] as Map<String, dynamic>? ?? {'total': 0, 'count': 0};
    final byCampaign = (_report!['byCampaign'] as List<dynamic>?) ?? [];
    final byMethod = (_report!['byMethod'] as List<dynamic>?) ?? [];
    final fmt = NumberFormat('#,##0');
    final dateRange = _dateRangeLabel();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, ctrl) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.print_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('معاينة التقرير', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primary))),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Color(0xFF64748B))),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _reportHeader(dateRange),
                  const SizedBox(height: 20),
                  _reportSummaryCard(fmt, totals),
                  const SizedBox(height: 20),
                  if (byCampaign.isNotEmpty) ...[
                    _reportSectionTitle('التبرعات حسب الحملة'),
                    const SizedBox(height: 10),
                    ...byCampaign.map((item) => _reportCampaignRow(item, fmt)),
                    const SizedBox(height: 20),
                  ],
                  if (byMethod.isNotEmpty) ...[
                    _reportSectionTitle('التبرعات حسب طريقة الدفع'),
                    const SizedBox(height: 10),
                    ...byMethod.map((item) => _reportMethodRow(item, fmt)),
                    const SizedBox(height: 20),
                  ],
                  _reportFooter(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateRangeLabel() {
    final fmt = DateFormat('d/MM/yyyy', 'ar');
    if (_fromDate != null && _toDate != null) {
      return 'من ${fmt.format(_fromDate!)} إلى ${fmt.format(_toDate!)}';
    }
    if (_fromDate != null) return 'من ${fmt.format(_fromDate!)}';
    if (_toDate != null) return 'إلى ${fmt.format(_toDate!)}';
    return 'جميع الفترات';
  }

  @override
  Widget build(BuildContext context) {
    final totals = _report?['totals'] as Map<String, dynamic>? ?? {'total': 0, 'count': 0};
    final byCampaign = (_report?['byCampaign'] as List<dynamic>?) ?? [];
    final byMethod = (_report?['byMethod'] as List<dynamic>?) ?? [];
    final fmt = NumberFormat('#,##0');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 18, color: AppColors.primary), onPressed: () => context.pop()),
          title: const Text('التقارير المالية', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primary)),
          centerTitle: true,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _dateFilterRow(),
                  const SizedBox(height: 20),
                  _summaryCard(fmt, totals),
                  const SizedBox(height: 20),
                  if (byCampaign.isNotEmpty) ...[
                    _sectionTitle('التبرعات حسب الحملة'),
                    const SizedBox(height: 12),
                    _breakdownCard(
                      byCampaign.map((item) {
                        final cid = item['_id'];
                        final title = cid is Map ? cid['title'] ?? 'حملة' : 'حملة';
                        return _breakdownRow(title, '${item['count']} تبرع', '${fmt.format(item['total'] ?? 0)} ج.س');
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (byMethod.isNotEmpty) ...[
                    _sectionTitle('التبرعات حسب طريقة الدفع'),
                    const SizedBox(height: 12),
                    _breakdownCard(
                      byMethod.map((item) {
                        final pm = item['_id'];
                        final name = pm is Map ? pm['display_name_ar'] ?? pm['provider_key'] ?? 'طريقة' : 'طريقة';
                        return _breakdownRow(name, '${item['count']} تبرع', '${fmt.format(item['total'] ?? 0)} ج.س');
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  _exportButton(),
                ],
              ),
      ),
    );
  }

  Widget _dateFilterRow() {
    return Row(
      children: [
        Expanded(child: _dateButton('من', _fromDate, () => _pickDate(isFrom: true))),
        const SizedBox(width: 12),
        Expanded(child: _dateButton('إلى', _toDate, () => _pickDate(isFrom: false))),
        if (_fromDate != null || _toDate != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _clearDates,
            child: Container(
              width: 40,
              height: 48,
              decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.close, size: 18, color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _dateButton(String label, DateTime? date, VoidCallback onTap) {
    final fmt = DateFormat('d/MM/yyyy');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF94A3B8)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 10, color: Color(0xFF94A3B8))),
                  Text(
                    date != null ? fmt.format(date) : 'اختر التاريخ',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: date != null ? AppColors.primary : const Color(0xFF64748B),
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

  Widget _summaryCard(NumberFormat fmt, Map<String, dynamic> totals) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.primary, Color(0xFF033A57)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            left: -30,
            child: Container(width: 120, height: 120, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), shape: BoxShape.circle)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('إجمالي التبرعات المؤكدة', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: Colors.white.withValues(alpha: 0.85))),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(fmt.format(totals['total'] ?? 0), style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(width: 6),
                  Text('ج.س', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _miniStat('${totals['count'] ?? 0}', 'تبرع مؤكد'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Text(value, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, color: Colors.white.withValues(alpha: 0.85))),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary));
  }

  Widget _breakdownCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EBF0)),
      ),
      child: Column(children: children),
    );
  }

  Widget _breakdownRow(String title, String subtitle, String amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F8)))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          Text(amount, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _exportButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _exporting ? null : _exportReport,
        icon: _exporting
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.print_rounded, size: 22),
        label: Text(_exporting ? 'جاري التصدير...' : 'تصدير وطباعة التقرير', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _reportHeader(String dateRange) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Image.asset('assets/images/splash_logo.png', fit: BoxFit.contain),
          ),
          const SizedBox(height: 10),
          const Text('تواتي', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 4),
          const Text('تقرير التبرعات المالية', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: Color(0xFF62707B))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(dateRange, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          Text('تم إعداد التقرير في: ${DateFormat('d/MM/yyyy  HH:mm', 'ar').format(DateTime.now())}', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _reportSummaryCard(NumberFormat fmt, Map<String, dynamic> totals) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [AppColors.primary, Color(0xFF033A57)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الملخص العام', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 12),
          Row(
            children: [
              _reportMiniStat('إجمالي المبالغ', '${fmt.format(totals['total'] ?? 0)} ج.س'),
              const SizedBox(width: 16),
              _reportMiniStat('عدد التبرعات', '${totals['count'] ?? 0}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reportMiniStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, color: Colors.white.withValues(alpha: 0.75))),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _reportSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary));
  }

  Widget _reportCampaignRow(dynamic item, NumberFormat fmt) {
    final cid = item['_id'];
    final title = cid is Map ? cid['title'] ?? 'حملة' : 'حملة';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
            const SizedBox(height: 2),
            Text('${item['count']} تبرع', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, color: Color(0xFF94A3B8))),
          ])),
          Text('${fmt.format(item['total'] ?? 0)} ج.س', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _reportMethodRow(dynamic item, NumberFormat fmt) {
    final pm = item['_id'];
    final name = pm is Map ? pm['display_name_ar'] ?? pm['provider_key'] ?? 'طريقة' : 'طريقة';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
            const SizedBox(height: 2),
            Text('${item['count']} تبرع', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, color: Color(0xFF94A3B8))),
          ])),
          Text('${fmt.format(item['total'] ?? 0)} ج.س', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _reportFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Text(
        'هذا التقرير تم إعداده تلقائياً عبر منصة تواتي. جميع المبالغ مؤكدة ومصرح بها.',
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, color: Color(0xFF94A3B8), height: 1.5),
      ),
    );
  }
}
