import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swachhata_app/l10n/app_localizations.dart';

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

  /// --- BLUE THEME MATCHING USER FORUM PAGE ---
  final Color primaryColor = const Color(0xFF2196F3);
  final Color primaryDark = const Color(0xFF1976D2);
  final Color primaryLight = const Color(0xFF64B5F6);
  final LinearGradient primaryGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
  );

  final Color backgroundColor = const Color(0xFFF5F7FA);

  // -------------------------------------
  // FULLSCREEN IMAGE DIALOG
  // -------------------------------------
  void _showFullImageDialog(String imageUrl) {
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
                  color: primaryLight.withOpacity(0.1),
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

  // -------------------------------------
  // ADD COMMENT
  // -------------------------------------
  Future<void> _addComment() async {
    final user = _auth.currentUser;
    final loc = AppLocalizations.of(context)!;

    if (user == null || _commentController.text.trim().isEmpty) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    String userName =
        userDoc.data()?['name'] ??
        user.displayName ??
        user.email?.split('@').first ??
        loc.anonymous;

    String profileImageUrl = userDoc.data()?['profileImageUrl'] ?? '';

    final commentData = {
      "userId": user.uid,
      "userName": userName,
      "userProfileUrl": profileImageUrl,
      "text": _commentController.text.trim(),
      "createdAt": Timestamp.now(),
    };

    await _firestore
        .collection("posts")
        .doc(widget.postId)
        .collection("comments")
        .add(commentData);

    await _firestore.collection("posts").doc(widget.postId).update({
      'commentsCount': FieldValue.increment(1),
    });

    _commentController.clear();
  }

  // -------------------------------------
  // LIKE / UNLIKE
  // -------------------------------------
  Future<void> _toggleLike(List likes) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = _firestore.collection("posts").doc(widget.postId);

    if (likes.contains(user.uid)) {
      await ref.update({
        "likes": FieldValue.arrayRemove([user.uid]),
      });
    } else {
      await ref.update({
        "likes": FieldValue.arrayUnion([user.uid]),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          loc.postDetails,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: primaryGradient),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // -------------------------------------
      // POST STREAM
      // -------------------------------------
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection("posts").doc(widget.postId).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          final data = snap.data!.data() as Map<String, dynamic>;

          final List<String> mediaUrls =
              (data["mediaUrls"] as List?)?.cast<String>() ?? [];
          final List likes = data["likes"] ?? [];
          final bool isLiked =
              _auth.currentUser != null &&
              likes.contains(_auth.currentUser!.uid);

          final String adminName = data["adminName"] ?? loc.user;
          final String content = data["content"] ?? "";
          final String profileImageUrl = data["profileImageUrl"] ?? "";

          final createdAt = (data["createdAt"] as Timestamp?)?.toDate();
          final date = createdAt != null
              ? DateFormat("dd MMM, hh:mm a").format(createdAt)
              : loc.unknownDate;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    // -------------------------------------
                    // IMAGE CAROUSEL
                    // -------------------------------------
                    if (mediaUrls.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CarouselSlider(
                            options: CarouselOptions(
                              height: 300,
                              viewportFraction: 1.0,
                              enlargeCenterPage: false,
                              autoPlay: mediaUrls.length > 1,
                              onPageChanged: (i, _) {
                                setState(() => _currentImageIndex = i);
                              },
                            ),
                            items: mediaUrls.map((url) {
                              return GestureDetector(
                                onTap: () => _showFullImageDialog(url),
                                child: Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.broken_image, size: 80),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                    // Indicator
                    if (mediaUrls.length > 1)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            "${_currentImageIndex + 1}/${mediaUrls.length}",
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                          ),
                        ),
                      ),

                    // -------------------------------------
                    // USER HEADER
                    // -------------------------------------
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primaryLight,
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
                          color: primaryDark,
                        ),
                      ),
                      subtitle: Text(
                        date,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),

                    // -------------------------------------
                    // POST CONTENT
                    // -------------------------------------
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        content,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    // -------------------------------------
                    // LIKES
                    // -------------------------------------
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => _toggleLike(likes),
                            icon: Icon(
                              isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isLiked ? Colors.red : primaryColor,
                              size: 26,
                            ),
                          ),
                          Text(
                            "${likes.length} ${loc.likes}",
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 30),

                    // -------------------------------------
                    // COMMENTS SECTION TITLE
                    // -------------------------------------
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        loc.comments,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: primaryDark,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // -------------------------------------
                    // COMMENTS STREAM
                    // -------------------------------------
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection("posts")
                          .doc(widget.postId)
                          .collection("comments")
                          .orderBy("createdAt", descending: true)
                          .snapshots(),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: primaryColor,
                            ),
                          );
                        }

                        final comments = snap.data!.docs;

                        if (comments.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              loc.noCommentsYet,
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: comments.length,
                          itemBuilder: (_, i) {
                            final c =
                                comments[i].data() as Map<String, dynamic>;
                            final createdAt = (c['createdAt'] as Timestamp?)
                                ?.toDate();
                            final formatted = createdAt != null
                                ? DateFormat(
                                    "dd MMM, hh:mm a",
                                  ).format(createdAt)
                                : "";

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: primaryLight,
                                backgroundImage:
                                    c["userProfileUrl"]?.isNotEmpty == true
                                    ? NetworkImage(c["userProfileUrl"])
                                    : null,
                                child: c["userProfileUrl"] == ""
                                    ? const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              title: Text(
                                c["userName"] ?? loc.anonymous,
                                style: TextStyle(
                                  color: primaryDark,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c["text"] ?? ""),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatted,
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

                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // -------------------------------------
              // COMMENT INPUT
              // -------------------------------------
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: loc.addCommentPlaceholder,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send_rounded, color: primaryColor),
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
