import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../models/chat_message_model.dart';
import '../../services/chat_service.dart';
import '../../services/encryption_service.dart';
import '../../utils/storage_service.dart';
import '../../widgets/chat_avatar.dart';
import '../../widgets/chat_status_ticks.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<dynamic> conversations = [];
  List<dynamic> allUsers = [];
  List<dynamic> filteredUsers = [];
  Map<String, int> unreadCounts = {};
  Map<String, bool> onlineStatusMap = {};
  Map<String, String> userNamesMap = {};
  Map<String, String> userRolesMap = {};

  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool isLoading = true;
  bool hasError = false;
  String errorMessage = "";
  bool isSearchMode = false;
  String searchText = "";
  String myEmail = "";

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> initData() async {
    myEmail = (await StorageService.getUserEmail() ?? "").trim().toLowerCase();
    await loadData();

    if (myEmail.isNotEmpty) {
      _chatService.addMessageListener("chat_screen", (_) => loadData(showLoading: false));
      _chatService.addStatusListener("chat_screen", (_) => loadData(showLoading: false));
      _chatService.addPresenceListener("chat_screen", (presenceJson) {
        try {
          final data = jsonDecode(presenceJson);
          final email = (data["userEmail"]?.toString() ?? "").trim().toLowerCase();
          final status = data["status"]?.toString();
          if (email.isNotEmpty && mounted) {
            setState(() {
              onlineStatusMap[email] = status == "ONLINE";
            });
          }
        } catch (_) {}
      });

      await _chatService.connect(userEmail: myEmail);
    }
  }

  Future<void> loadData({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        isLoading = true;
        hasError = false;
      });
    }

    try {
      await fetchAllUsers();
      await fetchConversations();
      await fetchUnreadCounts();

      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = "Unable to load conversations. Please check your connection.";
        });
      }
    }
  }

  Future<void> fetchConversations() async {
    final token = await StorageService.getToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/chat/conversations"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            conversations = data ?? [];
          });
        }

        // Check presence for each conversation partner
        for (var chat in (data ?? [])) {
          final s = (chat["sender"]?.toString() ?? "").trim().toLowerCase();
          final r = (chat["receiver"]?.toString() ?? "").trim().toLowerCase();
          final other = s == myEmail ? r : s;
          if (other.isNotEmpty) {
            _checkPresence(other);
          }
        }
      } else {
        if (mounted) {
          setState(() {
            conversations = [];
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => conversations = []);
    }
  }

  Future<void> _checkPresence(String email) async {
    final token = await StorageService.getToken();
    if (token == null) return;
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/chat/presence/$email"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            onlineStatusMap[email] = data["online"] == true;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> fetchUnreadCounts() async {
    final token = await StorageService.getToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/chat/unread"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            unreadCounts = Map<String, int>.from(data ?? {});
          });
        }
      }
    } catch (_) {}
  }

  Future<void> fetchAllUsers() async {
    final token = await StorageService.getToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/users"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          final usersList = (data as List)
              .where((user) =>
                  (user['email']?.toString() ?? "").trim().toLowerCase() != myEmail)
              .toList();

          final Map<String, String> names = {};
          final Map<String, String> roles = {};
          for (var u in usersList) {
            final email = (u['email']?.toString() ?? "").trim().toLowerCase();
            final name = (u['name']?.toString() ?? "").trim();
            final role = (u['role']?.toString() ?? "").trim();
            if (email.isNotEmpty && name.isNotEmpty) {
              names[email] = name;
            }
            if (email.isNotEmpty && role.isNotEmpty) {
              roles[email] = role;
            }
          }

          setState(() {
            allUsers = usersList;
            userNamesMap = names;
            userRolesMap = roles;
            if (searchText.isNotEmpty) {
              filterUsers(searchText);
            } else {
              filteredUsers = allUsers;
            }
          });
        }
      }
    } catch (_) {}
  }

  void filterUsers(String value) {
    setState(() {
      searchText = value;
      final query = value.toLowerCase().trim();
      if (query.isEmpty) {
        filteredUsers = allUsers;
      } else {
        filteredUsers = allUsers.where((user) {
          final name = (user['name']?.toString() ?? "").toLowerCase();
          final email = (user['email']?.toString() ?? "").toLowerCase();
          final role = (user['role']?.toString() ?? "").toLowerCase();
          return name.contains(query) || email.contains(query) || role.contains(query);
        }).toList();
      }
    });
  }

  void _openSearch() {
    setState(() {
      isSearchMode = true;
      filteredUsers = allUsers;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _closeSearch() {
    _searchFocusNode.unfocus();
    _searchController.clear();
    setState(() {
      isSearchMode = false;
      searchText = "";
      filteredUsers = allUsers;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    filterUsers("");
  }

  String _formatTimestamp(String timestampStr) {
    if (timestampStr.isEmpty) return "";
    try {
      final dt = DateTime.parse(timestampStr).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dt);

      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? "PM" : "AM";
      final timeStr = "$hour:$minute $period";

      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return timeStr;
      } else if (difference.inDays == 1 || (dt.day == now.day - 1 && dt.month == now.month)) {
        return "Yesterday";
      } else if (difference.inDays < 7) {
        const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
        return days[dt.weekday - 1];
      } else {
        return "${dt.day}/${dt.month}/${dt.year.toString().substring(2)}";
      }
    } catch (_) {
      return "";
    }
  }

  MessageStatus _parseMessageStatus(dynamic statusStr) {
    if (statusStr == "READ") return MessageStatus.read;
    if (statusStr == "DELIVERED") return MessageStatus.delivered;
    return MessageStatus.sent;
  }

  @override
  void dispose() {
    _chatService.removeMessageListener("chat_screen");
    _chatService.removeStatusListener("chat_screen");
    _chatService.removePresenceListener("chat_screen");
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final canPopBack = !isSearchMode && searchText.isEmpty && !_searchFocusNode.hasFocus;

    return PopScope(
      canPop: canPopBack,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Dismiss search mode / clear search text / remove focus
          if (isSearchMode || searchText.isNotEmpty || _searchFocusNode.hasFocus) {
            _closeSearch();
          }
        }
      },
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: isSearchMode ? _buildSearchAppBar(isDark) : _buildNormalAppBar(primaryColor),
        body: isLoading
            ? _buildLoadingState(primaryColor)
            : hasError
                ? _buildErrorState(primaryColor)
                : isSearchMode
                    ? _buildSearchUserList(isDark, primaryColor)
                    : (conversations.isEmpty
                        ? _buildEmptyState(primaryColor)
                        : _buildConversationList(isDark, primaryColor)),
        floatingActionButton: (!isSearchMode && !isLoading && !hasError)
            ? FloatingActionButton(
                onPressed: _openSearch,
                backgroundColor: primaryColor,
                elevation: 3,
                child: const Icon(Icons.chat_rounded, color: Colors.white, size: 22),
              )
            : null,
      ),
    );
  }

  PreferredSizeWidget _buildNormalAppBar(Color primaryColor) {
    return AppBar(
      backgroundColor: primaryColor,
      elevation: 0.5,
      title: const Text(
        "Chats",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 20,
          letterSpacing: 0.2,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Colors.white, size: 23),
          tooltip: "Search users",
          onPressed: _openSearch,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  PreferredSizeWidget _buildSearchAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: isDark ? Colors.white : Colors.black87,
        ),
        onPressed: _closeSearch,
      ),
      titleSpacing: 0,
      title: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: filterUsers,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: "Search name, email, or role...",
          hintStyle: TextStyle(
            color: isDark ? Colors.white54 : Colors.grey.shade500,
            fontSize: 15,
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        ),
      ),
      actions: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: isDark ? Colors.white70 : Colors.grey.shade600,
            ),
            onPressed: _clearSearch,
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildLoadingState(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: primaryColor,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            "Loading conversations...",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Unable to load chats",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => loadData(showLoading: true),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 44,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "No conversations yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Start a conversation with alumni, faculty, or students from your network.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openSearch,
              icon: const Icon(Icons.person_search_rounded, size: 18),
              label: const Text("Start a Chat"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 1,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationList(bool isDark, Color primaryColor) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: conversations.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 0.6,
        indent: 78,
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
      ),
      itemBuilder: (context, index) {
        final chat = conversations[index];
        final sender = (chat["sender"]?.toString() ?? "").trim().toLowerCase();
        final receiver = (chat["receiver"]?.toString() ?? "").trim().toLowerCase();
        final rawContent = chat["content"]?.toString() ?? "";
        final decryptedContent = EncryptionService.decrypt(rawContent, sender, receiver);
        final timestamp = chat["timestamp"]?.toString() ?? "";
        final isMe = sender == myEmail;
        final otherUser = isMe ? receiver : sender;
        final displayName = userNamesMap[otherUser] ?? otherUser;
        final unread = unreadCounts[otherUser] ?? unreadCounts[otherUser.toLowerCase()] ?? 0;
        final isOnline = onlineStatusMap[otherUser] ?? false;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetailScreen(
                  name: displayName,
                  receiverEmail: otherUser,
                ),
              ),
            ).then((_) => loadData(showLoading: false));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                ChatAvatar(
                  name: displayName,
                  radius: 26,
                  isOnline: isOnline,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w600,
                                fontSize: 15.5,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (timestamp.isNotEmpty)
                            Text(
                              _formatTimestamp(timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: unread > 0 ? primaryColor : Colors.grey.shade500,
                                fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (isMe) ...[
                            ChatStatusTicks(
                              status: _parseMessageStatus(chat["status"]),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              decryptedContent.isEmpty ? "Tap to chat" : decryptedContent,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: unread > 0
                                    ? (isDark ? Colors.white70 : const Color(0xFF1E293B))
                                    : (isDark ? Colors.white38 : Colors.grey.shade600),
                                fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                          if (unread > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                unread > 99 ? "99+" : unread.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchUserList(bool isDark, Color primaryColor) {
    if (filteredUsers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_off_rounded,
                size: 40,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                searchText.isEmpty ? "No users available" : "No users found for \"$searchText\"",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: filteredUsers.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 0.6,
        indent: 76,
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
      ),
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        final email = (user["email"]?.toString() ?? "").trim().toLowerCase();
        final name = (user["name"]?.toString() ?? "").trim();
        final role = (user["role"]?.toString() ?? "").trim();
        final isOnline = onlineStatusMap[email] ?? false;
        final displayName = name.isNotEmpty ? name : email;

        return InkWell(
          onTap: () {
            _closeSearch();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetailScreen(
                  name: displayName,
                  receiverEmail: email,
                ),
              ),
            ).then((_) => loadData(showLoading: false));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                ChatAvatar(
                  name: displayName,
                  radius: 24,
                  isOnline: isOnline,
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
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (role.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                role.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
