import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/core/providers.dart';
import 'package:tawati_mobile/src/core/widgets/skeleton.dart';
import 'package:tawati_mobile/src/core/media_url.dart';
import 'package:tawati_mobile/src/features/auth/providers/auth_provider.dart';
import 'package:tawati_mobile/src/features/groups/models/group.dart';
import 'package:tawati_mobile/src/features/news/models/news.dart';

const Color _kHeaderBorder = Color(0xFFE2E8F0);
const Color _kSoftBg = Color(0xFFF1F5F8);
const Color _kMuted = Color(0xFF9CAFB8);
const Color _kSecondary = Color(0xFF62707B);
const Color _kNameColor = Color(0xFF1A242B);
const Color _kDivider = Color(0xFFF1F5F8);
const Color _kOnlineGreen = Color(0xFF22C55E);

final _groupsNewsProvider = FutureProvider.autoDispose<List<News>>((ref) {
  return ref.read(newsServiceProvider).getNews();
});

class GroupsTab extends ConsumerStatefulWidget {
  const GroupsTab({super.key});

  @override
  ConsumerState<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends ConsumerState<GroupsTab> {
  static const List<String> _tabs = ['الدردشات', 'المناسبات', 'الوفيات', 'الإعلانات'];

  List<Group> _allGroups = [];
  bool _loading = true;
  String? _error;
  final Set<String> _joiningGroupIds = <String>{};
  final Set<String> _joinedRooms = <String>{};
  String? _activeChatGroupId;

  int _tabIndex = 0;
  bool _searchActive = false;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  String? get _currentUserId => ref.read(authProvider).user?.id;

  @override
  void initState() {
    super.initState();
    _setupSocket();
    _loadGroups();
  }

  @override
  void dispose() {
    final socketService = ref.read(socketServiceProvider);
    socketService.offEvent('message:new');
    for (final id in _joinedRooms) {
      socketService.leaveGroup(id);
    }
    _joinedRooms.clear();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _setupSocket() async {
    final socketService = ref.read(socketServiceProvider);
    socketService.offEvent('message:new');
    await socketService.connect();
    socketService.onMessageNew(_handleIncomingMessage);
    _joinMemberRooms();
  }

  void _joinMemberRooms() {
    final socketService = ref.read(socketServiceProvider);
    for (final group in _allGroups.where((g) => g.isMember)) {
      if (!_joinedRooms.contains(group.id)) {
        socketService.joinGroup(group.id);
        _joinedRooms.add(group.id);
      }
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    final message = GroupMessage.fromSocketJson(data);
    if (!mounted) return;
    if (message.senderId == _currentUserId) return;
    if (message.groupId == _activeChatGroupId) return;
    setState(() {
      final idx = _allGroups.indexWhere((g) => g.id == message.groupId);
      if (idx < 0) return;
      final group = _allGroups[idx];
      if (!group.isMember) return;
      _allGroups[idx] = group.copyWith(
        unreadCount: group.unreadCount + 1,
        lastMessage: message.isImage ? 'صورة 📷' : message.content,
        lastMessageAt: message.createdAt,
      );
    });
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
        _joinMemberRooms();
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

  Future<void> _openChat(String groupId, String groupName) async {
    _activeChatGroupId = groupId;
    await context.pushNamed('groupChat', extra: {
      'groupId': groupId,
      'groupName': groupName,
    });
    if (!mounted) return;
    _activeChatGroupId = null;
    final socketService = ref.read(socketServiceProvider);
    socketService.offEvent('message:new');
    socketService.onMessageNew(_handleIncomingMessage);
    _joinMemberRooms();
    await _loadGroups();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            SafeArea(bottom: false, child: _buildHeader()),
            Expanded(child: _buildTabContent()),
          ],
        ),
        floatingActionButton: _tabIndex == 0 && !_searchActive
            ? FloatingActionButton(
                onPressed: _showJoinSheet,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 6,
                highlightElevation: 0,
                shape: const CircleBorder(),
                child: const Icon(Icons.add_rounded, size: 26),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _kHeaderBorder)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 40,
                  child: Image.asset('assets/images/splash_logo.png', fit: BoxFit.contain),
                ),
                _buildSearchButton(),
              ],
            ),
          ),
          _buildTabBar(),
        ],
      ),
    );
  }

  Widget _buildSearchButton() {
    return Material(
      color: _kSoftBg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => setState(() {
          if (_searchActive) {
            _searchController.clear();
            _query = '';
          }
          _searchActive = !_searchActive;
        }),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(_searchActive ? Icons.close_rounded : Icons.search_rounded, size: 19, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Row(
      children: [
        for (var i = 0; i < _tabs.length; i++)
          Expanded(child: _buildTab(i)),
      ],
    );
  }

  Widget _buildTab(int index) {
    final active = index == _tabIndex;
    return InkWell(
      onTap: () => setState(() => _tabIndex = index),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: active ? AppColors.primary : Colors.transparent, width: 2),
          ),
        ),
        child: Text(
          _tabs[index],
          style: TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontSize: 14,
            height: 1.25,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? AppColors.primary : _kMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_loading) return _buildShimmer();
    if (_error != null) return _buildError();
    if (_tabIndex != 0) return _buildNewsTab(_tabIndex);

    final chats = _allGroups.where((g) => g.isMember).toList();
    final query = _query.trim();
    final filtered = query.isEmpty
        ? chats
        : chats.where((g) => g.name.toLowerCase().contains(query.toLowerCase())).toList();

    return Column(
      children: [
        if (_searchActive) _buildSearchField(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadGroups,
            color: AppColors.primary,
            child: filtered.isEmpty
                ? _buildNoChats(
                    query.isEmpty ? 'لا توجد قروبات بعد، اضغط + للانضمام إلى قروب' : 'لا توجد نتائج مطابقة لبحثك')
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _buildChatTile(filtered[index]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewsTab(int index) {
    final newsAsync = ref.watch(_groupsNewsProvider);
    return newsAsync.when(
      loading: () => _buildNewsShimmer(),
      error: (_, _) => _buildNewsError(),
      data: (list) {
        final items = switch (index) {
          1 => list.where((n) => n.isEvent).toList(),
          2 => list.where((n) => n.isDeath).toList(),
          _ => list.where((n) => n.isAnnouncement).toList(),
        };
        if (items.isEmpty) return _buildEmptyTab(index);
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.refresh(_groupsNewsProvider.future),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: items.length,
            itemBuilder: (context, i) => _NewsCard(item: items[i]),
          ),
        );
      },
    );
  }

  Widget _buildNewsShimmer() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kDivider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            skeletonLine(width: 80, height: 14, margin: EdgeInsets.zero),
            const SizedBox(height: 12),
            skeletonLine(height: 14, margin: EdgeInsets.zero),
            const SizedBox(height: 8),
            skeletonLine(width: 180, height: 13, margin: EdgeInsets.zero),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 44, color: _kMuted),
          const SizedBox(height: 14),
          const Text(
            'تعذر تحميل الأخبار',
            style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: _kSecondary),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => ref.refresh(_groupsNewsProvider.future),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: (value) => setState(() => _query = value),
        style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: _kNameColor),
        decoration: InputDecoration(
          hintText: 'ابحث في الدردشات...',
          hintStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: _kMuted),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: _kMuted),
          suffixIcon: GestureDetector(
            onTap: () => setState(() {
              _searchActive = false;
              _searchController.clear();
              _query = '';
            }),
            child: const Icon(Icons.close_rounded, size: 18, color: _kMuted),
          ),
          filled: true,
          fillColor: _kSoftBg,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
          ),
        ),
      ),
    );
  }

  Widget _buildChatTile(Group group) {
    final unread = group.unreadCount;
    final preview = group.lastMessage?.isNotEmpty == true
        ? group.lastMessage!
        : group.description?.isNotEmpty == true
            ? group.description!
            : '${_toArabicDigits('${group.memberCount}')} عضو';

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => _openChat(group.id, group.name),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _kDivider))),
          child: Row(
            children: [
              _buildAvatar(group),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'IBMPlexSansArabic',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _kNameColor,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _formatListTime(group.lastMessageAt ?? group.createdAt),
                          style: TextStyle(
                            fontFamily: 'IBMPlexSansArabic',
                            fontSize: 11,
                            height: 1.5,
                            color: unread > 0 ? AppColors.primary : _kMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'IBMPlexSansArabic',
                              fontSize: 13,
                              height: 1.5,
                              color: unread > 0 ? _kSecondary : _kMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildChatTrailing(group),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatTrailing(Group group) {
    if (group.unreadCount > 0) {
      return Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        child: Text(
          _toArabicDigits(group.unreadCount > 99 ? '99+' : '${group.unreadCount}'),
          style: const TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1,
          ),
        ),
      );
    }
    if (group.messageCount > 0) {
      return const Icon(Icons.done_all_rounded, size: 13, color: _kMuted);
    }
    return const SizedBox(width: 20);
  }

  Widget _buildAvatar(Group group) {
    final image = group.image;
    final showOnline = group.isOnline ||
        (group.lastMessageAt?.isAfter(DateTime.now().subtract(const Duration(minutes: 10))) ?? false);

    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 56,
            height: 56,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(color: _kSoftBg, shape: BoxShape.circle),
            child: (image != null && image.isNotEmpty)
                ? Image.network(
                    resolveMediaUrl(image),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _initialsAvatar(group),
                    loadingBuilder: (context, child, progress) =>
                        progress == null ? child : _initialsAvatar(group),
                  )
                : _initialsAvatar(group),
          ),
          if (showOnline)
            Positioned(
              bottom: 1,
              right: 1,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: _kOnlineGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _initialsAvatar(Group group) {
    return Center(
      child: Text(
        group.name.isNotEmpty ? group.name.trim()[0] : '؟',
        style: const TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildNoChats(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 96, left: 24, right: 24),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: _kSoftBg, shape: BoxShape.circle),
                child: const Icon(Icons.chat_bubble_outline_rounded, size: 30, color: _kMuted),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: _kSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTab(int index) {
    final (IconData icon, String title) = switch (index) {
      1 => (Icons.event_available_outlined, 'لا توجد مناسبات حالياً'),
      2 => (Icons.local_florist_outlined, 'لا توجد وفيات حالياً'),
      _ => (Icons.campaign_outlined, 'لا توجد إعلانات حالياً'),
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: _kSoftBg, shape: BoxShape.circle),
            child: Icon(icon, size: 30, color: _kMuted),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kNameColor,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'ستظهر المحتويات الجديدة هنا',
            style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: _kMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 44, color: _kMuted),
          const SizedBox(height: 14),
          const Text(
            'تعذر تحميل الدردشات',
            style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: _kSecondary),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _loadGroups,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (context, index) => Container(
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _kDivider))),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            skeletonCircle(size: 56),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      skeletonLine(width: 110, height: 14, margin: EdgeInsets.zero),
                      const Spacer(),
                      skeletonLine(width: 44, height: 10, margin: EdgeInsets.zero),
                    ],
                  ),
                  const SizedBox(height: 8),
                  skeletonLine(height: 12, margin: EdgeInsets.zero),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinSheet() {
    final publics = _allGroups.where((g) => !g.isMember).toList();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: publics.isEmpty
            ? Padding(
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(color: _kSoftBg, shape: BoxShape.circle),
                      child: const Icon(Icons.group_add_outlined, size: 28, color: _kMuted),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'لا توجد قروبات متاحة للانضمام حالياً',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: _kSecondary),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
                    child: Text(
                      'قروبات متاحة للانضمام',
                      style: const TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kNameColor,
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: publics.length,
                      itemBuilder: (context, index) => _buildJoinRow(publics[index]),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
      ),
    );
  }

  Widget _buildJoinRow(Group group) {
    final joining = _joiningGroupIds.contains(group.id);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Row(
        children: [
          _buildAvatar(group),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kNameColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_toArabicDigits('${group.memberCount}')} عضو',
                  style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: _kMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (joining)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            )
          else
            GestureDetector(
              onTap: () => _joinFromSheet(group),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
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
            ),
        ],
      ),
    );
  }

  void _joinFromSheet(Group group) {
    Navigator.of(context).pop();
    _joinGroup(group);
  }

  String _formatListTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final diff = today.difference(day).inDays;

    if (diff == 0) {
      final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
      final minute = local.minute.toString().padLeft(2, '0');
      return '${_toArabicDigits('$hour:$minute')} ${local.hour < 12 ? 'ص' : 'م'}';
    }
    if (diff == 1) return 'أمس';
    return _toArabicDigits(DateFormat('dd/MM/yyyy').format(local));
  }

  String _toArabicDigits(String input) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    final buffer = StringBuffer();
    for (final char in input.split('')) {
      final code = char.codeUnitAt(0) - 0x30;
      buffer.write(code >= 0 && code <= 9 ? digits[code] : char);
    }
    return buffer.toString();
  }
}

