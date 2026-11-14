import 'package:flutter/material.dart';
import '../../data/services/chat_service.dart';
import 'chat_screen.dart';

class ChatInboxScreen extends StatefulWidget {
  final String currentUserRole; // 'agent', 'seller', 'buyer'

  const ChatInboxScreen({
    super.key,
    required this.currentUserRole,
  });

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  static const Color primaryCyan = Color(0xFF00C6D4);
  static const Color purpleAccent = Color(0xFF6366F1);
  static const Color darkSlate = Color(0xFF0A0D14);
  static const Color cardDark = Color(0xFF131823);

  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    final list = await _chatService.getConversations();
    if (!mounted) return;
    setState(() {
      _conversations = list;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredConversations {
    if (_searchQuery.trim().isEmpty) return _conversations;
    final q = _searchQuery.toLowerCase();
    return _conversations.where((conv) {
      final name = (conv['participantName'] ?? '').toString().toLowerCase();
      final title = (conv['propertyTitle'] ?? '').toString().toLowerCase();
      final msg = (conv['lastMessage'] ?? '').toString().toLowerCase();
      return name.contains(q) || title.contains(q) || msg.contains(q);
    }).toList();
  }

  String _formatTimestamp(String? isoStr) {
    if (isoStr == null) return '';
    try {
      final dt = DateTime.parse(isoStr);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Color _getRoleColor(String? role) {
    final r = (role ?? '').toLowerCase();
    if (r.contains('agent') || r == 'agt') return primaryCyan;
    if (r.contains('seller') || r == 'sel') return purpleAccent;
    return const Color(0xFF10B981); // buyer
  }

  String _getRoleLabel(String? role) {
    final r = (role ?? '').toLowerCase();
    if (r.contains('agent') || r == 'agt') return 'AGENT';
    if (r.contains('seller') || r == 'sel') return 'SELLER';
    return 'BUYER';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: darkSlate,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Messages & In-App Chats',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: primaryCyan),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            color: darkSlate,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search chats by name or property...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: primaryCyan, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Colors.white60, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          // Conversation List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryCyan))
                : _filteredConversations.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: primaryCyan,
                        onRefresh: _loadConversations,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                          itemCount: _filteredConversations.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final conv = _filteredConversations[index];
                            final participantName = conv['participantName']?.toString() ?? 'User';
                            final propertyTitle = conv['propertyTitle']?.toString() ?? 'Property Inquiry';
                            final lastMsg = conv['lastMessage']?.toString() ?? 'No messages yet';
                            final role = conv['participantRole']?.toString() ?? 'user';
                            final roleColor = _getRoleColor(role);
                            final timestamp = _formatTimestamp(conv['lastMessageTime']?.toString());

                            return Material(
                              color: cardDark,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        propertyId: conv['propertyId']?.toString() ?? '',
                                        propertyTitle: propertyTitle,
                                        recipientId: conv['participantId']?.toString() ?? '',
                                        recipientName: participantName,
                                        recipientRole: role,
                                        currentUserRole: widget.currentUserRole,
                                      ),
                                    ),
                                  );
                                  _loadConversations();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: roleColor.withValues(alpha: 0.2),
                                        child: Text(
                                          participantName.isNotEmpty ? participantName[0].toUpperCase() : 'U',
                                          style: TextStyle(
                                            color: roleColor,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
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
                                                    participantName,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 15,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: roleColor.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    _getRoleLabel(role),
                                                    style: TextStyle(
                                                      color: roleColor,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  timestamp,
                                                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              propertyTitle,
                                              style: TextStyle(
                                                color: primaryCyan.withValues(alpha: 0.85),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              lastMsg,
                                              style: const TextStyle(
                                                color: Colors.white60,
                                                fontSize: 13,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white24),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: primaryCyan.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: primaryCyan, size: 48),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Message Threads Yet',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No conversations match "$_searchQuery".'
                  : 'Direct chats initiated with realtors, sellers, or buyers will be organized here.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
