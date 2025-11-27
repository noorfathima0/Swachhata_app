import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class RouteFollowPage extends StatefulWidget {
  final String vehicleId;
  final Map<String, dynamic> vehicleData;

  const RouteFollowPage({
    super.key,
    required this.vehicleId,
    required this.vehicleData,
  });

  @override
  State<RouteFollowPage> createState() => _RouteFollowPageState();
}

class _RouteFollowPageState extends State<RouteFollowPage> {
  GoogleMapController? _mapController;
  final Location _location = Location();
  StreamSubscription<LocationData>? _locationSub;

  LatLng? _startPoint;
  LatLng? _endPoint;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // TRACKING VARIABLES
  double totalDistanceKm = 0.0;
  LatLng? lastLocation;
  DateTime? serviceStartTime;

  bool _loadingRoute = true;
  String? _routeError;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    serviceStartTime = DateTime.now();
    await _loadRouteFromVehicleData();
    await _startLiveLocationUpdates();
  }

  // ---------------------------------------------------------------------------
  // 1️⃣ LOAD ROUTE
  // ---------------------------------------------------------------------------
  Future<void> _loadRouteFromVehicleData() async {
    final data = widget.vehicleData;
    final routeType = (data['routeType'] ?? '').toString();

    if (routeType != 'map') {
      setState(() {
        _routeError =
            "This vehicle has a manual route. No map route available.";
        _loadingRoute = false;
      });
      return;
    }

    GeoPoint? start;
    GeoPoint? end;

    if (data['mapRoute'] != null) {
      start = data['mapRoute']['start'];
      end = data['mapRoute']['end'];
    }

    if (start == null && data['routeStart'] != null) {
      start = data['routeStart'];
      end = data['routeEnd'];
    }

    if (start == null || end == null) {
      setState(() {
        _routeError = "No valid route found.";
        _loadingRoute = false;
      });
      return;
    }

    _startPoint = LatLng(start.latitude, start.longitude);
    _endPoint = LatLng(end.latitude, end.longitude);

    _markers = {
      Marker(
        markerId: const MarkerId("start"),
        position: _startPoint!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId("end"),
        position: _endPoint!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    _polylines = {
      Polyline(
        polylineId: const PolylineId("route"),
        points: [_startPoint!, _endPoint!],
        color: Colors.blue,
        width: 5,
      ),
    };

    setState(() => _loadingRoute = false);
  }

  // ---------------------------------------------------------------------------
  // 2️⃣ START GPS TRACKING + FIRESTORE LIVE LOCATION UPDATE + DISTANCE CALCULATION
  // ---------------------------------------------------------------------------
  Future<void> _startLiveLocationUpdates() async {
    bool enabled = await _location.serviceEnabled();
    if (!enabled) enabled = await _location.requestService();

    PermissionStatus permission = await _location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await _location.requestPermission();
    }

    _locationSub = _location.onLocationChanged.listen((loc) {
      if (loc.latitude == null || loc.longitude == null) return;

      LatLng current = LatLng(loc.latitude!, loc.longitude!);

      // CALCULATE DISTANCE TRAVELED
      if (lastLocation != null) {
        totalDistanceKm += _calculateDistance(
          lastLocation!.latitude,
          lastLocation!.longitude,
          current.latitude,
          current.longitude,
        );
      }

      lastLocation = current;

      // UPDATE LIVE LOCATION
      FirebaseFirestore.instance
          .collection("vehicles")
          .doc(widget.vehicleId)
          .update({
            "liveLocation": {
              "position": GeoPoint(loc.latitude!, loc.longitude!),
              "updatedAt": FieldValue.serverTimestamp(),
            },
          });
    });
  }

  // Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // km
    double dLat = _deg2rad(lat2 - lat1);
    double dLon = _deg2rad(lon2 - lon1);
    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * pi / 180;

  // ---------------------------------------------------------------------------
  // 3️⃣ STOP SERVICE + SAVE DISTANCE & TIME
  // ---------------------------------------------------------------------------
  Future<void> _completeService() async {
    _locationSub?.cancel();

    final DateTime endTime = DateTime.now();
    final int durationMinutes = endTime.difference(serviceStartTime!).inMinutes;

    await FirebaseFirestore.instance
        .collection("vehicles")
        .doc(widget.vehicleId)
        .update({
          "status": "completed",
          "service": {
            "startTime": serviceStartTime,
            "endTime": endTime,
            "durationMinutes": durationMinutes,
            "distanceKm": double.parse(totalDistanceKm.toStringAsFixed(2)),
          },
        });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Service Completed Successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 4️⃣ UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Follow Route"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _loadingRoute
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : _routeError != null
          ? Center(
              child: Text(
                _routeError!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _startPoint!,
                zoom: 14,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              onMapCreated: (c) => _mapController = c,
            ),

      // COMPLETE BUTTON
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(14),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            minimumSize: const Size(double.infinity, 55),
          ),
          onPressed: _completeService,
          icon: const Icon(Icons.stop_circle_outlined),
          label: const Text("Complete Service", style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}
