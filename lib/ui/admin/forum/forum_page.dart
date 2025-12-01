import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../services/imgbb_service.dart';
import 'post_details.dart';

class AdminForumPage extends StatefulWidget {
  const AdminForumPage({super.key});

  @override
  State<AdminForumPage> createState() => _AdminForumPageState();
}

class _AdminForumPageState extends State<AdminForumPage> {
  final TextEditingController _contentController = TextEditingController();
  final ImgBBService _imgBB = ImgBBService();
  final List<File> _selectedImages = [];
  bool _isPosting = false;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      final newFiles = pickedFiles.map((e) => File(e.path)).toList();

      if (_selectedImages.length + newFiles.length > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade600,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "You can upload up to 5 images only",
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
      } else {
        setState(() => _selectedImages.addAll(newFiles));
      }
    }
  }

  Future<void> _createPost() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
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
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "No admin user logged in",
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
      return;
    }

    if (_contentController.text.trim().isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "Please add some content or media",
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
      return;
    }

    setState(() => _isPosting = true);

    try {
      // 🧠 Get current user's Firestore data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};
      final String adminName = userData['name'] ?? user.displayName ?? 'Admin';
      final String profileImageUrl =
          userData['profileImageUrl'] ?? ''; // ✅ Get from Firestore

      // 🖼 Upload selected images to ImgBB
      List<String> mediaUrls = [];
      for (final image in _selectedImages) {
        final url = await _imgBB.uploadImage(image);
        mediaUrls.add(url);
      }

      // 📝 Save post with profile image and name
      await FirebaseFirestore.instance.collection('posts').add({
        'content': _contentController.text.trim(),
        'mediaUrls': mediaUrls,
        'adminName': adminName,
        'adminId': user.uid,
        'profileImageUrl': profileImageUrl, // ✅ added field
        'createdAt': FieldValue.serverTimestamp(),
        'likes': [],
        'commentsCount': 0,
      });

      _contentController.clear();
      setState(() {
        _selectedImages.clear();
        _isPosting = false;
      });

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
                  "Post created successfully!",
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
    } catch (e) {
      debugPrint("Post creation failed: $e");
      setState(() => _isPosting = false);
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
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "Error: $e",
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
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Community Forum",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🧱 Create Post Section
          Container(
            margin: EdgeInsets.all(20),
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
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF2C5F2D).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        color: Color(0xFF2C5F2D),
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Create New Post",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _contentController,
                  maxLines: 3,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        "Share updates, announcements, or community news...",
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
                      borderSide: BorderSide(
                        color: Color(0xFF2C5F2D),
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
                SizedBox(height: 16),

                if (_selectedImages.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Selected Images (${_selectedImages.length}/5)",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  margin: EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 6,
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      _selectedImages[index],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => _selectedImages.removeAt(index),
                                    ),
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade600,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 12),
                    ],
                  ),

                Row(
                  children: [
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ElevatedButton.icon(
                        icon: Icon(
                          Icons.photo_library_rounded,
                          color: Color(0xFF2C5F2D),
                          size: 20,
                        ),
                        label: Text(
                          "Add Images",
                          style: TextStyle(
                            color: Color(0xFF2C5F2D),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _pickImages,
                      ),
                    ),
                    SizedBox(width: 12),
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
                      child: ElevatedButton.icon(
                        icon: _isPosting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                        label: Text(
                          _isPosting ? "Posting..." : "Publish Post",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isPosting ? null : _createPost,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 🧱 Posts List Section
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 3,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Loading Posts...",
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
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final posts = snapshot.data!.docs;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: ListView.builder(
                    physics: BouncingScrollPhysics(),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index].data() as Map<String, dynamic>;
                      final postId = posts[index].id;
                      final List<String> mediaUrls =
                          (post['mediaUrls'] as List?)?.cast<String>() ?? [];
                      final hasMedia = mediaUrls.isNotEmpty;
                      final createdAt = (post['createdAt'] as Timestamp?)
                          ?.toDate();
                      final formattedDate = createdAt != null
                          ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt)
                          : 'Unknown Date';

                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        margin: EdgeInsets.only(bottom: 16),
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
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PostDetailPage(postId: postId),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Media or Icon Section
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: hasMedia
                                          ? Colors.transparent
                                          : Colors.blue.shade50,
                                      image: hasMedia
                                          ? DecorationImage(
                                              image: NetworkImage(mediaUrls[0]),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: hasMedia
                                        ? null
                                        : Center(
                                            child: Icon(
                                              Icons.article_rounded,
                                              size: 32,
                                              color: Colors.blue.shade600,
                                            ),
                                          ),
                                  ),
                                  SizedBox(width: 16),

                                  // Content Section
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          post['content'] ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: Colors.grey.shade800,
                                            height: 1.4,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.person_rounded,
                                                color: Colors.blue.shade600,
                                                size: 14,
                                              ),
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              "By ${post['adminName'] ?? 'Admin'}",
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            SizedBox(width: 16),
                                            if (hasMedia)
                                              Container(
                                                padding: EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.purple.shade50,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.photo_library_rounded,
                                                  color: Colors.purple.shade600,
                                                  size: 14,
                                                ),
                                              ),
                                            if (hasMedia) SizedBox(width: 6),
                                            if (hasMedia)
                                              Text(
                                                "${mediaUrls.length} photo${mediaUrls.length > 1 ? 's' : ''}",
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time_rounded,
                                              size: 16,
                                              color: Colors.grey.shade500,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              formattedDate,
                                              style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Spacer(),
                                            Container(
                                              padding: EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                color: Colors.grey.shade600,
                                                size: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.forum_rounded,
                size: 70,
                color: Colors.grey.shade300,
              ),
            ),
            SizedBox(height: 24),
            Text(
              "No Posts Yet",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: 12),
            Text(
              "Be the first to share updates, announcements, or community news.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24),
            Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF2C5F2D), Color(0xFF1E3A1E)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF2C5F2D).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                icon: Icon(Icons.add_rounded, color: Colors.white, size: 20),
                label: Text(
                  "Create First Post",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  // Focus on the text field
                  FocusScope.of(context).requestFocus(FocusNode());
                  Future.delayed(Duration(milliseconds: 100), () {
                    FocusScope.of(context).requestFocus(FocusNode());
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
