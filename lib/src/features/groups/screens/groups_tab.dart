import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/core/providers.dart';
import 'package:tawati_mobile/src/core/widgets/skeleton.dart';
import 'package:tawati_mobile/src/features/groups/models/group.dart';

class GroupsTab extends ConsumerStatefulWidget {
  const GroupsTab({super.key});

  @override
  ConsumerState<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends ConsumerState<GroupsTab> {
  List<Group> _allGroups = [];
  bool _loading = true;
  String? _error;
  final Set<String> _joiningGroupIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final groups = await ref.read(groupServiceProvider).getGroups();
      if (mounted) {
        setState(() {
          _allGroups = groups;
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

  Future<void> _joinGroup(Group group) async {
    setState(() => _joiningGroupIds.add(group.id));
    try {
      await ref.read(groupServiceProvider).joinGroup(group.id);
      if (!mounted) return;
      setState(() {
        _allGroups = [
          for (final g in _allGroups)
            if (g.id == group.id)
              g.copyWith(
                isMember: true,
                myPermission: 'send_and_view',
                myMemberStatus: 'active',
              )
            else
              g,
        ];
      });
      _openChat(group.id, group.name);
      await _loadGroups();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الانضمام: $e', style: const TextStyle(fontFamily: 'IBMPlexSansArabic')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _joiningGroupIds.remove(group.id));
    }
  }

  void _openChat(String groupId, String groupName) {
    context.pushNamed('groupChat', extra: {
      'groupId': groupId,
      'groupName': groupName,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: const Text('القروبات'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
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
              onPressed: _loadGroups,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    final myGroups = _allGroups.where((g) => g.isMember).toList();
    final publicGroups = _allGroups.where((g) => !g.isMember).toList();

    return RefreshIndicator(
      onRefresh: _loadGroups,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (myGroups.isEmpty && publicGroups.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Column(
                children: [
                  Icon(Icons.group_outlined, size: 48, color: AppColors.textHint),
                  SizedBox(height: 12),
                  Text(
                    'لا توجد قروبات',
                    style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          if (myGroups.isNotEmpty) ...[
            _buildSectionHeader('قروباتي'),
            ...myGroups.map((g) => _buildGroupCard(g, joined: true)),
          ],
          if (publicGroups.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSectionHeader('قروبات متاحة للانضمام'),
            ...publicGroups.map((g) => _buildGroupCard(g, joined: false)),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildGroupCard(Group group, {required bool joined}) {
    final isMutedLocally = ref.watch(localMutedGroupsProvider).contains(group.id);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: joined
            ? () {
                context.pushNamed('groupChat', extra: {
                  'groupId': group.id,
                  'groupName': group.name,
                });
              }
            : () => _joinGroup(group),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  group.name.isNotEmpty ? group.name[0] : '?',
                  style: const TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            style: const TextStyle(
                              fontFamily: 'IBMPlexSansArabic',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (joined && isMutedLocally)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.notifications_off_outlined, size: 15, color: AppColors.textHint),
                          ),
                        if (joined && group.unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              group.unreadCount > 99 ? '99+' : '${group.unreadCount}',
                              style: const TextStyle(
                                fontFamily: 'IBMPlexSansArabic',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.people_outline, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          '${group.memberCount} عضو',
                          style: const TextStyle(
                            fontFamily: 'IBMPlexSansArabic',
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (group.type == 'announcement') ...[
                          const Icon(Icons.campaign_outlined, size: 14, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          const Text(
                            'إعلانات',
                            style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: AppColors.textHint),
                          ),
                        ],
                      ],
                    ),
                    if (group.description != null && group.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        group.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'IBMPlexSansArabic',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (joined)
                const Icon(Icons.chevron_left, color: AppColors.textHint, size: 22)
              else
                _joiningGroupIds.contains(group.id)
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'انضمام',
                          style: TextStyle(
                            fontFamily: 'IBMPlexSansArabic',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: List.generate(5, (_) => skeletonListItem()),
    );
  }
}
