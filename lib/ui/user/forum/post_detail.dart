import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const PostDetailPage({
    super.key,
    required this.postId,
    required this.postData,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _currentImageIndex = 0;

  final Color _primaryColor = Colors.teal;
  final Color _primaryDark = const Color(0xFF00695C);
  final Color _primaryLight = const Color(0xFF4DB6AC);
  final Color _backgroundColor = const Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;

  void _showFullImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  height: 300,
                  color: _primaryLight.withOpacity(0.1),
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addComment() async {
    final user = _auth.currentUser;
    if (user == null || _commentController.text.trim().isEmpty) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    String userName =
        userDoc.data()?['name'] ??
        user.displayName ??
        user.email?.split('@').first ??
        'Anonymous';
    String profileImageUrl = userDoc.data()?['profileImageUrl'] ?? '';

    final commentData = {
      'userId': user.uid,
      'userName': userName,
      'userProfileUrl': profileImageUrl,
      'text': _commentController.text.trim(),
      'createdAt': Timestamp.now(),
    };

    await _firestore
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add(commentData);

    await _firestore.collection('posts').doc(widget.postId).update({
      'commentsCount': FieldValue.increment(1),
    });

    _commentController.clear();
  }

  Future<void> _toggleLike(List<dynamic> likes) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final postRef = _firestore.collection('posts').doc(widget.postId);
    if (likes.contains(user.uid)) {
      await postRef.update({
        'likes': FieldValue.arrayRemove([user.uid]),
      });
    } else {
      await postRef.update({
        'likes': FieldValue.arrayUnion([user.uid]),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Post Details",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('posts').doc(widget.postId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: _primaryColor),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List<String> mediaUrls =
              (data['mediaUrls'] as List?)?.cast<String>() ?? [];
          final List<dynamic> likes = data['likes'] is List
              ? data['likes'] as List
              : [];
          final bool isLiked = user != null && likes.contains(user.uid);
          final adminName = data['adminName'] ?? 'Admin';
          final content = data['content'] ?? '';
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          final formattedDate = createdAt != null
              ? DateFormat('dd MMM, hh:mm a').format(createdAt)
              : 'Unknown date';
          final profileImageUrl = data['profileImageUrl'] ?? '';

          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    // 🖼️ Post Images
                    if (mediaUrls.isNotEmpty)
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 320,
                          enlargeCenterPage: true,
                          enableInfiniteScroll: false,
                          viewportFraction: 1,
                          onPageChanged: (i, _) =>
                              setState(() => _currentImageIndex = i),
                        ),
                        items: mediaUrls.map((url) {
                          return GestureDetector(
                            onTap: () => _showFullImageDialog(context, url),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                url,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image, size: 80),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    // 👤 Post Info
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _primaryLight,
                        backgroundImage: profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl)
                            : null,
                        child: profileImageUrl.isEmpty
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      title: Text(
                        adminName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _primaryDark,
                        ),
                      ),
                      subtitle: Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                    // 📝 Post Content
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        content,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    // ❤️ Likes
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : _primaryColor,
                          ),
                          onPressed: user == null
                              ? null
                              : () => _toggleLike(likes),
                        ),
                        Text(
                          "${likes.length} likes",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),

                    const Divider(),

                    // 💬 Comments Section
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        "Comments",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('posts')
                          .doc(widget.postId)
                          .collection('comments')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final comments = snapshot.data!.docs;
                        if (comments.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text("No comments yet."),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment =
                                comments[index].data() as Map<String, dynamic>;
                            final createdAt =
                                (comment['createdAt'] as Timestamp?)?.toDate();
                            final formattedDate = createdAt != null
                                ? DateFormat(
                                    'dd MMM, hh:mm a',
                                  ).format(createdAt)
                                : '';
                            final userProfileUrl =
                                comment['userProfileUrl'] ?? '';

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _primaryLight,
                                backgroundImage: userProfileUrl.isNotEmpty
                                    ? NetworkImage(userProfileUrl)
                                    : null,
                                child: userProfileUrl.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              title: Text(
                                comment['userName'] ?? 'Anonymous',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _primaryDark,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(comment['text'] ?? ''),
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // ✍️ Comment Input
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: "Add a comment...",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send, color: _primaryColor),
                        onPressed: _addComment,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
