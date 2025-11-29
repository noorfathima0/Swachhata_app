import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleService {
  final CollectionReference _vehicles = FirebaseFirestore.instance.collection(
    'vehicles',
  );
  List<Map<String, dynamic>>? pendingMapPolyline;

  // ADD VEHICLE
  Future<void> addVehicle({
    required String type,
    required String number,
    required String jobType,
    required String routeType,
    Map<String, dynamic>? manualRoute,
    GeoPoint? routeStart,
    GeoPoint? routeEnd,
    required double km,
  }) async {
    await FirebaseFirestore.instance.collection("vehicles").add({
      "type": type,
      "number": number,
      "jobType": jobType,
      "routeType": routeType,
      "manualRoute": manualRoute,
      "mapRoute": {"start": routeStart, "end": routeEnd},
      "km": km,
      "liveLocation": null, // future update from GPS device
      "createdAt": FieldValue.serverTimestamp(),
      'completedAt': FieldValue.serverTimestamp(),
      "mapRoutePoints": pendingMapPolyline,
      });
  }

  // GET ALL VEHICLES
  Stream<QuerySnapshot> getVehicles() {
    return _vehicles.orderBy('createdAt', descending: true).snapshots();
  }

  // UPDATE VEHICLE STATUS (for daily completion tracking)
  Future<void> updateVehicleStatus(String id, bool completed) async {
    await _vehicles.doc(id).update({
      'completedToday': completed,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateVehicle(String id, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance
        .collection('vehicles')
        .doc(id)
        .update(data);
  }

  Future<void> deleteVehicle(String id) async {
    await FirebaseFirestore.instance.collection('vehicles').doc(id).delete();
  }
}
