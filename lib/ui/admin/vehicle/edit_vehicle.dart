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
  late TextEditingController _startRouteController;
  late TextEditingController _endRouteController;
  late TextEditingController _stopInputController;

  List<String> _stops = [];

  String _vehicleType = "auto";
  String _jobType = "collection";
  String _routeType = "manual";

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
    _startRouteController = TextEditingController(
      text: v['manualRoute']?['start'] ?? "",
    );
    _endRouteController = TextEditingController(
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
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Edit Vehicle",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.only(left: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
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
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.red, Colors.redAccent],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.delete_rounded, color: Colors.white),
              onPressed: _deleteVehicle,
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _themedCard(
              child: Column(
                children: [
                  _sectionHeader(
                    Icons.directions_car_rounded,
                    "Vehicle Details",
                  ),
                  const SizedBox(height: 16),
                  _buildVehicleType(),
                  const SizedBox(height: 16),
                  if (_vehicleType == "tractor" || _vehicleType == "jcb")
                    _buildJobType(),
                  const SizedBox(height: 16),
                  _buildVehicleNumber(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (_vehicleType != "jcb")
              _themedCard(
                child: Column(
                  children: [
                    _sectionHeader(Icons.alt_route_rounded, "Route Settings"),
                    const SizedBox(height: 16),
                    _buildRouteType(),
                    const SizedBox(height: 16),
                    if (_routeType == "manual") _buildManualRouteUI(),
                    if (_routeType == "map") _buildMapRouteUI(),
                  ],
                ),
              ),

            if (_vehicleType == "jcb")
              _themedCard(
                child: Column(
                  children: [
                    _sectionHeader(Icons.location_on_rounded, "JCB Stops"),
                    const SizedBox(height: 16),
                    _buildJCBStopsUI(),
                  ],
                ),
              ),

            const SizedBox(height: 30),

            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  // ---------------- THEMING HELPERS -------------------

  Widget _themedCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF2C5F2D).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF2C5F2D)),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF2C5F2D)),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2C5F2D), width: 2),
      ),
    );
  }

  // ---------------- UI COMPONENTS -------------------

  Widget _buildVehicleType() {
    return DropdownButtonFormField(
      value: _vehicleType,
      items: ["auto", "tipper", "tractor", "jcb"]
          .map((v) => DropdownMenuItem(value: v, child: Text(v.toUpperCase())))
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
    );
  }

  Widget _buildJobType() {
    return DropdownButtonFormField(
      value: _jobType,
      items: const [
        DropdownMenuItem(value: "collection", child: Text("Collection")),
        DropdownMenuItem(value: "sanitation", child: Text("Sanitation")),
      ],
      onChanged: (v) => setState(() => _jobType = v!),
      decoration: _input("Work Type", Icons.work_outline_rounded),
    );
  }

  Widget _buildVehicleNumber() {
    return TextFormField(
      controller: _numberController,
      decoration: _input("Vehicle Number", Icons.confirmation_number_rounded),
      validator: (v) => v!.isEmpty ? "Required" : null,
    );
  }

  Widget _buildRouteType() {
    return DropdownButtonFormField(
      value: _routeType,
      items: const [
        DropdownMenuItem(value: "manual", child: Text("Manual Route")),
        DropdownMenuItem(value: "map", child: Text("Map Route")),
      ],
      onChanged: (v) => setState(() => _routeType = v!),
      decoration: _input("Route Type", Icons.alt_route),
    );
  }

  // ---------------- MANUAL ROUTE UI -------------------

  Widget _buildManualRouteUI() {
    return Column(
      children: [
        TextFormField(
          controller: _startRouteController,
          decoration: _input("Start Point (From)", Icons.flag_rounded),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _endRouteController,
          decoration: _input("End Point (To)", Icons.location_on_rounded),
        ),
        const SizedBox(height: 12),

        // Add stop
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _stopInputController,
                decoration: _input("Add Stop", Icons.add_location_alt_rounded),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C5F2D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (_stopInputController.text.isNotEmpty) {
                  setState(() {
                    _stops.add(_stopInputController.text);
                    _stopInputController.clear();
                  });
                }
              },
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),

        const SizedBox(height: 14),

        ..._stops.map(
          (s) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              s,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_rounded, color: Colors.red),
              onPressed: () => setState(() => _stops.remove(s)),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- JCB ROUTE UI -------------------

  Widget _buildJCBStopsUI() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _stopInputController,
                decoration: _input("Add Stop", Icons.add_location_alt_rounded),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C5F2D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (_stopInputController.text.isNotEmpty) {
                  setState(() {
                    _stops.add(_stopInputController.text);
                    _stopInputController.clear();
                  });
                }
              },
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),

        const SizedBox(height: 14),

        ..._stops.map(
          (s) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              s,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_rounded, color: Colors.red),
              onPressed: () => setState(() => _stops.remove(s)),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- MAP UI -------------------

  Widget _buildMapRouteUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.map_rounded),
          label: const Text("Pick Route on Map"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2C5F2D),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => _openMapPicker(context),
        ),
        const SizedBox(height: 10),

        if (_startPoint != null)
          Text("Start: ${_startPoint!.latitude}, ${_startPoint!.longitude}"),

        if (_endPoint != null)
          Text("End: ${_endPoint!.latitude}, ${_endPoint!.longitude}"),
      ],
    );
  }

  // ---------------- SAVE BUTTON -------------------

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveVehicle,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: const Color(0xFF2C5F2D),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          "UPDATE VEHICLE",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ---------------- LOGIC: Save, Delete, Map (unchanged) -------------------

  // keep your logic EXACTLY as is ↓↓↓
  Future<void> _openMapPicker(BuildContext context) async {
    // (no change)
  }

  Future<void> _saveVehicle() async {
    // (no change)
  }

  Future<void> _deleteVehicle() async {
    // (no change)
  }
}
