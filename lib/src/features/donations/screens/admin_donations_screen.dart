import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/theme/app_theme.dart';
import '../models/donation.dart';
import '../services/admin_donation_service.dart';

class AdminDonationsScreen extends ConsumerStatefulWidget {
  const AdminDonationsScreen({super.key});

  @override
  ConsumerState<AdminDonationsScreen> createState() => _AdminDonationsScreenState();
}

class _AdminDonationsScreenState extends ConsumerState<AdminDonationsScreen> {
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _allDonations = [];
  List<Campaign> _campaigns = [];
  Campaign? _selectedCampaign;
  bool _loading = true;
  String? _error;
  String _filter = 'الكل';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final service = ref.read(adminDonationServiceProvider);
      final results = await Future.wait([
        service.getAdminDonations(limit: 200),
        service.getAdminCampaigns(),
      ]);
      if (!mounted) return;
      setState(() {
        _allDonations = results[0] as List<Map<String, dynamic>>;
        _campaigns = results[1] as List<Campaign>;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  List<Map<String, dynamic>> get _filteredDonations {
    var list = _allDonations;
    if (_selectedCampaign != null) {
      final cid = _selectedCampaign!.id;
      list = list.where((d) {
        final cId = (d['campaign_id'] is Map) ? d['campaign_id']['_id'] : d['campaign_id'];
        return cId == cid;
      }).toList();
    }
    switch (_filter) {
      case 'مكتمل':
        list = list.where((d) => d['status'] == 'confirmed').toList();
        break;
      case 'قيد الانتظار':
        list = list.where((d) => d['status'] == 'pending_manual_review' || d['status'] == 'pending_payment').toList();
        break;
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((d) {
        final userName = _donorName(d).toLowerCase();
        final ref = (d['reference_number'] ?? '').toString().toLowerCase();
        return userName.contains(q) || ref.contains(q);
      }).toList();
    }
    return list;
  }

  double get _totalAmount => _filteredDonations.fold<double>(0, (s, d) => s + (d['amount'] ?? 0).toDouble());
  int get _donorCount => _filteredDonations.length;
  int get _pendingCount => _allDonations.where((d) => d['status'] == 'pending_manual_review' || d['status'] == 'pending_payment').length;

  String _donorName(Map<String, dynamic> d) {
    if (d['is_anonymous'] == true) return 'فاعل خير';
    final uid = d['user_id'];
    if (uid is Map) return uid['full_name'] ?? 'غير معروف';
    return 'غير معروف';
  }

  String _campaignTitle(Map<String, dynamic> d) {
    final cid = d['campaign_id'];
    if (cid is Map) return cid['title'] ?? '';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/admin/donation-reports'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.bar_chart_rounded, size: 20),
          label: const Text('التقارير', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w600)),
        ),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
                              const SizedBox(height: 12),
                              const Text('حدث خطأ في تحميل البيانات', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15, color: Color(0xFF62707B))),
                              const SizedBox(height: 8),
                              Text(_error!, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: Color(0xFF94A3B8)), textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              TextButton.icon(
                                onPressed: _loadData,
                                icon: const Icon(Icons.refresh),
                                label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView(
                        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 80),
                        children: [
                          _buildCampaignDropdown(fmt),
                          _buildStatsRow(fmt),
                          _buildSearchBar(),
                          _buildFilterTabs(),
                          _buildDonationsList(fmt),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 12),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: Color(0xFFF1F5F8), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'إدارة التبرعات',
            style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignDropdown(NumberFormat fmt) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('اختر الحملة', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showCampaignPicker,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedCampaign?.title ?? 'جميع الحملات',
                      style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15, color: Color(0xFF0F172A)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_selectedCampaign != null)
                    GestureDetector(
                      onTap: () => setState(() => _selectedCampaign = null),
                      child: const Icon(Icons.close, size: 18, color: Color(0xFF94A3B8)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCampaignPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, ctrl) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('اختر الحملة', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _campaignOption(null),
                  ..._campaigns.map((c) => _campaignOption(c)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campaignOption(Campaign? campaign) {
    final isSelected = _selectedCampaign?.id == campaign?.id;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCampaign = campaign);
        Navigator.of(context).pop();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                campaign?.title ?? 'جميع الحملات',
                style: TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : const Color(0xFF0F172A),
                ),
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, size: 20, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(NumberFormat fmt) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          Expanded(child: _statCard('إجمالي التبرعات', '${fmt.format(_totalAmount)} ج.س')),
          const SizedBox(width: 12),
          Expanded(child: _statCard('عدد المتبرعين', '$_donorCount')),
          const SizedBox(width: 12),
          Expanded(child: _statCard('قيد المراجعة', '$_pendingCount')),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EBF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 10, color: Color(0xFF62707B))),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v),
        style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: 'بحث عن متبرع أو معاملة...',
          hintStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
          filled: true,
          fillColor: const Color(0xFFF1F5F8),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.2)),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['الكل', 'مكتمل', 'قيد الانتظار'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: filters.map((f) {
          final isSelected = _filter == f;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _filter = f),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : const Color(0xFFF1F5F8),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  f,
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF62707B),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDonationsList(NumberFormat fmt) {
    final items = _filteredDonations;
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(Icons.volunteer_activism_outlined, size: 48, color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            const Text('لا توجد تبرعات', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15, color: Color(0xFF62707B))),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5EBF0)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            _tableHeader(),
            ...items.asMap().entries.map((entry) => _donationRow(entry.value, fmt, entry.key < items.length - 1)),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE5EBF0))),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('المتبرع', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, color: Color(0xFF62707B)))),
          Expanded(flex: 2, child: Text('المبلغ', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, color: Color(0xFF62707B)))),
          Expanded(flex: 2, child: Text('الحملة', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, color: Color(0xFF62707B)))),
          Expanded(flex: 2, child: Text('الحالة', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, color: Color(0xFF62707B)))),
        ],
      ),
    );
  }

  Widget _donationRow(Map<String, dynamic> d, NumberFormat fmt, bool showBorder) {
    final status = d['status'] ?? '';
    final isPending = status == 'pending_manual_review' || status == 'pending_payment';
    final isConfirmed = status == 'confirmed';
    final statusColor = isConfirmed ? const Color(0xFF22C55E) : isPending ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
    final statusLabel = isConfirmed ? 'مكتمل' : isPending ? 'انتظار' : status == 'rejected' ? 'مرفوض' : status;
    final createdAt = d['created_at'] != null ? DateTime.tryParse(d['created_at']) : null;
    final dateStr = createdAt != null ? DateFormat('d MMM', 'ar').format(createdAt.toLocal()) : '';

    return GestureDetector(
      onTap: () => context.push('/admin/donation-detail', extra: d),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: showBorder ? const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F8)))) : null,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  _donorAvatar(_donorName(d)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _donorName(d),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                        const SizedBox(height: 2),
                        Text(dateStr, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 10, color: Color(0xFF9CAFB8))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${fmt.format(d['amount'] ?? 0)} ج.س',
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _campaignTitle(d),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, color: Color(0xFF62707B)),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(statusLabel, style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _donorAvatar(String name) {
    final initials = name.length >= 2 ? name.substring(0, 2) : name;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F8),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
      ),
    );
  }
}
