import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:swachhata_app/services/vehicle_service.dart';

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({super.key});

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final VehicleService _vehicleService = VehicleService();

  final TextEditingController _numberController = TextEditingController();

  // Manual route controllers
  final TextEditingController _startRouteController = TextEditingController();
  final TextEditingController _endRouteController = TextEditingController();
  final TextEditingController _stopInputController = TextEditingController();
  final TextEditingController _kmController = TextEditingController();

  List<String> _stops = [];

  // Map route geo-points
  GeoPoint? _startPoint;
  GeoPoint? _endPoint;

  String _vehicleType = 'auto';
  String _jobType = 'collection';
  String _routeType = 'manual';

  final List<String> vehicleTypes = ['auto', 'tipper', 'tractor', 'jcb'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Vehicle"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // VEHICLE TYPE
              DropdownButtonFormField(
                value: _vehicleType,
                items: vehicleTypes
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _vehicleType = v!;

                    // Auto + Tipper always collection
                    if (v == "auto" || v == "tipper") {
                      _jobType = "collection";
                    }

                    // JCB Special Mode
                    if (v == "jcb") {
                      _routeType = "jcb_stops"; // disable normal route mode
                      _stops.clear();
                      _startRouteController.clear();
                      _endRouteController.clear();
                      _startPoint = null;
                      _endPoint = null;
                    } else {
                      _routeType = "manual"; // default for others
                    }
                  });
                },
                decoration: _input("Vehicle Type", Icons.directions_car),
              ),
              const SizedBox(height: 16),

              // JOB TYPE (Tractor/JCB only)
              if (_vehicleType == "tractor" || _vehicleType == "jcb")
                DropdownButtonFormField(
                  value: _jobType,
                  items: const [
                    DropdownMenuItem(
                      value: "collection",
                      child: Text("Collection"),
                    ),
                    DropdownMenuItem(
                      value: "sanitation",
                      child: Text("Sanitation"),
                    ),
                  ],
                  onChanged: (v) => setState(() => _jobType = v!),
                  decoration: _input("Work Type", Icons.work),
                ),
              const SizedBox(height: 16),

              // VEHICLE NUMBER
              TextFormField(
                controller: _numberController,
                decoration: _input("Vehicle Number", Icons.confirmation_number),
                validator: (v) => v!.isEmpty ? "Enter vehicle number" : null,
              ),
              const SizedBox(height: 16),

              // ROUTE TYPE — hidden for JCB
              if (_vehicleType != "jcb")
                DropdownButtonFormField(
                  value: _routeType,
                  items: const [
                    DropdownMenuItem(
                      value: "manual",
                      child: Text("Manual Route"),
                    ),
                    DropdownMenuItem(value: "map", child: Text("Map Route")),
                  ],
                  onChanged: (v) => setState(() => _routeType = v!),
                  decoration: _input("Route Type", Icons.map),
                ),
              const SizedBox(height: 16),

              // SPECIAL JCB ONLY UI
              if (_vehicleType == "jcb") _buildJCBStops(),

              // NORMAL VEHICLE ROUTE UIs
              if (_vehicleType != "jcb" && _routeType == "manual")
                _buildManualRoute(),

              if (_vehicleType != "jcb" && _routeType == "map")
                _buildMapRoutePicker(),

              const SizedBox(height: 20),

              // KM INPUT — hidden for JCB
              if (_vehicleType != "jcb")
                TextFormField(
                  controller: _kmController,
                  keyboardType: TextInputType.number,
                  decoration: _input("KM to travel", Icons.speed),
                  validator: (v) => v!.isEmpty ? "Enter distance in KM" : null,
                ),

              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _saveVehicle,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: Colors.teal,
                ),
                child: const Text("Save Vehicle"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------ JCB STOP UI ------------------
  Widget _buildJCBStops() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "JCB Stop Points",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _stopInputController,
                decoration: const InputDecoration(
                  hintText: "Add JCB stop location...",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (_stopInputController.text.isNotEmpty) {
                  setState(() {
                    _stops.add(_stopInputController.text.trim());
                    _stopInputController.clear();
                  });
                }
              },
              child: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Column(
          children: _stops
              .map(
                (e) => ListTile(
                  title: Text(e),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => _stops.remove(e)),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  // ------------------ MANUAL ROUTE UI ------------------
  Widget _buildManualRoute() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _startRouteController,
          decoration: _input("Start Point (From)", Icons.flag),
          validator: (v) => v!.isEmpty ? "Enter start point" : null,
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _endRouteController,
          decoration: _input("End Point (To)", Icons.location_on),
          validator: (v) => v!.isEmpty ? "Enter end point" : null,
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _stopInputController,
                decoration: const InputDecoration(
                  hintText: "Add intermediate stop...",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (_stopInputController.text.isNotEmpty) {
                  setState(() {
                    _stops.add(_stopInputController.text);
                    _stopInputController.clear();
                  });
                }
              },
              child: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Column(
          children: _stops
              .map(
                (e) => ListTile(
                  title: Text(e),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => _stops.remove(e)),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  // ------------------ MAP ROUTE UI ------------------
  Widget _buildMapRoutePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.location_searching),
          label: const Text("Choose Start & End Points on Map"),
          onPressed: () => _openMapPicker(context),
        ),
        const SizedBox(height: 12),

        if (_startPoint != null)
          Text("Start: ${_startPoint!.latitude}, ${_startPoint!.longitude}"),

        if (_endPoint != null)
          Text("End: ${_endPoint!.latitude}, ${_endPoint!.longitude}"),
      ],
    );
  }

  // ------------------ MAP PICKER FUNCTION ------------------
  Future<void> _openMapPicker(BuildContext context) async {
    List<LatLng> polyPoints = [];

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              contentPadding: EdgeInsets.zero,
              content: SizedBox(
                height: 400,
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(12.2979, 76.6393),
                    zoom: 13,
                  ),

                  // 👉 Add point on each tap
                  onTap: (pos) {
                    setModalState(() {
                      polyPoints.add(pos);
                    });
                  },

                  markers: {
                    if (polyPoints.isNotEmpty)
                      Marker(
                        markerId: const MarkerId("start"),
                        position: polyPoints.first,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueGreen,
                        ),
                      ),
                    if (polyPoints.length > 1)
                      Marker(
                        markerId: const MarkerId("end"),
                        position: polyPoints.last,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        ),
                      ),
                  },

                  // 👉 Draw the polyline LIVE
                  polylines: {
                    if (polyPoints.length > 1)
                      Polyline(
                        polylineId: const PolylineId("route"),
                        points: polyPoints,
                        width: 5,
                        color: Colors.blue,
                      ),
                  },
                ),
              ),

              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),

                // Save button only if we have at least start + end
                if (polyPoints.length > 1)
                  ElevatedButton(
                    child: const Text("Save Route"),
                    onPressed: () {
                      // Set main route points
                      setState(() {
                        _startPoint = GeoPoint(
                          polyPoints.first.latitude,
                          polyPoints.first.longitude,
                        );
                        _endPoint = GeoPoint(
                          polyPoints.last.latitude,
                          polyPoints.last.longitude,
                        );
                      });

                      // Save polyline list in vehicle service
                      _vehicleService.pendingMapPolyline = polyPoints
                          .map((e) => {"lat": e.latitude, "lng": e.longitude})
                          .toList();

                      Navigator.pop(context);
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // ------------------ SAVE VEHICLE ------------------
  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    // MAP ROUTE VALIDATION
    if (_vehicleType != "jcb" &&
        _routeType == "map" &&
        (_startPoint == null || _endPoint == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select route on map"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await _vehicleService.addVehicle(
      type: _vehicleType,
      number: _numberController.text.trim(),
      jobType: _jobType,
      routeType: _routeType,

      // SPECIAL JCB ONLY
      manualRoute: _vehicleType == "jcb"
          ? {'stops': _stops}
          : _routeType == "manual"
          ? {
              'start': _startRouteController.text.trim(),
              'end': _endRouteController.text.trim(),
              'stops': _stops,
            }
          : null,

      routeStart: _routeType == "map" ? _startPoint : null,
      routeEnd: _routeType == "map" ? _endPoint : null,

      // KM NOT REQUIRED FOR JCB
      km: _vehicleType == "jcb"
          ? 0.0
          : double.tryParse(_kmController.text.trim()) ?? 0.0,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Vehicle Added Successfully!"),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  // ------------------ INPUT DECOR ------------------
  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.teal),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
