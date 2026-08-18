import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:go_router/go_router.dart';

import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/features/join_requests/models/join_request.dart';
import 'package:tawati_mobile/src/features/join_requests/services/join_request_service.dart';

final joinRequestsProvider = FutureProvider.autoDispose.family<List<JoinRequest>, String?>((ref, status) async {
  final service = ref.read(joinRequestServiceProvider);
  return service.getJoinRequests(status: status, limit: 50);
});

class JoinRequestsTab extends ConsumerStatefulWidget {
  const JoinRequestsTab({super.key});

  @override
  ConsumerState<JoinRequestsTab> createState() => _JoinRequestsTabState();
}

class _JoinRequestsTabState extends ConsumerState<JoinRequestsTab> {
  String _selectedTab = 'pending_review';
  String _searchQuery = '';

  final _tabs = const [
    {'key': 'pending_review', 'label': 'قيد الانتظار'},
    {'key': 'approved', 'label': 'تم القبول'},
    {'key': 'rejected', 'label': 'مرفوضة'},
  ];

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(joinRequestsProvider(_selectedTab));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildFilterTabs(),
              Expanded(
                child: requestsAsync.when(
                  data: (requests) {
                    final filtered = _searchQuery.isEmpty
                        ? requests
                        : requests.where((r) => r.headFullName.contains(_searchQuery) || r.headPhone.contains(_searchQuery)).toList();
                    if (filtered.isEmpty) return _buildEmptyState();
                    return _buildRequestList(filtered);
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (e, _) => _buildErrorState(e.toString()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'طلبات الانضمام',
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'إدارة طلبات انضمام الأعضاء الجدد',
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F8),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded, size: 20, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v.trim()),
          textAlign: TextAlign.right,
          style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'بحث بالاسم أو رقم الهاتف...',
            hintStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: AppColors.textHint),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: _tabs.map((tab) {
          final isActive = _selectedTab == tab['key'];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = tab['key']!),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isActive ? AppColors.primary : AppColors.border),
                ),
                child: Center(
                  child: Text(
                    tab['label']!,
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRequestList(List<JoinRequest> requests) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      itemCount: requests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildRequestCard(requests[index]),
    );
  }

  Widget _buildRequestCard(JoinRequest request) {
    final dateStr = '${request.createdAt.day.toString().padLeft(2, '0')}/${request.createdAt.month.toString().padLeft(2, '0')}/${request.createdAt.year}';

    return GestureDetector(
      onTap: () => context.push('/join-request/${request.id}', extra: request),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline_rounded, size: 22, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.headFullName,
                        style: const TextStyle(
                          fontFamily: 'IBMPlexSansArabic',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.typeLabel,
                        style: const TextStyle(
                          fontFamily: 'IBMPlexSansArabic',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(request.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMetaRow(Icons.calendar_today_rounded, dateStr),
                const SizedBox(width: 16),
                _buildMetaRow(Icons.phone_rounded, request.headPhone),
                if (request.familyMembers.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  _buildMetaRow(Icons.people_outline_rounded, '${request.familyMembers.length} أفراد'),
                ],
              ],
            ),
            if (_selectedTab == 'pending_review') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      label: 'رفض',
                      isReject: true,
                      onTap: () => _reviewRequest(request.id, 'rejected'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      label: 'قبول',
                      isReject: false,
                      onTap: () => _reviewRequest(request.id, 'approved'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'approved':
        color = const Color(0xFF10B981);
        break;
      case 'rejected':
        color = const Color(0xFFEF4444);
        break;
      default:
        color = const Color(0xFFF59E0B);
    }

    final label = status == 'pending_review'
        ? 'قيد الانتظار'
        : status == 'approved'
            ? 'تم القبول'
            : 'مرفوض';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required bool isReject,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isReject ? const Color(0xFFFEF2F2) : AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isReject ? const Color(0xFFEF4444) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F8),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inbox_outlined, size: 32, color: AppColors.textHint),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد طلبات',
            style: TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'لم يتم العثور على طلبات انضمام حالياً',
            style: TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => ref.invalidate(joinRequestsProvider(_selectedTab)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reviewRequest(String id, String status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            status == 'approved' ? 'تأكيد القبول' : 'تأكيد الرفض',
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.bold),
          ),
          content: Text(
            status == 'approved'
                ? 'هل تريد قبول طلب الانضمام هذا؟'
                : 'هل تريد رفض طلب الانضمام هذا؟',
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'IBMPlexSansArabic', color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                status == 'approved' ? 'قبول' : 'رفض',
                style: TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  color: status == 'approved' ? AppColors.primary : const Color(0xFFEF4444),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final service = ref.read(joinRequestServiceProvider);
      await service.reviewRequest(id: id, status: status);
      ref.invalidate(joinRequestsProvider(_selectedTab));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'approved' ? 'تم قبول الطلب بنجاح' : 'تم رفض الطلب',
              style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
            ),
            backgroundColor: status == 'approved' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e', style: const TextStyle(fontFamily: 'IBMPlexSansArabic')),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
