import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/core/providers.dart';
import 'package:tawati_mobile/src/core/widgets/skeleton.dart';
import 'package:tawati_mobile/src/features/auth/providers/auth_provider.dart';
import 'package:tawati_mobile/src/features/groups/models/group.dart';

const _kChatBlue = Color(0xFF1E3A8A);
const _kOnlineGreen = Color(0xFF16A34A);
const _kIncomingBubble = Color(0xFFF1F5F9);
const _kIncomingText = Color(0xFF1E293B);
const _kTimestamp = Color(0xFF94A3B8);
const _kDateText = Color(0xFF64748B);
const _kFieldBg = Color(0xFFF8FAFC);
const _kFieldBorder = Color(0xFFE2E8F0);
const _kNameColor = Color(0xFF1A242B);
const _kSoftBg = Color(0xFFF1F5F8);

const _kApiBase = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.237.182.29:3000/api',
);
final String _kOrigin = _kApiBase.replaceFirst('/api', '');

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
      final currentUserId = _currentUserId;
      setState(() {
        final existingIndex = _messages.indexWhere((m) => m.id == message.id);
        if (existingIndex >= 0) {
          _messages[existingIndex] = message;
          return;
        }
        final optimisticIndex = _messages.indexWhere(
          (m) =>
              m.id.startsWith('local-') &&
              m.senderId == message.senderId &&
              m.content == message.content,
        );
        if (optimisticIndex >= 0) {
          _messages[optimisticIndex] = message;
        } else if (currentUserId == null ||
            currentUserId.isEmpty ||
            message.senderId != currentUserId) {
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
          _messages.removeWhere((m) => m.id == message.id);
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
          _messages.removeWhere((m) => m.id == message.id);
          final idx = _messages.indexWhere((m) => m.id == optimistic.id);
          if (idx >= 0) {
            _messages[idx] = message.copyWith(sendStatus: 'sent');
          } else {
            _messages.add(message.copyWith(sendStatus: 'sent'));
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Column(
          children: [
            _buildHeader(),
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

  Widget _buildHeader() {
    final isMutedLocally = ref.watch(localMutedGroupsProvider).contains(widget.groupId);
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _kFieldBorder)),
      ),
      child: Row(
        children: [
          _HeaderCircleButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          _GroupAvatar(name: widget.groupName),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.groupName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _kNameColor,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'متصل الآن',
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 12,
                    color: _kOnlineGreen,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<_HeaderAction>(
            tooltip: 'المزيد',
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            offset: const Offset(0, 44),
            onSelected: (action) {
              if (action == _HeaderAction.mute) {
                ref.read(localMutedGroupsProvider.notifier).toggle(widget.groupId);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _HeaderAction.mute,
                child: Row(
                  children: [
                    Icon(
                      isMutedLocally ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isMutedLocally ? 'تفعيل الإشعارات' : 'كتم الإشعارات',
                      style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14),
                    ),
                  ],
                ),
              ),
              if (_viewOnly)
                const PopupMenuItem(
                  value: _HeaderAction.none,
                  enabled: false,
                  child: Row(
                    children: [
                      Icon(Icons.visibility_outlined, size: 20, color: AppColors.textHint),
                      SizedBox(width: 10),
                      Text(
                        'وضع العرض فقط',
                        style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14),
                      ),
                    ],
                  ),
                ),
            ],
            child: const _HeaderCircleButton(
              icon: Icons.more_horiz_rounded,
            ),
          ),
        ],
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
              _buildMessageBubble(_messages, index),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _kIncomingBubble,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _formatDate(date),
            style: const TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _kDateText,
            ),
          ),
        ),
      ),
    );
  }

  bool _shouldShowSenderName(GroupMessage message) =>
      message.senderName.trim().isNotEmpty;

  String _resolveImageUrl(String content) {
    if (content.startsWith('http')) return content;
    return '$_kOrigin$content';
  }

  Widget _buildMessageBubble(List<GroupMessage> messages, int index) {
    final message = messages[index];
    final isMine = message.senderId == _currentUserId;
    final timeStr = DateFormat('HH:mm').format(message.createdAt);
    final isFailed = message.sendStatus == 'failed';
    final showSenderName = !isMine && _shouldShowSenderName(message);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSenderName)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, right: 4, left: 4),
              child: Text(
                message.senderName,
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kDateText,
                ),
              ),
            ),
          GestureDetector(
            onLongPress: () => _showReactionPicker(message),
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: message.isImage ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine ? _kChatBlue : _kIncomingBubble,
                borderRadius: isMine
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(4),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      )
                    : const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
              ),
              child: _buildMessageContent(message, isMine),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 4, left: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: isMine ? MainAxisAlignment.start : MainAxisAlignment.end,
              children: [
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 11,
                    color: _kTimestamp,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  if (message.sendStatus == 'pending')
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: _kTimestamp),
                    )
                  else if (isFailed)
                    InkWell(
                      onTap: () => _retryFailedMessage(message),
                      child: const Icon(Icons.error_outline, size: 14, color: AppColors.error),
                    )
                  else
                    const Icon(Icons.done, size: 14, color: _kTimestamp),
                ],
              ],
            ),
          ),
          _buildReactionsRow(message),
        ],
      ),
    );
  }

  Widget _buildMessageContent(GroupMessage message, bool isMine) {
    if (message.isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          _resolveImageUrl(message.content),
          width: 220,
          height: 200,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: 220,
              height: 200,
              color: _kIncomingBubble,
              alignment: Alignment.center,
              child: const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: _kDateText),
              ),
            );
          },
          errorBuilder: (context, error, stack) => Container(
            width: 220,
            height: 200,
            color: _kIncomingBubble,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(12),
            child: Text(
              message.content,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 14,
                color: isMine ? Colors.white : _kIncomingText,
              ),
            ),
          ),
        ),
      );
    }
    return Text(
      message.content,
      style: TextStyle(
        fontFamily: 'IBMPlexSansArabic',
        fontSize: 15,
        color: isMine ? Colors.white : _kIncomingText,
        height: 1.5,
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _kFieldBorder, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: TextField(
                controller: _inputController,
                textDirection: TextDirection.rtl,
                onSubmitted: (_) => _sendMessage(),
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 14,
                  color: _kIncomingText,
                ),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك هنا...',
                  hintStyle: const TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    color: _kTimestamp,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: _kFieldBg,
                  suffixIcon: const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(Icons.attach_file_rounded, color: _kTimestamp, size: 22),
                  ),
                  suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: const BorderSide(color: _kFieldBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: const BorderSide(color: _kFieldBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: const BorderSide(color: _kChatBlue, width: 1.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Semantics(
            label: 'إرسال',
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: _kChatBlue,
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
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
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

enum _HeaderAction { mute, none }

class _HeaderCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _HeaderCircleButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _kSoftBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: _kNameColor, size: 22),
      ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  final String name;

  const _GroupAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => String.fromCharCode(w.runes.first))
        .join('');

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _kIncomingBubble,
              shape: BoxShape.circle,
            ),
            child: Text(
              initials.isEmpty ? 'م' : initials,
              style: const TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kChatBlue,
              ),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
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
}
