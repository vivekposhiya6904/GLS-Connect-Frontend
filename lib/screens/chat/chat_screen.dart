import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../utils/storage_service.dart';
import '../../services/encryption_service.dart';
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

  bool isLoading = true;
  String searchText = "";
  String myEmail = "";

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> initData() async {
    myEmail = await StorageService.getUserEmail() ?? "";
    await loadData();
  }

  Future<void> loadData() async {
    await fetchConversations();
    await fetchUnreadCounts();
    await fetchAllUsers();
  }

  // 🔥 Fetch latest conversations
  Future<void> fetchConversations() async {
    final token = await StorageService.getToken();

    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/api/chat/conversations"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        conversations = data ?? [];
        isLoading = false;
      });
    } else {
      setState(() {
        conversations = [];
        isLoading = false;
      });
    }
  }

  // 🔥 Fetch unread counts
  Future<void> fetchUnreadCounts() async {
    final token = await StorageService.getToken();

    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/api/chat/unread"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        unreadCounts =
        Map<String, int>.from(data ?? {});
      });
    }
  }

  // 🔥 Fetch users for search
  Future<void> fetchAllUsers() async {
    final token = await StorageService.getToken();

    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/api/users"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        allUsers = data
            .where((user) => user['email'] != myEmail)
            .toList();
        filteredUsers = allUsers;
      });
    }
  }

  void filterUsers(String value) {
    setState(() {
      searchText = value;

      filteredUsers = allUsers
          .where((user) =>
      user['name']
          .toLowerCase()
          .contains(value.toLowerCase()) ||
          user['email']
              .toLowerCase()
              .contains(value.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Chats",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [

          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              onChanged: filterUsers,
              decoration: InputDecoration(
                hintText: "Search user...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF2F2F2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: searchText.isNotEmpty
                ? buildUserList()
                : buildConversationList(),
          )
        ],
      ),
    );
  }

  // 🔥 WhatsApp Style Conversation List
  Widget buildConversationList() {
    if (conversations.isEmpty) {
      return const Center(child: Text("No conversations yet"));
    }

    return ListView.separated(
      itemCount: conversations.length,
      separatorBuilder: (_, __) =>
      const Divider(height: 0),
      itemBuilder: (context, index) {
        final chat = conversations[index];

        final sender = chat["sender"]?.toString() ?? "";
        final receiver = chat["receiver"]?.toString() ?? "";
        final rawContent = chat["content"]?.toString() ?? "";
        final decryptedContent = EncryptionService.decrypt(rawContent, sender, receiver);
        final timestamp = chat["timestamp"]?.toString() ?? "";

        // Correct other user logic
        final otherUser = sender.toLowerCase() == myEmail.toLowerCase() ? receiver : sender;
        final unread = unreadCounts[otherUser.toLowerCase()] ?? unreadCounts[otherUser] ?? 0;

        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFEAEAEA),
            child: Icon(Icons.person, color: Colors.black),
          ),

          title: Text(
            otherUser,
            style: TextStyle(
              fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),

          subtitle: Text(
            decryptedContent,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          trailing: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [

              if (timestamp.isNotEmpty)
                Text(
                  formatTime(timestamp),
                  style: const TextStyle(
                      fontSize: 12),
                ),

              const SizedBox(height: 5),

              if (unread > 0)
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  width: 22,   // ✅ fixed width
                  height: 22,  // ✅ fixed height
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.black,  // ✅ black instead of green
                    shape: BoxShape.circle,
                  ),
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
          ),

          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ChatDetailScreen(
                      name: otherUser,
                      receiverEmail: otherUser,
                    ),
              ),
            ).then((_) => loadData());
          },
        );
      },
    );
  }

  // 🔍 Search User List
  Widget buildUserList() {
    return ListView.separated(
      itemCount: filteredUsers.length,
      separatorBuilder: (_, __) =>
      const Divider(height: 0),
      itemBuilder: (context, index) {
        final user = filteredUsers[index];

        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFEAEAEA),
            child:
            Icon(Icons.person, color: Colors.black),
          ),
          title: Text(user["name"] ?? ""),
          subtitle: Text(user["email"] ?? ""),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ChatDetailScreen(
                      name: user["name"] ?? "",
                      receiverEmail:
                      user["email"] ?? "",
                    ),
              ),
            ).then((_) => loadData());
          },
        );
      },
    );
  }

  String formatTime(String timestamp) {
    try {
      final date =
      DateTime.parse(timestamp);
      return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "";
    }
  }
}
