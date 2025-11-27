import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ---------------- ADD DRIVER ----------------
  Future<void> addDriver({
    required String name,
    required String phone,
    required String password,
    required int age,
  }) async {
    // Convert name → email-friendly format
    String cleanName = name.trim().replaceAll(" ", "_").toLowerCase();

    // Create driver email
    String driverEmail = "$cleanName@driver.com";

    // 1. Create Firebase Auth account
    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: driverEmail,
      password: password,
    );

    // 2. Save driver details in Firestore
    await _firestore.collection('drivers').doc(cred.user!.uid).set({
      'name': name,
      'phone': phone,
      'age': age,
      'email': driverEmail,
      'uid': cred.user!.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ------------ UPDATE DRIVER ----------------
  Future<void> updateDriver(String id, Map<String, dynamic> data) {
    return _firestore.collection('drivers').doc(id).update(data);
  }

  // ------------ DELETE DRIVER ----------------
  Future<void> deleteDriver(String id) async {
    await _firestore.collection('drivers').doc(id).delete();
  }

  // ------------ GET DRIVER LIST ---------------
  Stream<QuerySnapshot> getDrivers() {
    return _firestore.collection('drivers').orderBy('createdAt').snapshots();
  }
}
