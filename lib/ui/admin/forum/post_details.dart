import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;
  const PostDetailPage({super.key, required this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final TextEditingController _editController = TextEditingController();

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_rounded, color: Colors.red.shade600),
            ),
            SizedBox(width: 12),
            Text(
              "Delete Post",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to delete this post? This action cannot be undone.",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
        ),
        actions: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.red.shade600, Colors.red.shade800],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                "Delete",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Post deleted successfully",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _editPost(String content) async {
    _editController.text = content;
    final newContent = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF2C5F2D).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.edit_rounded, color: Color(0xFF2C5F2D)),
            ),
            SizedBox(width: 12),
            Text(
              "Edit Post",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _editController,
              maxLines: 4,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: "Edit post content...",
                hintStyle: TextStyle(color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF2C5F2D), width: 2),
                ),
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF2C5F2D), Color(0xFF1E3A1E)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF2C5F2D).withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () =>
                  Navigator.pop(context, _editController.text.trim()),
              child: Text(
                "Save Changes",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (newContent != null && newContent.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update({'content': newContent});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF27AE60),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Post updated successfully",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId)
        .delete();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.delete_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "Comment deleted",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.85),
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 100,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId);

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Post Details",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2C5F2D), Color(0xFF1E3A1E)],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.edit_rounded, color: Colors.white, size: 20),
              onPressed: () async {
                final snapshot = await postRef.get();
                final post = snapshot.data() as Map<String, dynamic>;
                _editPost(post['content']);
              },
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.red.shade600, Colors.red.shade800],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.delete_rounded, color: Colors.white, size: 20),
              onPressed: _deletePost,
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: postRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2C5F2D), Color(0xFF1E3A1E)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Loading Post...",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            );
          }

          final post = snapshot.data!.data() as Map<String, dynamic>;
          final List mediaUrls = post['mediaUrls'] != null
              ? List<String>.from(post['mediaUrls'])
              : [];
          final List<dynamic> likes = post['likes'] is List
              ? post['likes']
              : [];
          final likeCount = likes.length;
          final createdAt = (post['createdAt'] as Timestamp?)?.toDate();
          final formattedDate = createdAt != null
              ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt)
              : 'Unknown Date';

          return SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🖼 Media Carousel
                if (mediaUrls.isNotEmpty)
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.photo_library_rounded,
                                color: Colors.purple.shade600,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Media Gallery (${mediaUrls.length})",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        CarouselSlider(
                          items: mediaUrls.map((url) {
                            return GestureDetector(
                              onTap: () => _showImageDialog(url),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: Colors.grey.shade100,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.broken_image_rounded,
                                              size: 48,
                                              color: Colors.grey.shade400,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              "Image not available",
                                              style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                ),
                              ),
                            );
                          }).toList(),
                          options: CarouselOptions(
                            height: 280,
                            enableInfiniteScroll: false,
                            enlargeCenterPage: true,
                            viewportFraction: 0.9,
                            autoPlay: true,
                            autoPlayInterval: Duration(seconds: 4),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (mediaUrls.isNotEmpty) SizedBox(height: 20),

                // 📝 Post Content Card
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.article_rounded,
                              color: Colors.blue.shade600,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Post Content",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        post['content'] ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 20),
                      Divider(height: 1, color: Colors.grey.shade200),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.favorite_rounded,
                              color: Colors.red.shade600,
                              size: 18,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "$likeCount like${likeCount != 1 ? 's' : ''}",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(width: 24),
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              color: Colors.green.shade600,
                              size: 18,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            post['adminName'] ?? 'Admin',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.access_time_rounded,
                              color: Colors.orange.shade600,
                              size: 18,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // 💬 Comments Section
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.comment_rounded,
                              color: Colors.purple.shade600,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Comments",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      StreamBuilder<QuerySnapshot>(
                        stream: postRef
                            .collection('comments')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (snapshot.data!.docs.isEmpty) {
                            return Container(
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    "No comments yet",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Be the first to comment on this post",
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Column(
                            children: snapshot.data!.docs.map((commentDoc) {
                              final comment =
                                  commentDoc.data() as Map<String, dynamic>;
                              final commentCreatedAt =
                                  (comment['createdAt'] as Timestamp?)
                                      ?.toDate();
                              final commentFormattedDate =
                                  commentCreatedAt != null
                                  ? DateFormat(
                                      'dd MMM, hh:mm a',
                                    ).format(commentCreatedAt)
                                  : 'Unknown Date';

                              return AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                                margin: EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    contentPadding: EdgeInsets.all(16),
                                    leading: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.person_rounded,
                                        color: Colors.blue.shade600,
                                        size: 20,
                                      ),
                                    ),
                                    title: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          comment['userName'] ?? 'Anonymous',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          commentFormattedDate,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Text(
                                        comment['text'] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.delete_rounded,
                                          color: Colors.red.shade600,
                                          size: 18,
                                        ),
                                        onPressed: () =>
                                            _deleteComment(commentDoc.id),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