class _NewsCard extends StatelessWidget {
  final News item;

  const _NewsCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final (label, chipColor) = _labelFor(item);
    final date = _formatNewsDate(item.createdAt);
    return GestureDetector(
      onTap: () => context.push('/news/detail', extra: _newsToMap(item)),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kDivider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: chipColor,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  date,
                  style: const TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 11,
                    color: _kMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              style: const TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _kNameColor,
              ),
            ),
            if (item.content.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 13,
                  color: _kSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

(String, Color) _labelFor(News n) {
  if (n.isDeath) return ('نعي', const Color(0xFF94A3B8));
  if (n.isWedding) return ('عرس', const Color(0xFFF59E0B));
  if (n.isCongratulation) return ('تهنئة', const Color(0xFF0D9488));
  switch (n.type) {
    case 'admin_alert': return ('إعلان إداري', const Color(0xFF0D9488));
    case 'important': return ('إعلان', const Color(0xFFEF4444));
    case 'social_occasion': return ('مناسبة', const Color(0xFFF59E0B));
    default: return ('إعلان', const Color(0xFF3B82F6));
  }
}

String _formatNewsDate(DateTime dt) {
  final d = dt.toLocal();
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  final dateStr = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  final buffer = StringBuffer();
  for (final char in dateStr.split('')) {
    final code = char.codeUnitAt(0) - 0x30;
    buffer.write(code >= 0 && code <= 9 ? digits[code] : char);
  }
  return buffer.toString();
}

Map<String, dynamic> _newsToMap(News n) {
  final d = n.createdAt.toLocal();
  final dateStr = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  return {
    'title': n.title,
    'subtitle': n.subtitle,
    'content': n.content,
    'type': n.type,
    'sub_type': n.subType ?? '',
    'created_at': dateStr,
  };
}
