import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Example function: add dummy data
  Future<void> addTestDocument() async {
    await _db.collection('test').add({
      'message': 'Hello Firestore!',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Example function: fetch all test docs
  Stream<QuerySnapshot> getTestDocuments() {
    return _db
        .collection('test')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
