import 'dart:ui' as ui;
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

  // ------------------ Convert Flutter Icon to BitmapDescriptor ------------------
  Future<BitmapDescriptor> _iconToBitmap(IconData iconData, Color color) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    const double size = 100.0;
    final Paint paint = Paint()..color = Colors.transparent;
    canvas.drawRect(Rect.fromLTWH(0, 0, size, size), paint);

    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: 80,
        fontFamily: iconData.fontFamily,
        color: color,
      ),
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  IconData _getVehicleIcon(String type) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Vehicle Tracking"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("vehicles")
            .where("status", isEqualTo: "running")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            );
          }

          final docs = snapshot.data!.docs;
          Set<Marker> markers = {};

          return FutureBuilder(
            future: Future.wait(
              docs.map((doc) async {
                final data = doc.data() as Map<String, dynamic>;
                final live = data["liveLocation"];

                if (live == null) return null;

                final pos = live["position"];
                if (pos == null) return null;

                final geo = pos as GeoPoint;

                // Build icon
                IconData iconData = _getVehicleIcon(data["type"] ?? "");
                BitmapDescriptor iconBitmap = await _iconToBitmap(
                  iconData,
                  Colors.teal,
                );

                return Marker(
                  markerId: MarkerId(doc.id),
                  position: LatLng(geo.latitude, geo.longitude),
                  icon: iconBitmap,
                  infoWindow: InfoWindow(
                    title: data["number"] ?? "Vehicle",
                    snippet: data["type"] ?? "",
                  ),
                );
              }),
            ),
            builder: (context, markerSnapshots) {
              if (!markerSnapshots.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.teal),
                );
              }

              markers = markerSnapshots.data!
                  .where((m) => m != null)
                  .cast<Marker>()
                  .toSet();

              return GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(12.2958, 76.6394),
                  zoom: 12,
                ),
                markers: markers,
                myLocationEnabled: false,
                mapType: MapType.normal,
                onMapCreated: (c) => _mapController = c,
              );
            },
          );
        },
      ),
    );
  }
}
