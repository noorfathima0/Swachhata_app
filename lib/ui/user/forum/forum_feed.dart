import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swachhata_app/l10n/app_localizations.dart';
import 'post_detail.dart';

class UserForumPage extends StatefulWidget {
  const UserForumPage({super.key});

  @override
  State<UserForumPage> createState() => _UserForumPageState();
}

class _UserForumPageState extends State<UserForumPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stores current image index for each post (no rebuilding)
  final Map<String, int> _currentIndex = {};

  // Theme (Blue Modern)
  final Color primaryColor = const Color(0xFF2196F3);
  final Color primaryDark = const Color(0xFF1976D2);
  final LinearGradient primaryGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
  );

  // LIKE feature
  Future<void> _toggleLike(String postId, List likes) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = _firestore.collection("posts").doc(postId);

    await ref.update({
      "likes": likes.contains(user.uid)
          ? FieldValue.arrayRemove([user.uid])
          : FieldValue.arrayUnion([user.uid]),
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          loc.forum,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: primaryGradient),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // STREAM BUILDER
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.forum_rounded,
                    size: 70,
                    color: primaryColor.withOpacity(.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.noPosts,
                    style: TextStyle(color: primaryDark, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.beFirstToShare,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            );
          }

          final posts = snap.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),

            itemBuilder: (context, i) {
              final post = posts[i];
              final data = post.data() as Map<String, dynamic>;

              final media = (data["mediaUrls"] as List?)?.cast<String>() ?? [];
              final likes = data["likes"] ?? [];
              final isLiked = user != null && likes.contains(user.uid);
              final comments = data["commentsCount"] ?? 0;
              final author = data["adminName"] ?? loc.user;
              final profile = data["profileImageUrl"] ?? "";
              final content = data["content"] ?? "";
              final created = (data["createdAt"] as Timestamp?)?.toDate();
              final date = created != null
                  ? DateFormat("dd MMM, hh:mm a").format(created)
                  : loc.unknownDate;

              // ✨ WRAP THE WHOLE CARD — open details anywhere
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PostDetailPage(postId: post.id, postData: data),
                    ),
                  );
                },

                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2D2D2D)
                          : Colors.grey.shade300,
                    ),
                    boxShadow: isDark
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HEADER
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: primaryColor.withOpacity(.15),
                              backgroundImage: profile.isNotEmpty
                                  ? NetworkImage(profile)
                                  : null,
                              child: profile.isEmpty
                                  ? Icon(Icons.person, color: primaryColor)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    author,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    date,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.more_horiz,
                              color: isDark ? Colors.white60 : Colors.grey,
                            ),
                          ],
                        ),
                      ),

                      // IMAGES
                      if (media.isNotEmpty)
                        Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CarouselSlider(
                                options: CarouselOptions(
                                  height: 230,
                                  viewportFraction: 1,
                                  enableInfiniteScroll: false,
                                  autoPlay: media.length > 1,
                                  autoPlayInterval: const Duration(seconds: 4),
                                  onPageChanged: (index, reason) {
                                    _currentIndex[post.id] =
                                        index; // No setState()
                                  },
                                ),
                                items: media.map((url) {
                                  return Container(
                                    width: double.infinity,
                                    color: isDark
                                        ? const Color(0xFF2D2D2D)
                                        : Colors.white,
                                    child: Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 50,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            if (media.length > 1)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  '${(_currentIndex[post.id] ?? 0) + 1}/${media.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                          ],
                        ),

                      // CONTENT
                      if (content.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            content,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontSize: 15,
                              height: 1.45,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                      // ACTION BUTTONS (Like / Comment)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            // ❤️ LIKE BUTTON (tap does NOT trigger parent)
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _toggleLike(post.id, likes),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: isLiked
                                          ? Colors.red.withOpacity(.1)
                                          : Colors.grey.withOpacity(.15),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isLiked
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: isLiked
                                              ? Colors.red
                                              : Colors.grey[700],
                                          size: 22,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${likes.length}',
                                          style: TextStyle(
                                            color: isLiked
                                                ? Colors.red
                                                : Colors.grey[800],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // 💬 COMMENT BUTTON
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PostDetailPage(
                                          postId: post.id,
                                          postData: data,
                                        ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey.withOpacity(.15),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.chat_bubble_outline,
                                          color: primaryColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '$comments',
                                          style: TextStyle(
                                            color: primaryDark,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
