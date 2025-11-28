import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class DriverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth =
      FirebaseAuth.instance; // still used elsewhere if needed

  // 👉 Replace this with your real Firebase Web API key
  static const String firebaseApiKey =
      'AIzaSyCd_8FbWJatldjP5__2ixP5KftBcSIj-iM';

  // ---------------- ADD DRIVER ----------------
  Future<void> addDriver({
    required String name,
    required String phone,
    required String password,
    required int age,
  }) async {
    // Build driver email from phone (same as before)
    final driverEmail = "$name@driver.com";

    // 1️⃣ Create Firebase Auth user via REST API (does NOT affect current admin login)
    final signUpUrl =
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$firebaseApiKey';

    final signUpResponse = await http.post(
      Uri.parse(signUpUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': driverEmail,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    if (signUpResponse.statusCode != 200) {
      final body = jsonDecode(signUpResponse.body);
      final errorMessage =
          body['error']?['message'] ?? 'Failed to create driver auth user';
      throw Exception(errorMessage);
    }

    final signUpData = jsonDecode(signUpResponse.body);
    final String driverUid = signUpData['localId'];

    // 2️⃣ Save driver document in Firestore
    await _firestore.collection("drivers").doc(driverUid).set({
      "uid": driverUid,
      "name": name,
      "phone": phone,
      "email": driverEmail,
      "password": password,
      "age": age,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  // ---------------- UPDATE DRIVER ----------------
  Future<void> updateDriver(String id, Map<String, dynamic> data) async {
    await _firestore.collection("drivers").doc(id).update(data);
  }

  // ---------------- DELETE DRIVER ----------------
  Future<void> deleteDriver(
    String driverId,
    String driverEmail,
    String driverPassword,
  ) async {
    // 1️⃣ Sign in as driver via REST (no effect on current admin session)
    final signInUrl =
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$firebaseApiKey';

    final signInResponse = await http.post(
      Uri.parse(signInUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': driverEmail,
        'password': driverPassword,
        'returnSecureToken': true,
      }),
    );

    if (signInResponse.statusCode != 200) {
      final body = jsonDecode(signInResponse.body);
      final errorMessage =
          body['error']?['message'] ?? 'Failed to sign in driver for deletion';
      throw Exception(errorMessage);
    }

    final signInData = jsonDecode(signInResponse.body);
    final String idToken = signInData['idToken'];

    // 2️⃣ Delete user from Firebase Auth via REST
    final deleteUrl =
        'https://identitytoolkit.googleapis.com/v1/accounts:delete?key=$firebaseApiKey';

    final deleteResponse = await http.post(
      Uri.parse(deleteUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    if (deleteResponse.statusCode != 200) {
      final body = jsonDecode(deleteResponse.body);
      final errorMessage =
          body['error']?['message'] ?? 'Failed to delete driver auth user';
      throw Exception(errorMessage);
    }

    // 3️⃣ Delete driver document from Firestore
    await _firestore.collection("drivers").doc(driverId).delete();
  }

  // ---------------- GET DRIVERS ----------------
  Stream<QuerySnapshot> getDrivers() {
    return _firestore
        .collection("drivers")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }
}
