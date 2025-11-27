import 'dart:developer';
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
  final TextEditingController _timeController = TextEditingController();

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
                    if (v == "auto" || v == "tipper") {
                      _jobType = "collection";
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

              // ROUTE TYPE
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

              if (_routeType == "manual") _buildManualRoute(),
              if (_routeType == "map") _buildMapRoutePicker(),

              const SizedBox(height: 20),

              // KM + TIME INPUT
              TextFormField(
                controller: _kmController,
                keyboardType: TextInputType.number,
                decoration: _input("KM to travel", Icons.speed),
                validator: (v) => v!.isEmpty ? "Enter distance in KM" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _timeController,
                keyboardType: TextInputType.number,
                decoration: _input("Time to travel (minutes)", Icons.timer),
                validator: (v) => v!.isEmpty ? "Enter travel time" : null,
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

  Future<void> _openMapPicker(BuildContext context) async {
    LatLng? start;
    LatLng? end;

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              contentPadding: EdgeInsets.zero,
              content: SizedBox(
                height: 400,
                width: double.maxFinite,
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(12.9716, 77.5946),
                    zoom: 13,
                  ),
                  onTap: (pos) {
                    setModalState(() {
                      if (start == null) {
                        start = pos;
                      } else if (end == null) {
                        end = pos;
                      } else {
                        start = pos;
                        end = null;
                      }
                    });
                  },
                  markers: {
                    if (start != null)
                      Marker(
                        markerId: const MarkerId("start"),
                        position: start!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueGreen,
                        ),
                      ),
                    if (end != null)
                      Marker(
                        markerId: const MarkerId("end"),
                        position: end!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        ),
                      ),
                  },
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                if (start != null && end != null)
                  ElevatedButton(
                    child: const Text("Save Route"),
                    onPressed: () {
                      setState(() {
                        _startPoint = GeoPoint(
                          start!.latitude,
                          start!.longitude,
                        );
                        _endPoint = GeoPoint(end!.latitude, end!.longitude);
                      });
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

    if (_routeType == "map" && (_startPoint == null || _endPoint == null)) {
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

      manualRoute: _routeType == "manual"
          ? {
              'start': _startRouteController.text.trim(),
              'end': _endRouteController.text.trim(),
              'stops': _stops,
            }
          : null,

      routeStart: _routeType == "map" ? _startPoint : null,
      routeEnd: _routeType == "map" ? _endPoint : null,

      // NEW FIELDS
      km: double.tryParse(_kmController.text.trim()) ?? 0.0,
      time: int.tryParse(_timeController.text.trim()) ?? 0,
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
