import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../services/admin_donation_service.dart';

class DonationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> donation;
  const DonationDetailScreen({super.key, required this.donation});

  @override
  State<DonationDetailScreen> createState() => _DonationDetailScreenState();
}

class _DonationDetailScreenState extends State<DonationDetailScreen> {
  late final AdminDonationService _service;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _service = AdminDonationService(
      ApiClient(baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://54.251.69.36/api/v1')),
    );
  }

  Map<String, dynamic> get _d => widget.donation;

  String get _donorName {
    if (_d['is_anonymous'] == true) return 'فاعل خير';
    final uid = _d['user_id'];
    if (uid is Map) return uid['full_name'] ?? 'غير معروف';
    return 'غير معروف';
  }

  String get _donorPhone {
    final uid = _d['user_id'];
    if (uid is Map) return uid['phone'] ?? '';
    return '';
  }

  String get _campaignTitle {
    final cid = _d['campaign_id'];
    if (cid is Map) return cid['title'] ?? '';
    return '';
  }

  String get _methodName {
    final pm = _d['payment_method_id'];
    if (pm is Map) return pm['display_name_ar'] ?? pm['provider_key'] ?? '';
    return '';
  }

  bool get _isPending => _d['status'] == 'pending_manual_review' || _d['status'] == 'pending_payment';

  ({Color color, String label, IconData icon}) _statusConfig() {
    switch (_d['status']) {
      case 'confirmed':
        return (color: const Color(0xFF22C55E), label: 'مكتمل', icon: Icons.check_circle_outline);
      case 'pending_manual_review':
      case 'pending_payment':
        return (color: const Color(0xFFF59E0B), label: 'قيد المراجعة', icon: Icons.schedule);
      case 'rejected':
        return (color: const Color(0xFFEF4444), label: 'مرفوض', icon: Icons.cancel_outlined);
      default:
        return (color: const Color(0xFF94A3B8), label: _d['status'] ?? '', icon: Icons.help_outline);
    }
  }

  Future<void> _approve() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد التبرع', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w700)),
        content: const Text('هل أنت متأكد من تأكيد هذا التبرع؟', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(fontFamily: 'IBMPlexSansArabic', color: Color(0xFF64748B)))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تأكيد', style: TextStyle(fontFamily: 'IBMPlexSansArabic', color: Color(0xFF22C55E), fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _actionLoading = true);
    try {
      await _service.approveDonation(_d['_id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تأكيد التبرع بنجاح', style: TextStyle(fontFamily: 'IBMPlexSansArabic')), backgroundColor: Color(0xFF22C55E)),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e', style: const TextStyle(fontFamily: 'IBMPlexSansArabic')), backgroundColor: const Color(0xFFEF4444)),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _reject() async {
    final notesCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رفض التبرع', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w700)),
        content: TextField(
          controller: notesCtrl,
          decoration: const InputDecoration(hintText: 'سبب الرفض (اختياري)', hintStyle: TextStyle(fontFamily: 'IBMPlexSansArabic')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(fontFamily: 'IBMPlexSansArabic', color: Color(0xFF64748B)))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('رفض', style: TextStyle(fontFamily: 'IBMPlexSansArabic', color: Color(0xFFEF4444), fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _actionLoading = true);
    try {
      await _service.rejectDonation(_d['_id'], notes: notesCtrl.text.isEmpty ? null : notesCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفض التبرع', style: TextStyle(fontFamily: 'IBMPlexSansArabic')), backgroundColor: Color(0xFFF59E0B)),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e', style: const TextStyle(fontFamily: 'IBMPlexSansArabic')), backgroundColor: const Color(0xFFEF4444)),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');
    final sc = _statusConfig();
    final createdAt = _d['created_at'] != null ? DateTime.tryParse(_d['created_at'])?.toLocal() : null;
    final dateStr = createdAt != null ? DateFormat('d MMMM yyyy  •  HH:mm', 'ar').format(createdAt) : '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 18, color: AppColors.primary), onPressed: () => context.pop()),
          title: const Text('تفاصيل التبرع', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primary)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _statusBanner(sc),
              const SizedBox(height: 20),
              _infoCard([
                _infoTile('المتبرع', _donorName),
                _infoTile('رقم الهاتف', _donorPhone.isEmpty ? '-' : _donorPhone),
                _infoTile('الحملة', _campaignTitle),
                _infoTile('تاريخ الإنشاء', dateStr.isEmpty ? '-' : dateStr),
              ]),
              const SizedBox(height: 16),
              _infoCard([
                _infoTile('المبلغ', '${fmt.format(_d['amount'] ?? 0)} ج.س', valueColor: AppColors.primary),
                _infoTile('طريقة الدفع', _methodName.isEmpty ? '-' : _methodName),
                _infoTile('رقم المرجع', (_d['reference_number'] ?? '-').toString()),
                _infoTile('تاريخ التحويل', _d['transfer_date'] != null
                    ? DateFormat('d MMM yyyy', 'ar').format(DateTime.parse(_d['transfer_date']).toLocal())
                    : '-'),
              ]),
              if (_d['is_anonymous'] == true) ...[
                const SizedBox(height: 16),
                _infoCard([_infoTile('تبرع مجهول', 'نعم', valueColor: const Color(0xFFF59E0B))]),
              ],
              if (_isPending) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _actionLoading ? null : _approve,
                          icon: _actionLoading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_circle_outline, size: 20),
                          label: const Text('تأكيد التبرع', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _actionLoading ? null : _reject,
                          icon: const Icon(Icons.cancel_outlined, size: 20),
                          label: const Text('رفض', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBanner(({Color color, String label, IconData icon}) sc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [sc.color, sc.color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: sc.color.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(sc.icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sc.label, style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: Colors.white.withValues(alpha: 0.85))),
                const SizedBox(height: 4),
                Text(
                  '${fmt.format(_d['amount'] ?? 0)} ج.س',
                  style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static final fmt = NumberFormat('#,##0');

  Widget _infoCard(List<Widget> children) {
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

  Widget _infoTile(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: Color(0xFF62707B))),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}
