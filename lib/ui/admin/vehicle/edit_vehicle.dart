import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:swachhata_app/services/vehicle_service.dart';

class EditVehiclePage extends StatefulWidget {
  final String vehicleId;
  final Map<String, dynamic> vehicleData;

  const EditVehiclePage({
    super.key,
    required this.vehicleId,
    required this.vehicleData,
  });

  @override
  State<EditVehiclePage> createState() => _EditVehiclePageState();
}

class _EditVehiclePageState extends State<EditVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final VehicleService _vehicleService = VehicleService();

  late TextEditingController _numberController;
  late TextEditingController _startController;
  late TextEditingController _endController;
  late TextEditingController _stopInputController;

  String _vehicleType = "auto";
  String _jobType = "collection";
  String _routeType = "manual";

  List<String> _stops = [];

  GeoPoint? _startPoint;
  GeoPoint? _endPoint;

  @override
  void initState() {
    super.initState();

    final v = widget.vehicleData;

    _vehicleType = v['type'] ?? 'auto';
    _jobType = v['jobType'] ?? 'collection';
    _routeType = v['routeType'] ?? 'manual';

    _numberController = TextEditingController(text: v['number']);
    _startController = TextEditingController(
      text: v['manualRoute']?['start'] ?? "",
    );
    _endController = TextEditingController(
      text: v['manualRoute']?['end'] ?? "",
    );
    _stopInputController = TextEditingController();

    _stops = List<String>.from(v['manualRoute']?['stops'] ?? []);

    _startPoint = v['routeStart'];
    _endPoint = v['routeEnd'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Vehicle"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _deleteVehicle,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildVehicleTypeField(),
              const SizedBox(height: 12),

              if (_vehicleType == "tractor" || _vehicleType == "jcb")
                _buildJobTypeField(),

              const SizedBox(height: 12),
              _buildVehicleNumberField(),
              const SizedBox(height: 12),

              _buildRouteTypeField(),
              const SizedBox(height: 12),

              if (_routeType == "manual") _buildManualRouteUI(),
              if (_routeType == "map") _buildMapRouteUI(),

              const SizedBox(height: 20),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _saveVehicle, // <-- FIXED (Now it calls _saveVehicle)
        icon: const Icon(Icons.save, color: Colors.white),
        label: const Text(
          "Save Changes",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ------------------ FIELD WIDGETS -------------------

  Widget _buildVehicleTypeField() {
    return DropdownButtonFormField(
      value: _vehicleType,
      items: ["auto", "tipper", "tractor", "jcb"]
          .map((v) => DropdownMenuItem(value: v, child: Text(v.toUpperCase())))
          .toList(),
      onChanged: (v) => setState(() => _vehicleType = v!),
      decoration: _input("Vehicle Type", Icons.car_rental),
    );
  }

  Widget _buildJobTypeField() {
    return DropdownButtonFormField(
      value: _jobType,
      items: const [
        DropdownMenuItem(value: "collection", child: Text("Collection")),
        DropdownMenuItem(value: "sanitation", child: Text("Sanitation")),
      ],
      onChanged: (v) => setState(() => _jobType = v!),
      decoration: _input("Work Type", Icons.work),
    );
  }

  Widget _buildVehicleNumberField() {
    return TextFormField(
      controller: _numberController,
      decoration: _input("Vehicle Number", Icons.confirmation_number),
      validator: (v) => v!.isEmpty ? "Required" : null,
    );
  }

  Widget _buildRouteTypeField() {
    return DropdownButtonFormField(
      value: _routeType,
      items: const [
        DropdownMenuItem(value: "manual", child: Text("Manual Route")),
        DropdownMenuItem(value: "map", child: Text("Map Route")),
      ],
      onChanged: (v) => setState(() => _routeType = v!),
      decoration: _input("Route Type", Icons.route),
    );
  }

  // ------------------ MANUAL ROUTE -------------------

  Widget _buildManualRouteUI() {
    return Column(
      children: [
        TextFormField(
          controller: _startController,
          decoration: _input("Start", Icons.flag),
        ),
        const SizedBox(height: 10),

        TextFormField(
          controller: _endController,
          decoration: _input("End", Icons.place),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _stopInputController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Add stop",
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _stops.add(_stopInputController.text);
                  _stopInputController.clear();
                });
              },
              child: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 10),

        ..._stops.map(
          (s) => ListTile(
            title: Text(s),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  _stops.remove(s);
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  // ------------------ MAP ROUTE -------------------

  Widget _buildMapRouteUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.map),
          label: const Text("Pick Route"),
          onPressed: () => _openMapRoutePicker(context),
        ),
        if (_startPoint != null)
          Text("Start: ${_startPoint!.latitude}, ${_startPoint!.longitude}"),
        if (_endPoint != null)
          Text("End: ${_endPoint!.latitude}, ${_endPoint!.longitude}"),
      ],
    );
  }

  Future<void> _openMapRoutePicker(BuildContext context) async {
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
                    child: const Text("Save"),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // ------------------ SAVE VEHICLE -------------------

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    await FirebaseFirestore.instance
        .collection('vehicles')
        .doc(widget.vehicleId)
        .update({
          'type': _vehicleType,
          'number': _numberController.text.trim(),
          'jobType': _jobType,
          'routeType': _routeType,
          'manualRoute': _routeType == "manual"
              ? {
                  'start': _startController.text.trim(),
                  'end': _endController.text.trim(),
                  'stops': _stops,
                }
              : null,
          'routeStart': _routeType == "map" ? _startPoint : null,
          'routeEnd': _routeType == "map" ? _endPoint : null,
          'updatedAt': FieldValue.serverTimestamp(),
        });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Vehicle updated")));
    Navigator.pop(context);
  }

  // ------------------ DELETE VEHICLE -------------------

  Future<void> _deleteVehicle() async {
    await _vehicleService.deleteVehicle(widget.vehicleId);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Vehicle deleted")));

    Navigator.pop(context);
  }

  // ------------------ Input Decoration -------------------

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
