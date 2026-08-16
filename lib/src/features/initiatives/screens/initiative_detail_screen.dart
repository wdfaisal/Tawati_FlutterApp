import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/core/providers.dart';
import 'package:tawati_mobile/src/core/widgets/skeleton.dart';
import 'package:tawati_mobile/src/features/initiatives/models/initiative.dart';

class InitiativeDetailScreen extends ConsumerStatefulWidget {
  final String campaignId;

  const InitiativeDetailScreen({super.key, required this.campaignId});

  @override
  ConsumerState<InitiativeDetailScreen> createState() => _InitiativeDetailScreenState();
}

class _InitiativeDetailScreenState extends ConsumerState<InitiativeDetailScreen> {
  Initiative? _initiative;
  bool _loading = true;
  bool _isRegistered = false;
  bool _registering = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final initiative = await ref.read(initiativeServiceProvider).getInitiativeDetail(widget.campaignId);
      if (mounted) {
        setState(() {
          _initiative = initiative;
          _isRegistered = initiative.isRegistered;
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

  Future<void> _toggleRegistration() async {
    final id = widget.campaignId;
    setState(() => _registering = true);
    try {
      if (_isRegistered) {
        await ref.read(initiativeServiceProvider).unregisterFromInitiative(id);
        if (mounted) {
          setState(() => _isRegistered = false);
          _showSnack('تم إلغاء التسجيل', AppColors.success);
        }
      } else {
        await ref.read(initiativeServiceProvider).registerForInitiative(id);
        if (mounted) {
          setState(() => _isRegistered = true);
          _showSnack('تم التسجيل في المبادرة بنجاح', AppColors.success);
        }
      }
    } catch (e) {
      if (mounted) _showSnack('فشلت العملية، حاول مرة أخرى', AppColors.error);
    } finally {
      if (mounted) setState(() => _registering = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'IBMPlexSansArabic')),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
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
        bottomNavigationBar: _initiative != null
            ? _buildBottomCta()
            : null,
      ),
    );
  }

  Widget _buildError() {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'تفاصيل المبادرة',
          style: TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
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

  String _typeLabel(Initiative initiative) {
    switch (initiative.type) {
      case 'distribution':
        return 'توزيع';
      default:
        return 'نشاط';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('dd/MM/yyyy').format(date.toLocal());
  }

  Widget _buildContent() {
    final initiative = _initiative!;
    final fmt = NumberFormat('#,##0');

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(initiative),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildInfoCard(initiative, fmt),
                const SizedBox(height: 16),
                _buildAboutSection(initiative),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(Initiative initiative) {
    final hasImage = initiative.image != null && initiative.image!.isNotEmpty;
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
                    '${initiative.image!.startsWith('http') ? '' : baseUrl}$initiative.image',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildHeroGradient(initiative),
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
                          child: Text(
                            _typeLabel(initiative),
                            style: const TextStyle(
                              fontFamily: 'IBMPlexSansArabic',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          initiative.title,
                          style: const TextStyle(
                            fontFamily: 'IBMPlexSansArabic',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : _buildHeroGradient(initiative),
      ),
    );
  }

  Widget _buildHeroGradient(Initiative initiative) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
              ],
            ),
          ),
        ),
        Positioned(
          top: -60,
          right: -60,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -40,
          left: -40,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          right: 24,
          left: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _typeLabel(initiative),
                  style: const TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                initiative.title,
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(Initiative initiative, NumberFormat fmt) {
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
            children: [
              _buildStatItem(Icons.groups_outlined, 'المشاركون', '${fmt.format(initiative.participantCount)}',
                  initiative.maxParticipants > 0 ? 'من ${fmt.format(initiative.maxParticipants)}' : null),
              const Spacer(),
              _buildStatItem(Icons.event_outlined, 'بداية المبادرة', _formatDate(initiative.startDate), null),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(Icons.event_available_outlined, 'نهاية المبادرة', _formatDate(initiative.endDate), null),
              const Spacer(),
              if (initiative.location != null && initiative.location!.isNotEmpty)
                _buildStatItem(Icons.location_on_outlined, 'الموقع', initiative.location!, null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, String? sub) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
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
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (sub != null)
              Text(
                sub,
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 10,
                  color: AppColors.textHint,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAboutSection(Initiative initiative) {
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
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'عن المبادرة',
                style: TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            initiative.description ?? 'لا يوجد وصف',
            style: const TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.7,
            ),
          ),
          if (initiative.createdByName != null && initiative.createdByName!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'بواسطة: ${initiative.createdByName}',
              style: const TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 12,
                color: AppColors.textHint,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomCta() {
    final initiative = _initiative!;
    final canRegister = initiative.status == 'open' || _isRegistered;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (initiative.isFull && !_isRegistered) ...[
              const Text(
                'المبادرة ممتلئة',
                style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: AppColors.warning),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: (_registering || (!canRegister && !initiative.isFull)) ? null : _toggleRegistration,
                icon: _registering
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Icon(_isRegistered ? Icons.person_remove_outlined : Icons.person_add_alt, size: 20),
                label: Text(
                  _isRegistered ? 'إلغاء التسجيل' : 'سجل في المبادرة',
                  style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRegistered ? AppColors.error : AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
