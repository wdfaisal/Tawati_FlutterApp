import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/core/providers.dart';
import 'package:tawati_mobile/src/core/widgets/skeleton.dart';
import 'package:tawati_mobile/src/features/initiatives/models/initiative.dart';
import 'package:tawati_mobile/src/shared/widgets/shared_widgets.dart';

class InitiativesTab extends ConsumerStatefulWidget {
  const InitiativesTab({super.key});

  @override
  ConsumerState<InitiativesTab> createState() => _InitiativesTabState();
}

class _InitiativesTabState extends ConsumerState<InitiativesTab> {
  List<Initiative> _allInitiatives = [];
  bool _loading = true;
  String? _error;
  final Set<String> _registeringIds = {};
  String _selectedFilter = 'الكل';
  final Set<String> _registeredIds = {};

  final List<String> _filters = ['الكل', 'متاحة', 'مسجل'];

  @override
  void initState() {
    super.initState();
    _loadInitiatives();
  }

  Future<void> _loadInitiatives() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final initiatives = await ref.read(initiativeServiceProvider).getInitiatives();
      if (mounted) {
        setState(() {
          _allInitiatives = initiatives;
          _registeredIds.clear();
          for (final init in initiatives) {
            if (init.isRegistered) {
              _registeredIds.add(init.id);
            }
          }
          _loading = false;
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

  List<Initiative> get _filteredInitiatives {
    switch (_selectedFilter) {
      case 'متاحة':
        return _allInitiatives.where((i) => !_registeredIds.contains(i.id) && !i.isFull && !i.isPast).toList();
      case 'مسجل':
        return _allInitiatives.where((i) => _registeredIds.contains(i.id)).toList();
      default:
        return List.from(_allInitiatives);
    }
  }

  List<Initiative> get _availableOnes => _filteredInitiatives.where((i) => !_registeredIds.contains(i.id)).toList();
  List<Initiative> get _registeredOnes => _filteredInitiatives.where((i) => _registeredIds.contains(i.id)).toList();

  Future<void> _toggleRegistration(Initiative initiative) async {
    final id = initiative.id;
    final isRegistered = _registeredIds.contains(id);

    setState(() => _registeringIds.add(id));

    try {
      if (isRegistered) {
        await ref.read(initiativeServiceProvider).unregisterFromInitiative(id);
        if (mounted) {
          setState(() => _registeredIds.remove(id));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إلغاء التسجيل', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
            ),
          );
        }
      } else {
        await ref.read(initiativeServiceProvider).registerForInitiative(id);
        if (mounted) {
          setState(() => _registeredIds.add(id));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم التسجيل بنجاح', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final msg = isRegistered ? 'فشل إلغاء التسجيل: $e' : 'فشل التسجيل: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg, style: const TextStyle(fontFamily: 'IBMPlexSansArabic')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _registeringIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: const Text('المبادرات'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return _buildShimmer();
    if (_error != null) {
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
              onPressed: _loadInitiatives,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }
    if (_allInitiatives.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_outlined, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            const Text(
              'لا توجد مبادرات حالياً',
              style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitiatives,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildFilterChips(),
          ..._buildSections(),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              label: Text(
                filter,
                style: TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.2 : 0.5,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onSelected: (_) {
                setState(() => _selectedFilter = filter);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildSections() {
    final available = _availableOnes;
    final registered = _registeredOnes;
    final List<Widget> sections = [];

    if (available.isNotEmpty) {
      sections.add(const SectionHeader(title: 'المبادرات المتاحة'));
      sections.addAll(available.map((i) => _buildCard(i)));
    }

    if (registered.isNotEmpty) {
      sections.add(const SectionHeader(title: 'المبادرات المسجل فيها'));
      sections.addAll(registered.map((i) => _buildCard(i)));
    }

    if (sections.isEmpty) {
      sections.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
          child: Center(
            child: Text(
              'لا توجد نتائج للفلتر المحدد',
              style: const TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return sections;
  }

  Widget _buildCard(Initiative initiative) {
    return InitiativeCard(
      type: initiative.type,
      title: initiative.title,
      location: initiative.location,
      startDate: initiative.startDate,
      endDate: initiative.endDate,
      participantCount: initiative.participantCount,
      isRegistered: _registeredIds.contains(initiative.id),
      onToggleRegistration: () => _toggleRegistration(initiative),
    );
  }

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: List.generate(4, (_) => skeletonCard()),
    );
  }
}
