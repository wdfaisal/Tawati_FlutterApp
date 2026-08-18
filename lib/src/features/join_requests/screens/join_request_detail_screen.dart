import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:go_router/go_router.dart';

import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/features/join_requests/models/join_request.dart';
import 'package:tawati_mobile/src/features/join_requests/services/join_request_service.dart';

final joinRequestDetailProvider = FutureProvider.autoDispose.family<JoinRequest, String>((ref, id) async {
  final service = ref.read(joinRequestServiceProvider);
  return service.getJoinRequestById(id);
});

class JoinRequestDetailScreen extends ConsumerWidget {
  final String requestId;
  final JoinRequest? initialRequest;

  const JoinRequestDetailScreen({
    super.key,
    required this.requestId,
    this.initialRequest,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(joinRequestDetailProvider(requestId));
    final request = requestAsync.valueOrNull ?? initialRequest;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: requestAsync.isLoading && request == null
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : requestAsync.hasError && request == null
                        ? _buildErrorState(context, ref, requestAsync.error.toString())
                        : request != null
                            ? _buildBody(context, ref, request)
                            : const SizedBox.shrink(),
              ),
              if (request != null && request.status == 'pending_review')
                _buildBottomBar(context, ref, request),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F8),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تفاصيل طلب الانضمام',
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'مراجعة بيانات مقدم الطلب',
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

  Widget _buildBody(BuildContext context, WidgetRef ref, JoinRequest request) {
    final dateStr = '${request.createdAt.day.toString().padLeft(2, '0')}/${request.createdAt.month.toString().padLeft(2, '0')}/${request.createdAt.year}';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Person Info Card
          _buildPersonCard(request, dateStr),
          const SizedBox(height: 20),
          // Documents Section
          if (request.documents.isNotEmpty) ...[
            _buildSectionTitle('المستندات المرفقة'),
            const SizedBox(height: 12),
            _buildDocumentsSection(request.documents),
            const SizedBox(height: 20),
          ],
          // Family Members
          if (request.familyMembers.isNotEmpty) ...[
            _buildSectionTitle('أفراد العائلة (${request.familyMembers.length})'),
            const SizedBox(height: 12),
            ...request.familyMembers.map((m) => _buildFamilyMemberCard(m)),
            const SizedBox(height: 20),
          ],
          // Additional Notes
          if (request.reviewNotes != null && request.reviewNotes!.isNotEmpty) ...[
            _buildSectionTitle('ملاحظات المراجعة'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                request.reviewNotes!,
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.8,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          // Help Contact Card
          _buildHelpCard(),
        ],
      ),
    );
  }

  Widget _buildPersonCard(JoinRequest request, String dateStr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, size: 28, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.headFullName,
                      style: const TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
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
          const SizedBox(height: 20),
          const Divider(color: AppColors.border),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.calendar_today_rounded, 'تاريخ التقديم', dateStr),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.phone_rounded, 'رقم الهاتف', request.headPhone),
          if (request.headNationalId != null && request.headNationalId!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.badge_outlined, 'رقم الهوية', request.headNationalId!),
          ],
          if (request.headAge != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.cake_outlined, 'العمر', '${request.headAge} سنة'),
          ],
          if (request.headGender != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.wc_rounded, 'الجنس', request.headGender == 'male' ? 'ذكر' : 'أنثى'),
          ],
          if (request.headMaritalStatus != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.favorite_outline, 'الحالة الاجتماعية', _maritalStatusLabel(request.headMaritalStatus!)),
          ],
          if (request.headSpouseName != null && request.headSpouseName!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.person_outline_rounded, 'اسم الزوج/الزوجة', request.headSpouseName!),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(List<String> documents) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: documents.map((doc) {
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.description_outlined, size: 32, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                doc.split('/').last,
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFamilyMemberCard(FamilyMemberData member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              member.gender == 'male' ? Icons.male_rounded : Icons.female_rounded,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName,
                  style: const TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    member.genderLabel,
                    if (member.age != null) '${member.age} سنة',
                    if (member.maritalStatus != null) _maritalStatusLabel(member.maritalStatus!),
                  ].where((s) => s.isNotEmpty).join(' · '),
                  style: const TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'IBMPlexSansArabic',
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHelpCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.help_outline_rounded, size: 22, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'هل تحتاج مساعدة؟',
                      style: TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'تواصل معنا لأي استفسار',
                      style: TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'رقم التواصل: support@tawati.com',
              style: TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
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

  Widget _buildBottomBar(BuildContext context, WidgetRef ref, JoinRequest request) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(top: BorderSide(color: Color(0xFFF1F5F8))),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _reviewRequest(context, ref, request.id, 'rejected'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'رفض الطلب',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _reviewRequest(context, ref, request.id, 'approved'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'قبول الطلب',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
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
            onTap: () => ref.invalidate(joinRequestDetailProvider(requestId)),
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

  String _maritalStatusLabel(String status) {
    switch (status) {
      case 'single': return 'أعزب';
      case 'married': return 'متزوج';
      case 'divorced': return 'مطلق';
      case 'widowed': return 'أرمل';
      default: return status;
    }
  }

  Future<void> _reviewRequest(BuildContext context, WidgetRef ref, String id, String status) async {
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

    if (confirmed != true || !context.mounted) return;

    try {
      final service = ref.read(joinRequestServiceProvider);
      await service.reviewRequest(id: id, status: status);
      ref.invalidate(joinRequestDetailProvider(id));
      if (context.mounted) {
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
      if (context.mounted) {
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
