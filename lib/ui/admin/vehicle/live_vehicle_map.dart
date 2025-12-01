import 'dart:ui' as ui;
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AdminLiveVehicleTrackingPage extends StatefulWidget {
  const AdminLiveVehicleTrackingPage({super.key});

  @override
  State<AdminLiveVehicleTrackingPage> createState() =>
      _AdminLiveVehicleTrackingPageState();
}

class _AdminLiveVehicleTrackingPageState
    extends State<AdminLiveVehicleTrackingPage> {
  GoogleMapController? _mapController;
  bool _isLoading = true;

  // Cached marker icons so flutter doesn’t rebuild them each frame
  final Map<String, BitmapDescriptor> _cachedIcons = {};

  // ------------------ Convert Icon to BitmapDescriptor ------------------
  Future<BitmapDescriptor> _iconToBitmap(IconData icon, Color color) async {
    final key = "${icon.codePoint}_$color";

    if (_cachedIcons.containsKey(key)) {
      return _cachedIcons[key]!;
    }

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    const double size = 110.0;

    // Shadow circle background
    Paint bg = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(size / 2, size / 2), 55, bg);

    // Draw icon
    TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: 80,
        fontFamily: icon.fontFamily,
        color: color,
        shadows: const [
          Shadow(color: Colors.black26, offset: Offset(3, 3), blurRadius: 6),
        ],
      ),
    );
    tp.layout();
    tp.paint(canvas, Offset((size - tp.width) / 2, (size - tp.height) / 2));

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    final bitmap = BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
    _cachedIcons[key] = bitmap;

    return bitmap;
  }

  IconData _vehicleIcon(String type) {
    switch (type.toLowerCase()) {
      case 'auto':
        return Icons.local_taxi;
      case 'tipper':
        return Icons.local_shipping;
      case 'tractor':
        return Icons.agriculture;
      case 'jcb':
        return Icons.construction;
      default:
        return Icons.directions_car;
    }
  }

  // ----------------------------------------------------------------------
  // UI BUILD
  // ----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      // ----------------- NEW THEMED APP BAR -----------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Live Vehicle Tracking",
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.only(left: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
            color: Colors.grey.shade700,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2C5F2D), Color(0xFF1E3A1E)],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.list_rounded, color: Colors.white),
              onPressed: () => _openVehicleListDrawer(context),
            ),
          ),
        ],
      ),

      body: Stack(
        children: [_buildMapStream(), _loadingOverlay(), _recenterButton()],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // MAP STREAM (LIVE)
  // ----------------------------------------------------------------------

  Widget _buildMapStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("vehicles")
          .where("status", isEqualTo: "running")
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _loadingOverlay();

        final docs = snapshot.data!.docs;

        return FutureBuilder(
          future: _buildMarkers(docs),
          builder: (context, async) {
            if (!async.hasData) return _loadingOverlay();

            final markers = async.data!;

            if (_isLoading) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) setState(() => _isLoading = false);
              });
            }

            return GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(12.2958, 76.6394),
                zoom: 12,
              ),
              markers: markers,
              mapType: MapType.normal,
              onMapCreated: (c) => _mapController = c,
              myLocationButtonEnabled: false,
              compassEnabled: false,
              zoomControlsEnabled: false,
            );
          },
        );
      },
    );
  }

  // ----------------------------------------------------------------------
  // BUILD MARKERS
  // ----------------------------------------------------------------------

  Future<Set<Marker>> _buildMarkers(List<QueryDocumentSnapshot> docs) async {
    final List<Marker?> list = await Future.wait(
      docs.map((doc) async {
        final data = doc.data() as Map<String, dynamic>;
        final live = data["liveLocation"];
        if (live == null || live["position"] == null) return null;

        final GeoPoint geo = live["position"];

        BitmapDescriptor icon = await _iconToBitmap(
          _vehicleIcon(data["type"] ?? ""),
          const Color(0xFF2C5F2D),
        );

        return Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(geo.latitude, geo.longitude),
          icon: icon,
          infoWindow: InfoWindow(
            title: data["number"] ?? "Vehicle",
            snippet: data["type"] ?? "",
          ),
        );
      }),
    );

    return list.where((e) => e != null).cast<Marker>().toSet();
  }

  // ----------------------------------------------------------------------
  // RIGHT DRAWER - VEHICLE LIST
  // ----------------------------------------------------------------------

  void _openVehicleListDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("vehicles")
                .where("status", isEqualTo: "running")
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2C5F2D)),
                );
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Center(child: Text("No running vehicles"));
              }

              return ListView(
                children: [
                  Text(
                    "Running Vehicles",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 20),

                  ...docs.map((v) {
                    final data = v.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(
                          0xFF2C5F2D,
                        ).withOpacity(0.15),
                        child: Icon(
                          _vehicleIcon(data["type"] ?? ""),
                          color: const Color(0xFF2C5F2D),
                        ),
                      ),
                      title: Text(
                        data["number"] ?? "Unknown",
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        data["type"] ?? "",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------------------
  // OVERLAYS & BUTTONS
  // ----------------------------------------------------------------------

  Widget _loadingOverlay() {
    if (!_isLoading) return const SizedBox();

    return Container(
      color: Colors.white.withOpacity(0.7),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF2C5F2D)),
      ),
    );
  }

  Widget _recenterButton() {
    return Positioned(
      bottom: 30,
      right: 30,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2C5F2D), Color(0xFF1E3A1E)],
          ),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.center_focus_strong, color: Colors.white),
          onPressed: () {
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(const LatLng(12.2958, 76.6394), 12),
            );
          },
        ),
      ),
    );
  }
}
