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
  // Driver theme colors (same as dashboard)
  final Color primaryColor = const Color(0xFFFF9800);
  final Color primaryDark = const Color(0xFFF57C00);
  final LinearGradient primaryGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
  );

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
        SnackBar(
          content: const Text("Service Completed Successfully!"),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Exit Service?"),
            content: const Text("Service will be auto-completed. Continue?"),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: isDarkMode
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            contentTextStyle: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Exit",
                  style: TextStyle(color: Colors.white),
                ),
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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDarkMode
        ? const Color(0xFF121212)
        : const Color(0xFFF5F7FA);

    final String vehicleType = (widget.vehicleData['type'] ?? "").toString();
    final String vehicleNumber = (widget.vehicleData['number'] ?? "")
        .toString();

    return WillPopScope(
      onWillPop: _confirmExit,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Active Service",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "${_formatVehicleType(vehicleType)} • $vehicleNumber",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: isDarkMode ? Colors.white : Colors.black,
          automaticallyImplyLeading: false,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close_rounded, size: 22),
                tooltip: "Exit",
                onPressed: () => _confirmExit().then((exit) {
                  if (exit && mounted) Navigator.pop(context);
                }),
                color: Colors.red,
              ),
            ),
          ],
        ),
        body: _loadingRoute
            ? _buildLoadingUI(isDarkMode)
            : widget.vehicleData['routeType'] == "jcb_stops"
            ? _buildJCBStopsUI(isDarkMode)
            : widget.vehicleData['routeType'] == "manual"
            ? _buildManualRouteUI(isDarkMode)
            : _routeError != null
            ? _buildErrorUI(_routeError!, isDarkMode)
            : _buildMapUI(isDarkMode),
        bottomNavigationBar: _buildBottomBar(isDarkMode),
      ),
    );
  }

  Widget _buildLoadingUI(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            "Loading route...",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Preparing your navigation",
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white60 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorUI(String error, bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.red.shade400,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Route Error",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text("Back to Dashboard"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Manual Route UI
  Widget _buildManualRouteUI(bool isDarkMode) {
    final manual = widget.vehicleData['manualRoute'] ?? {};
    final stops = List<String>.from(manual['stops'] ?? []);

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.route_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Manual Route",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Follow the route instructions below",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Route Details Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isDarkMode
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
              border: Border.all(
                color: isDarkMode
                    ? const Color(0xFF2D2D2D)
                    : const Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Start Point
                _buildRoutePointCard(
                  icon: Icons.play_arrow_rounded,
                  title: "Start Point",
                  address: manual['start']?.toString() ?? "Not specified",
                  color: Colors.green,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 16),

                // Stops (if any)
                if (stops.isNotEmpty) ...[
                  Text(
                    "Stops (${stops.length})",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...stops.asMap().entries.map((entry) {
                    return _buildStopItem(
                      index: entry.key + 1,
                      stop: entry.value,
                      isDarkMode: isDarkMode,
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                ],

                // End Point
                _buildRoutePointCard(
                  icon: Icons.flag_rounded,
                  title: "Destination",
                  address: manual['end']?.toString() ?? "Not specified",
                  color: Colors.red,
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),

          // Stats Card
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDarkMode
                    ? const Color(0xFF2D2D2D)
                    : const Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.timer_rounded,
                  label: "Duration",
                  value: _calculateDuration(),
                  isDarkMode: isDarkMode,
                ),
                _buildStatItem(
                  icon: Icons.directions_car_rounded,
                  label: "Distance",
                  value: "${totalDistanceKm.toStringAsFixed(2)} km",
                  isDarkMode: isDarkMode,
                ),
                _buildStatItem(
                  icon: Icons.location_on_rounded,
                  label: "Tracking",
                  value: "Live",
                  isDarkMode: isDarkMode,
                  isLive: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // 🔹 JCB Stops UI
  Widget _buildJCBStopsUI(bool isDarkMode) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.orange, Colors.deepOrange],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.construction_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "JCB Service Route",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Complete ${jcbStops.length} service stops",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${completedStops.length}/${jcbStops.length}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Stops List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: jcbStops.asMap().entries.map((entry) {
                final index = entry.key;
                final stop = entry.value;
                final isCompleted = completedStops.contains(stop);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDarkMode
                          ? const Color(0xFF2D2D2D)
                          : const Color(0xFFE0E0E0),
                    ),
                    boxShadow: isDarkMode
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isCompleted
                                  ? Colors.green.shade800
                                  : Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        stop,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        "Service Stop ${index + 1}",
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      trailing: isCompleted
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "Done",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ElevatedButton(
                              onPressed: () =>
                                  setState(() => completedStops.add(stop)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Mark Done",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Progress Stats
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDarkMode
                    ? const Color(0xFF2D2D2D)
                    : const Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: jcbStops.isEmpty
                      ? 0
                      : completedStops.length / jcbStops.length,
                  backgroundColor: isDarkMode
                      ? Colors.white24
                      : Colors.grey.shade200,
                  color: primaryColor,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Progress",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      "${completedStops.length}/${jcbStops.length} stops",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // 🔹 MAP UI
  Widget _buildMapUI(bool isDarkMode) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _startPoint!, zoom: 14),
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: true,
          onMapCreated: (c) => _mapController = c,
          mapToolbarEnabled: true,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
        ),
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black87 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getVehicleIcon(
                      (widget.vehicleData['type'] ?? "").toString(),
                    ),
                    color: primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Navigation Active",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Following the route in real-time",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        "LIVE",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          right: 20,
          child: FloatingActionButton(
            onPressed: () async {
              final locationData = await _location.getLocation();
              _mapController?.animateCamera(
                CameraUpdate.newLatLng(
                  LatLng(locationData.latitude!, locationData.longitude!),
                ),
              );
            },
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            child: const Icon(Icons.my_location_rounded),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDarkMode
                ? const Color(0xFF2D2D2D)
                : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _completeService,
              icon: const Icon(Icons.stop_circle_rounded, size: 24),
              label: const Text(
                "Complete Service",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              onPressed: () {
                // Show service stats
                showDialog(
                  context: context,
                  builder: (context) => _buildServiceStatsDialog(isDarkMode),
                );
              },
              icon: Icon(
                Icons.analytics_rounded,
                color: primaryColor,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutePointCard({
    required IconData icon,
    required String title,
    required String address,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopItem({
    required int index,
    required String stop,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              stop,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDarkMode,
    bool isLive = false,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isLive
                ? Colors.green.withOpacity(0.1)
                : primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(
            icon,
            color: isLive ? Colors.green : primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isLive
                ? Colors.green
                : isDarkMode
                ? Colors.white
                : Colors.black,
          ),
        ),
      ],
    );
  }

  String _calculateDuration() {
    if (serviceStartTime == null) return "0 min";
    final duration = DateTime.now().difference(serviceStartTime!);
    final minutes = duration.inMinutes;
    if (minutes < 60) return "$minutes min";
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return "$hours h ${remainingMinutes} min";
  }

  Widget _buildServiceStatsDialog(bool isDarkMode) {
    final duration = _calculateDuration();
    final distance = totalDistanceKm.toStringAsFixed(2);
    final stops = widget.vehicleData['routeType'] == "jcb_stops"
        ? "${completedStops.length}/${jcbStops.length}"
        : "0";

    return Dialog(
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.analytics_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Service Statistics",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        "Live tracking metrics",
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildStatRow(
              icon: Icons.timer_rounded,
              label: "Duration",
              value: duration,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              icon: Icons.directions_car_rounded,
              label: "Distance",
              value: "$distance km",
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              icon: widget.vehicleData['routeType'] == "jcb_stops"
                  ? Icons.construction_rounded
                  : Icons.flag_rounded,
              label: widget.vehicleData['routeType'] == "jcb_stops"
                  ? "Stops Completed"
                  : "Route Type",
              value: widget.vehicleData['routeType'] == "jcb_stops"
                  ? stops
                  : _formatRouteType(widget.vehicleData['routeType']),
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Close",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDarkMode,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryColor, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatVehicleType(String type) {
    return type[0].toUpperCase() + type.substring(1);
  }

  String _formatRouteType(String routeType) {
    switch (routeType) {
      case 'manual':
        return 'Manual Route';
      case 'map':
        return 'Map Navigation';
      case 'jcb_stops':
        return 'JCB Stops';
      default:
        return routeType;
    }
  }

  IconData _getVehicleIcon(String type) {
    switch (type.toLowerCase()) {
      case 'auto':
        return Icons.electric_rickshaw_rounded;
      case 'tractor':
        return Icons.local_shipping_rounded;
      case 'tipper':
        return Icons.fire_truck_rounded;
      case 'jcb':
        return Icons.construction_rounded;
      case 'truck':
        return Icons.local_shipping_rounded;
      default:
        return Icons.directions_car_filled_rounded;
    }
  }
}
