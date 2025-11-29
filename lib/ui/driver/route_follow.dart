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

  double totalDistanceKm = 0.0;
  LatLng? lastLocation;
  DateTime? serviceStartTime;

  bool _loadingRoute = true;
  String? _routeError;

  List<String> jcbStops = [];
  List<String> completedStops = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _autoCompleteServiceOnExit();
    _locationSub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    serviceStartTime = DateTime.now();
    await _loadRoute();
    await _startTracking();
  }

  // ============================================================
  // 🔥 LOAD ROUTE (MAP + MANUAL + JCB)
  // ============================================================
  Future<void> _loadRoute() async {
    final data = widget.vehicleData;
    final routeType = data['routeType'];

    // JCB
    if (routeType == "jcb_stops") {
      jcbStops = List<String>.from(data['manualRoute']?['stops'] ?? []);
      setState(() => _loadingRoute = false);
      return;
    }

    GeoPoint? start;
    GeoPoint? end;

    // MAP route (primary)
    if (data['mapRoute'] != null) {
      start = data['mapRoute']['start'];
      end = data['mapRoute']['end'];

      // Load polyline path (drawn on map)
      List<dynamic>? points = data['mapRoutePoints'];

      if (points != null && points.isNotEmpty) {
        List<LatLng> polyPoints = points
            .map((p) => LatLng(p['lat'], p['lng']))
            .toList();

        _polylines.add(
          Polyline(
            polylineId: const PolylineId("user_route"),
            points: polyPoints,
            width: 5,
            color: Colors.blue,
          ),
        );
      }
    }

    // FALLBACK for old docs
    start ??= data['routeStart'];
    end ??= data['routeEnd'];

    if (start == null || end == null) {
      _routeError = "No valid route found.";
      setState(() => _loadingRoute = false);
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

    // Add simple line
    if (_polylines.isEmpty) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId("default_route"),
          points: [_startPoint!, _endPoint!],
          width: 5,
          color: Colors.orange,
        ),
      );
    }

    setState(() => _loadingRoute = false);
  }

  // ============================================================
  // 🔥 LOCATION TRACKING
  // ============================================================
  Future<void> _startTracking() async {
    bool enabled = await _location.serviceEnabled();
    if (!enabled) enabled = await _location.requestService();

    var perm = await _location.hasPermission();
    if (perm == PermissionStatus.denied) {
      perm = await _location.requestPermission();
    }

    _locationSub = _location.onLocationChanged.listen((loc) {
      if (loc.latitude == null || loc.longitude == null) return;

      LatLng current = LatLng(loc.latitude!, loc.longitude!);

      if (lastLocation != null) {
        totalDistanceKm += _distance(lastLocation!, current);
      }

      lastLocation = current;

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

  double _distance(LatLng a, LatLng b) {
    const R = 6371;
    double dLat = _rad(b.latitude - a.latitude);
    double dLon = _rad(b.longitude - a.longitude);
    double aa =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(a.latitude)) *
            cos(_rad(b.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return R * 2 * atan2(sqrt(aa), sqrt(1 - aa));
  }

  double _rad(double d) => d * pi / 180;

  // ============================================================
  // 🔥 COMPLETE SERVICE
  // ============================================================
  Future<void> _completeService() async {
    _locationSub?.cancel();

    final end = DateTime.now();
    final duration = end.difference(serviceStartTime!).inMinutes;

    await FirebaseFirestore.instance
        .collection("vehicles")
        .doc(widget.vehicleId)
        .update({
          "status": "completed",
          "service": {
            "startTime": serviceStartTime,
            "endTime": end,
            "durationMinutes": duration,
            "distanceKm": double.parse(totalDistanceKm.toStringAsFixed(2)),
            "completedStops": completedStops,
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

  // ============================================================
  // 🔥 AUTO COMPLETE WHEN EXITING
  // ============================================================
  Future<void> _autoCompleteServiceOnExit() async {
    try {
      final end = DateTime.now();
      final duration = end.difference(serviceStartTime ?? end).inMinutes;

      await FirebaseFirestore.instance
          .collection("vehicles")
          .doc(widget.vehicleId)
          .update({
            "status": "completed",
            "service": {
              "startTime": serviceStartTime ?? end,
              "endTime": end,
              "durationMinutes": duration,
              "distanceKm": double.parse(totalDistanceKm.toStringAsFixed(2)),
              "completedStops": completedStops,
            },
          });
    } catch (_) {}
  }

  Future<bool> _confirmExit() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Exit Service?"),
            content: const Text("Service will be auto-completed. Continue?"),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                child: const Text("Exit"),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ============================================================
  // 🔥 UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _confirmExit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Follow Route"),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),

        body: _loadingRoute
            ? const Center(child: CircularProgressIndicator())
            : widget.vehicleData['routeType'] == "jcb_stops"
            ? _buildJCBStopsUI()
            // ⭐ MANUAL ROUTE → Always show start/end/stops (no map)
            : widget.vehicleData['routeType'] == "manual"
            ? _buildManualRouteUI()
            // ⭐ MAP ROUTE
            : _routeError != null
            ? Center(
                child: Text(
                  _routeError!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            : _buildMapUI(),

        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(14),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 55),
            ),
            onPressed: _completeService,
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text(
              "Complete Service",
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }

  // Manual Route UI
  Widget _buildManualRouteUI() {
    final manual = widget.vehicleData['manualRoute'];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Start: ${manual['start']}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          Text(
            "End: ${manual['end']}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),
          const Text(
            "Stops:",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          ...List<String>.from(
            manual['stops'] ?? [],
          ).map((s) => ListTile(title: Text(s))).toList(),
        ],
      ),
    );
  }

  // 🔹 JCB
  Widget _buildJCBStopsUI() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: jcbStops
          .map(
            (stop) => Card(
              child: ListTile(
                title: Text(stop),
                trailing: completedStops.contains(stop)
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : ElevatedButton(
                        child: const Text("Done"),
                        onPressed: () =>
                            setState(() => completedStops.add(stop)),
                      ),
              ),
            ),
          )
          .toList(),
    );
  }

  // 🔹 MAP
  Widget _buildMapUI() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _startPoint!, zoom: 14),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      onMapCreated: (c) => _mapController = c,
    );
  }
}
