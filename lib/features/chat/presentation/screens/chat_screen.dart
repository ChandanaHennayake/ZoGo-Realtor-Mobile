import 'package:flutter/material.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/services/chat_service.dart';
import '../../models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  final String propertyId;
  final String propertyTitle;
  final String recipientId;
  final String recipientName;
  final String? recipientPhone;
  final String recipientRole; // 'buyer' or 'agent'
  final String? currentUserRole; // 'buyer' or 'agent'

  const ChatScreen({
    super.key,
    required this.propertyId,
    required this.propertyTitle,
    required this.recipientId,
    required this.recipientName,
    this.recipientPhone,
    required this.recipientRole,
    this.currentUserRole,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const Color primaryCyan = Color(0xFF00C6D4);
  static const Color darkCyan = Color(0xFF008D97);
  static const Color darkText = Color(0xFF0F172A);

  final ChatService _chatService = ChatService();
  final SecureStorageService _secureStorage = SecureStorageService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String _currentUserId = '';
  String _currentUserName = '';
  late String _currentUserRole;
  late String _conversationId;

  @override
  void initState() {
    super.initState();
    _currentUserRole = widget.currentUserRole ??
        (widget.recipientRole.toLowerCase() == 'buyer' ? 'agent' : 'buyer');
    
    // Conversation is keyed by property + buyer
    final buyerId = _currentUserRole == 'buyer' ? _currentUserId : widget.recipientId;
    _conversationId = ChatService.buildConversationId(widget.propertyId, buyerId);

    _initializeChat();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    final profile = await _secureStorage.getUserProfile();
    _currentUserId = profile['userId'] ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
    _currentUserName = '${profile['firstName'] ?? 'User'} ${profile['lastName'] ?? ''}'.trim();
    if (_currentUserName.isEmpty) {
      _currentUserName = _currentUserRole == 'agent' ? 'Agent' : 'Buyer';
    }

    final buyerId = _currentUserRole == 'buyer' ? _currentUserId : widget.recipientId;
    _conversationId = ChatService.buildConversationId(widget.propertyId, buyerId);

    // Seed initial greeting if chat is empty
    await _chatService.seedInitialGreetingIfEmpty(
      conversationId: _conversationId,
      propertyId: widget.propertyId,
      propertyTitle: widget.propertyTitle,
      agentId: _currentUserRole == 'agent' ? _currentUserId : widget.recipientId,
      agentName: _currentUserRole == 'agent' ? _currentUserName : widget.recipientName,
      buyerId: _currentUserRole == 'buyer' ? _currentUserId : widget.recipientId,
      buyerName: _currentUserRole == 'buyer' ? _currentUserName : widget.recipientName,
    );

    await _loadMessages();
  }

  Future<void> _loadMessages() async {
    final list = await _chatService.getMessages(_conversationId);
    if (!mounted) return;
    setState(() {
      _messages = list;
      _isLoading = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? presetText]) async {
    final text = presetText ?? _textController.text.trim();
    if (text.isEmpty) return;

    if (presetText == null) {
      _textController.clear();
    }

    await _chatService.sendMessage(
      conversationId: _conversationId,
      propertyId: widget.propertyId,
      propertyTitle: widget.propertyTitle,
      senderId: _currentUserId,
      senderName: _currentUserName,
      senderRole: _currentUserRole,
      recipientId: widget.recipientId,
      recipientName: widget.recipientName,
      text: text,
    );

    await _loadMessages();
  }

  List<String> get _quickPrompts {
    if (_currentUserRole == 'agent') {
      return [
        'When would you like to schedule a property visit?',
        'I can share property deed and title verification documents.',
        'The seller is open to reasonable negotiations.',
        'Feel free to call me for more direct inspection details.',
      ];
    } else {
      return [
        'I would like to schedule a visit this weekend.',
        'Is the asking price slightly negotiable?',
        'Could you share the title deed & survey plan?',
        'Can you provide more details about nearby amenities?',
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: darkText, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: widget.recipientRole == 'agent'
                  ? primaryCyan.withValues(alpha: 0.18)
                  : const Color(0xFF3B82F6).withValues(alpha: 0.18),
              child: Icon(
                widget.recipientRole == 'agent'
                    ? Icons.real_estate_agent_rounded
                    : Icons.person_rounded,
                color: widget.recipientRole == 'agent' ? primaryCyan : const Color(0xFF3B82F6),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.recipientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: darkText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: widget.recipientRole == 'agent'
                              ? primaryCyan.withValues(alpha: 0.12)
                              : const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.recipientRole.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: widget.recipientRole == 'agent' ? primaryCyan : const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Row(
                    children: [
                      Icon(Icons.circle, color: Color(0xFF10B981), size: 7),
                      SizedBox(width: 4),
                      Text(
                        'Interested Buyer Chat',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Property Context Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                const Icon(Icons.home_work_outlined, size: 16, color: primaryCyan),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Property: ${widget.propertyTitle}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Message List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryCyan))
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            const Text(
                              'Start your conversation below',
                              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = _messages[i];
                          final isMe = msg.senderRole == _currentUserRole;
                          return _buildMessageBubble(msg, isMe);
                        },
                      ),
          ),

          // Quick Prompt Suggestions Chips
          Container(
            height: 38,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (ctx, idx) {
                final prompt = _quickPrompts[idx];
                return ActionChip(
                  label: Text(
                    prompt,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                  ),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                  onPressed: () => _sendMessage(prompt),
                );
              },
            ),
          ),

          // Bottom Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _textController,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Type message...',
                          hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [primaryCyan, darkCyan]),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    final timeStr =
        '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? primaryCyan : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe ? null : Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              Text(
                msg.senderName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: darkCyan,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              msg.message,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? Colors.white : darkText,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : const Color(0xFF94A3B8),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all_rounded, size: 12, color: Colors.white70),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
