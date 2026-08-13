import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/core/providers.dart';
import 'package:tawati_mobile/src/core/socket_service.dart';
import 'package:tawati_mobile/src/core/widgets/skeleton.dart';
import 'package:tawati_mobile/src/features/auth/providers/auth_provider.dart';
import 'package:tawati_mobile/src/features/groups/models/group.dart';

class GroupChatScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  List<GroupMessage> _messages = [];
  bool _loading = true;
  String? _error;
  bool _sending = false;
  String? _myPermission;
  bool _viewOnly = false;
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  int _sendRetryCounter = 0;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _connectSocket();
  }

  @override
  void dispose() {
    final socketService = ref.read(socketServiceProvider);
    socketService.offEvent('message:new');
    socketService.offEvent('message:deleted');
    socketService.offEvent('message:reaction');
    socketService.leaveGroup(widget.groupId);
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _connectSocket() async {
    final socketService = ref.read(socketServiceProvider);
    socketService.offEvent('message:new');
    socketService.offEvent('message:deleted');
    socketService.offEvent('message:reaction');

    await socketService.connect();

    socketService.onMessageNew((data) {
      final message = GroupMessage.fromSocketJson(data);
      if (message.groupId != widget.groupId) return;
      if (!mounted) return;
      setState(() {
        final existingIndex = _messages.indexWhere((m) => m.id == message.id);
        if (existingIndex >= 0) {
          _messages[existingIndex] = message;
          return;
        }
        final optimisticIndex = _messages.indexWhere(
          (m) =>
              m.senderId == message.senderId &&
              m.content == message.content &&
              m.sendStatus != 'sent' &&
              message.createdAt.difference(m.createdAt).abs().inMinutes <= 2,
        );
        if (optimisticIndex >= 0) {
          _messages[optimisticIndex] = message;
        } else {
          _messages.add(message);
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });

    socketService.onMessageDeleted((messageId) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.id == messageId);
      });
    });

    socketService.onMessageReaction((data) {
      final message = GroupMessage.fromSocketJson(data);
      if (message.groupId != widget.groupId) return;
      if (!mounted) return;
      setState(() {
        final existingIndex = _messages.indexWhere((m) => m.id == message.id);
        if (existingIndex >= 0) {
          _messages[existingIndex] = message;
        }
      });
    });

    socketService.joinGroup(widget.groupId);
  }

  String? get _currentUserId => ref.read(authProvider).user?.id;

  Future<void> _loadMessages() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(groupServiceProvider).getMessages(widget.groupId);
      if (mounted) {
        setState(() {
          _messages = result.messages;
          _myPermission = result.myPermission;
          _viewOnly = result.myPermission == 'view_only' || result.myMemberStatus == 'muted';
          _loading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        ref.read(groupServiceProvider).markGroupRead(widget.groupId);
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final content = _inputController.text.trim();
    if (content.isEmpty || _sending) return;

    setState(() => _sending = true);
    _inputController.clear();

    final optimistic = GroupMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      groupId: widget.groupId,
      senderId: _currentUserId ?? '',
      senderName: ref.read(authProvider).user?.fullNameAr ?? '',
      content: content,
      type: 'text',
      createdAt: DateTime.now(),
      sendStatus: 'pending',
    );

    setState(() => _messages.add(optimistic));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    bool delivered = false;
    try {
      final message = await ref.read(groupServiceProvider).sendMessage(widget.groupId, content);
      delivered = true;
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == optimistic.id);
          if (idx >= 0) {
            _messages[idx] = message.copyWith(sendStatus: 'sent');
          } else {
            _messages.add(message.copyWith(sendStatus: 'sent'));
          }
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == optimistic.id);
          if (idx >= 0) {
            _messages[idx] = optimistic.copyWith(sendStatus: 'failed');
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الإرسال، سيتم إعادة المحاولة تلقائياً', style: const TextStyle(fontFamily: 'IBMPlexSansArabic')),
            backgroundColor: AppColors.error,
          ),
        );
        _scheduleRetry(optimistic, content);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
      if (delivered) {
        ref.read(groupServiceProvider).markGroupRead(widget.groupId);
      }
    }
  }

  void _scheduleRetry(GroupMessage optimistic, String content) {
    if (!mounted) return;
    final attempt = _sendRetryCounter;
    Future.delayed(Duration(seconds: 5 * (attempt + 1)), () async {
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == optimistic.id);
        if (idx >= 0) _messages[idx] = optimistic.copyWith(sendStatus: 'pending');
      });
      try {
        final message = await ref.read(groupServiceProvider).sendMessage(widget.groupId, content);
        if (!mounted) return;
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == optimistic.id);
          if (idx >= 0) {
            _messages[idx] = message.copyWith(sendStatus: 'sent');
          }
        });
      } catch (_) {
        _sendRetryCounter = attempt + 1;
        _scheduleRetry(optimistic, content);
      }
    });
  }

  void _retryFailedMessage(GroupMessage message) {
    _scheduleRetry(message, message.content);
  }

  static const _reactionEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  List<MessageReaction> _computeReactions(
    List<MessageReaction> current,
    String? userId,
    String emoji,
  ) {
    if (userId == null || userId.isEmpty) return current;
    final hasSame = current.any(
      (r) => r.userId == userId && r.emoji == emoji,
    );
    final list = current.where((r) => r.userId != userId).toList();
    if (!hasSame) {
      list.add(MessageReaction(userId: userId, emoji: emoji));
    }
    return list;
  }

  Future<void> _toggleReaction(GroupMessage message, String emoji) async {
    if (_viewOnly) return;
    final previous = message;
    final optimistic = message.copyWith(
      reactions: _computeReactions(
        message.reactions,
        _currentUserId,
        emoji,
      ),
    );
    setState(() {
      final idx = _messages.indexWhere((m) => m.id == message.id);
      if (idx >= 0) _messages[idx] = optimistic;
    });
    try {
      final server = await ref
          .read(groupServiceProvider)
          .reactToMessage(widget.groupId, message.id, emoji);
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == message.id);
        if (idx >= 0) {
          _messages[idx] = server.copyWith(sendStatus: 'sent');
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == message.id);
        if (idx >= 0) _messages[idx] = previous;
      });
    }
  }

  Future<void> _showReactionPicker(GroupMessage message) async {
    if (_viewOnly) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'اختر رد فعل',
                style: TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _reactionEmojis.map((e) {
                  final reacted = message.reactions.any(
                    (r) => r.userId == _currentUserId && r.emoji == e,
                  );
                  return GestureDetector(
                    onTap: () => Navigator.of(context).pop(e),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: reacted
                            ? AppColors.primaryLight
                            : Colors.transparent,
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 28)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) await _toggleReaction(message, picked);
  }

  Widget _buildReactionsRow(GroupMessage message) {
    if (message.reactions.isEmpty) return const SizedBox.shrink();
    final counts = <String, int>{};
    for (final r in message.reactions) {
      counts[r.emoji] = (counts[r.emoji] ?? 0) + 1;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: counts.entries.map((entry) {
          final reacted = message.reactions.any(
            (r) => r.userId == _currentUserId && r.emoji == entry.key,
          );
          return InkWell(
            onTap: () => _toggleReaction(message, entry.key),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: reacted
                    ? AppColors.primaryLight
                    : const Color(0xFFEDEFF3),
                borderRadius: BorderRadius.circular(12),
                border: reacted
                    ? Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                      )
                    : null,
              ),
              child: Text(
                '${entry.key} ${entry.value}',
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);

    if (msgDate == today) return 'اليوم';
    if (msgDate == yesterday) return 'أمس';
    return DateFormat('d/M/yyyy').format(date);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final isMutedLocally = ref.watch(localMutedGroupsProvider).contains(widget.groupId);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text(widget.groupName),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: [
            IconButton(
              tooltip: isMutedLocally ? 'تفعيل الإشعارات' : 'كتم الإشعارات',
              icon: Icon(
                isMutedLocally ? Icons.notifications_off_outlined : Icons.notifications_none,
                color: AppColors.textPrimary,
              ),
              onPressed: () {
                ref.read(localMutedGroupsProvider.notifier).toggle(widget.groupId);
              },
            ),
            if (_viewOnly)
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Center(
                  child: Icon(Icons.visibility_outlined, size: 20, color: AppColors.textSecondary),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            if (_viewOnly)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFFFFF3CD),
                child: const Text(
                  'هذا القروب للاطلاع فقط، الإرسال غير متاح',
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 12,
                    color: Color(0xFF856404),
                  ),
                ),
              ),
            Expanded(child: _buildBody()),
            if (!_viewOnly) _buildInputBar(),
          ],
        ),
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
              onPressed: _loadMessages,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            const Text(
              'لا توجد رسائل بعد',
              style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMessages,
      color: AppColors.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          final showDateSeparator = index == 0 || !_isSameDay(_messages[index - 1].createdAt, message.createdAt);
          return Column(
            children: [
              if (showDateSeparator) _buildDateSeparator(message.createdAt),
              _buildMessageBubble(message),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDate(date),
            style: const TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(GroupMessage message) {
    final isMine = message.senderId == _currentUserId;
    final timeStr = DateFormat('HH:mm').format(message.createdAt);
    final isFailed = message.sendStatus == 'failed';

    return Align(
      alignment: isMine ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 3),
        child: Column(
          crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, right: 4, left: 4),
                child: Text(
                  message.senderName,
                  style: const TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            GestureDetector(
              onLongPress: () => _showReactionPicker(message),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMine ? AppColors.primaryLight : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMine ? 4 : 16),
                    bottomRight: Radius.circular(isMine ? 16 : 4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.content,
                      style: const TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontFamily: 'IBMPlexSansArabic',
                            fontSize: 10,
                            color: AppColors.textHint,
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 4),
                          if (message.sendStatus == 'pending')
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.textHint),
                            )
                          else if (isFailed)
                            InkWell(
                              onTap: () => _retryFailedMessage(message),
                              child: const Icon(Icons.error_outline, size: 14, color: AppColors.error),
                            )
                          else
                            const Icon(Icons.done, size: 14, color: AppColors.textHint),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _buildReactionsRow(message),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              textDirection: TextDirection.rtl,
              onSubmitted: (_) => _sendMessage(),
              style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14),
              decoration: InputDecoration(
                hintText: 'اكتب رسالتك...',
                hintStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', color: AppColors.textHint, fontSize: 14),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            label: 'إرسال',
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _sending ? null : _sendMessage,
                icon: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: 6,
      itemBuilder: (context, index) {
        final isRight = index % 3 != 0;
        return Align(
          alignment: isRight ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            width: MediaQuery.of(context).size.width * 0.6,
            child: Column(
              crossAxisAlignment: isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isRight)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: skeletonLine(width: 80, height: 12),
                  ),
                skeletonBox(height: 48, borderRadius: 16),
                const SizedBox(height: 4),
                skeletonLine(width: 40, height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}
