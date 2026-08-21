import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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
    try {
      final pdf = await _generatePdf();
      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _ExportActionSheet(
          onPrint: () async {
            Navigator.pop(ctx);
            await Printing.layoutPdf(
              onLayout: (format) async => pdf.save(),
              name: 'تقرير_التبرعات_${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
            );
          },
          onDownload: () async {
            Navigator.pop(ctx);
            await _savePdfToFile(pdf);
          },
          onShare: () async {
            Navigator.pop(ctx);
            await _sharePdf(pdf);
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إنشاء التقرير: $e', style: const TextStyle(fontFamily: 'IBMPlexSansArabic'))),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<pw.Document> _generatePdf() async {
    final pdf = pw.Document();
    final fmt = NumberFormat('#,##0');
    final totals = _report!['totals'] as Map<String, dynamic>? ?? {'total': 0, 'count': 0};
    final byCampaign = (_report!['byCampaign'] as List<dynamic>?) ?? [];
    final byMethod = (_report!['byMethod'] as List<dynamic>?) ?? [];
    final dateRange = _dateRangeLabel();

    final regularData = await rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/IBMPlexSansArabic-Bold.ttf');
    final arabicFont = pw.Font.ttf(regularData);
    final arabicBold = pw.Font.ttf(boldData);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Text('تواتي', style: pw.TextStyle(font: arabicBold, fontSize: 24, color: PdfColor.fromHex('#044465'))),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text('تقرير التبرعات المالية', style: pw.TextStyle(font: arabicFont, fontSize: 14, color: PdfColor.fromHex('#62707B'))),
          ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: pw.BoxDecoration(
                color: PdfColor(0.016, 0.267, 0.396, 0.1),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(dateRange, style: pw.TextStyle(font: arabicBold, fontSize: 11, color: PdfColor.fromHex('#044465'))),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'تم إعداد التقرير في: ${DateFormat('d/MM/yyyy  HH:mm').format(DateTime.now())}',
              style: pw.TextStyle(font: arabicFont, fontSize: 10, color: PdfColor.fromHex('#94A3B8')),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [PdfColor.fromHex('#044465'), PdfColor.fromHex('#033A57')],
              ),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('الملخص العام', style: pw.TextStyle(font: arabicBold, fontSize: 14, color: PdfColors.white)),
                pw.SizedBox(height: 12),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('إجمالي المبالغ', style: pw.TextStyle(font: arabicFont, fontSize: 10, color: PdfColor(1, 1, 1, 0.75))),
                          pw.SizedBox(height: 4),
                          pw.Text('${fmt.format(totals['total'] ?? 0)} ج.س', style: pw.TextStyle(font: arabicBold, fontSize: 16, color: PdfColors.white)),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('عدد التبرعات', style: pw.TextStyle(font: arabicFont, fontSize: 10, color: PdfColor(1, 1, 1, 0.75))),
                          pw.SizedBox(height: 4),
                          pw.Text('${totals['count'] ?? 0}', style: pw.TextStyle(font: arabicBold, fontSize: 16, color: PdfColors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (byCampaign.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text('التبرعات حسب الحملة', style: pw.TextStyle(font: arabicBold, fontSize: 13, color: PdfColor.fromHex('#044465'))),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(font: arabicBold, fontSize: 10, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#044465')),
              cellStyle: pw.TextStyle(font: arabicFont, fontSize: 10),
              cellAlignment: pw.Alignment.centerRight,
              headerAlignment: pw.Alignment.centerRight,
              cellHeight: 30,
              cellAlignments: {0: pw.Alignment.centerRight, 1: pw.Alignment.center, 2: pw.Alignment.centerLeft},
              headerAlignments: {0: pw.Alignment.centerRight, 1: pw.Alignment.center, 2: pw.Alignment.centerLeft},
              headers: ['الحملة', 'عدد التبرعات', 'المبلغ'],
              data: byCampaign.map((item) {
                final cid = item['_id'];
                final title = cid is Map ? cid['title'] ?? 'حملة' : 'حملة';
                return [title, '${item['count']}', '${fmt.format(item['total'] ?? 0)} ج.س'];
              }).toList(),
            ),
          ],
          if (byMethod.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text('التبرعات حسب طريقة الدفع', style: pw.TextStyle(font: arabicBold, fontSize: 13, color: PdfColor.fromHex('#044465'))),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(font: arabicBold, fontSize: 10, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#044465')),
              cellStyle: pw.TextStyle(font: arabicFont, fontSize: 10),
              cellAlignment: pw.Alignment.centerRight,
              headerAlignment: pw.Alignment.centerRight,
              cellHeight: 30,
              cellAlignments: {0: pw.Alignment.centerRight, 1: pw.Alignment.center, 2: pw.Alignment.centerLeft},
              headerAlignments: {0: pw.Alignment.centerRight, 1: pw.Alignment.center, 2: pw.Alignment.centerLeft},
              headers: ['طريقة الدفع', 'عدد التبرعات', 'المبلغ'],
              data: byMethod.map((item) {
                final pm = item['_id'];
                final name = pm is Map ? pm['display_name_ar'] ?? pm['provider_key'] ?? 'طريقة' : 'طريقة';
                return [name, '${item['count']}', '${fmt.format(item['total'] ?? 0)} ج.س'];
              }).toList(),
            ),
          ],
          pw.SizedBox(height: 30),
          pw.Center(
            child: pw.Text(
              'هذا التقرير تم إعداده تلقائياً عبر منصة تواتي. جميع المبالغ مؤكدة ومصرح بها.',
              style: pw.TextStyle(font: arabicFont, fontSize: 9, color: PdfColor.fromHex('#94A3B8')),
            ),
          ),
        ],
      ),
    );
    return pdf;
  }

  Future<void> _savePdfToFile(pw.Document pdf) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/تقرير_التبرعات_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf');
    await file.writeAsBytes(await pdf.save());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ التقرير في: ${file.path}', style: const TextStyle(fontFamily: 'IBMPlexSansArabic')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _sharePdf(pw.Document pdf) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/تقرير_التبرعات_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf');
    await file.writeAsBytes(await pdf.save());
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'تقرير_التبرعات.pdf');
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
}

class _ExportActionSheet extends StatelessWidget {
  final VoidCallback onPrint;
  final VoidCallback onDownload;
  final VoidCallback onShare;

  const _ExportActionSheet({
    required this.onPrint,
    required this.onDownload,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('تصدير التقرير', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 8),
            const Text('اختر طريقة التصدير', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: Color(0xFF94A3B8))),
            const SizedBox(height: 16),
            _actionTile(
              icon: Icons.print_rounded,
              title: 'طباعة',
              subtitle: 'إرسال التقرير للطابعة',
              onTap: onPrint,
            ),
            _actionTile(
              icon: Icons.download_rounded,
              title: 'حفظ كملف PDF',
              subtitle: 'حفظ التقرير على الجهاز',
              onTap: onDownload,
            ),
            _actionTile(
              icon: Icons.share_rounded,
              title: 'مشاركة',
              subtitle: 'إرسال التقرير عبر تطبيقات أخرى',
              onTap: onShare,
              isLast: true,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          title: Text(title, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
          subtitle: Text(subtitle, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: Color(0xFF94A3B8))),
          trailing: const Icon(Icons.arrow_back_ios_rounded, size: 16, color: Color(0xFFCBD5E1)),
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Divider(height: 1, color: Color(0xFFF1F5F8)),
          ),
      ],
    );
  }
}
