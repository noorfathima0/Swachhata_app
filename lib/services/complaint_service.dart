import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'imgbb_service.dart';

class ComplaintService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _imgBB = ImgBBService();

  /// 🔹 Update complaint status (for admin)
  Future<void> updateComplaintStatus(
    String complaintId,
    String newStatus,
  ) async {
    await _firestore.collection('complaints').doc(complaintId).update({
      'status': newStatus,
    });
  }

  /// 🔹 Submit new complaint
  Future<void> submitComplaint({
    required String type,
    required String description,
    required File image,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final complaintId = const Uuid().v4();

    // ✅ Upload image to ImgBB
    final imageUrl = await _imgBB.uploadImage(image);

    // ✅ Save complaint to Firestore with address included
    await _firestore.collection('complaints').doc(complaintId).set({
      'complaintId': complaintId,
      'userId': user.uid,
      'type': type,
      'description': description,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'address': address, // ✅ full human-readable address
      'status': 'Submitted',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 🔹 Get all complaints for a specific user
  Stream<QuerySnapshot> getUserComplaints(String userId) {
    return _firestore
        .collection('complaints')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// 🔹 Get all complaints (for admin)
  Stream<QuerySnapshot> getAllComplaints() {
    return _firestore
        .collection('complaints')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
