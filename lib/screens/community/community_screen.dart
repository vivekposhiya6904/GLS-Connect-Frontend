import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';
import '../profile/profile_detail_screen.dart';
import 'create_post_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late Future<List<PostModel>?> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = PostService.getAllPosts();
  }

  void _refreshPosts() {
    setState(() {
      _postsFuture = PostService.getAllPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "GLS Community",
          style: TextStyle(
            color: Color(0xFF1A3A8F),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1A3A8F)),
            onPressed: _refreshPosts,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshPosts();
        },
        child: FutureBuilder<List<PostModel>?>(
          future: _postsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text("Failed to load community feed"),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshPosts,
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              );
            }

            final posts = snapshot.data ?? [];

            if (posts.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(
                    child: Text(
                      "No posts in community feed yet.\nBe the first to share something!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return _buildPostCard(post);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPostCard(PostModel post) {
    String timeStr = "Just now";
    if (post.createdAt != null && post.createdAt!.isNotEmpty) {
      try {
        DateTime dt = DateTime.parse(post.createdAt!);
        timeStr = "${dt.day}/${dt.month}/${dt.year}";
      } catch (_) {
        timeStr = post.createdAt!.split('T').first;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3A8F).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _openAuthorProfile(post),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFE0E7FF),
                    child: Text(
                      post.userName.isNotEmpty ? post.userName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _openAuthorProfile(post),
                        child: Text(
                          post.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${post.posterDesignation} • ${post.posterDepartment}",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  timeStr,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Text(
              post.content,
              style: const TextStyle(
                fontSize: 14.5,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                width: double.infinity,
                child: Image.network(
                  "${ApiConfig.baseUrl}${post.imageUrl}",
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ] else
            const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _openAuthorProfile(PostModel post) {
    if (post.userId == 0) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileDetailScreen(
          userId: post.userId,
          userName: post.userName,
          userRole: post.userRole,
        ),
      ),
    );
  }
}
