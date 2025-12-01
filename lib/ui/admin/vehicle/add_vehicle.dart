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
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Add New Vehicle",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📝 Form Section
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFF2C5F2D).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.directions_car_rounded,
                            color: Color(0xFF2C5F2D),
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Vehicle Details",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // VEHICLE TYPE
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Vehicle Type",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _vehicleType,
                              icon: Icon(
                                Icons.arrow_drop_down_rounded,
                                color: Color(0xFF2C5F2D),
                              ),
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              items: vehicleTypes
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Row(
                                        children: [
                                          Icon(
                                            _getVehicleTypeIcon(e),
                                            color: Color(0xFF2C5F2D),
                                            size: 20,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            e.toUpperCase(),
                                            style: TextStyle(
                                              color: Colors.grey.shade800,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
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
                                    _routeType = "jcb_stops";
                                    _stops.clear();
                                    _startRouteController.clear();
                                    _endRouteController.clear();
                                    _startPoint = null;
                                    _endPoint = null;
                                  } else {
                                    _routeType = "manual";
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // JOB TYPE (Tractor/JCB only)
                    if (_vehicleType == "tractor" || _vehicleType == "jcb")
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Work Type",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _jobType,
                                icon: Icon(
                                  Icons.arrow_drop_down_rounded,
                                  color: Color(0xFF2C5F2D),
                                ),
                                isExpanded: true,
                                dropdownColor: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                items: const [
                                  DropdownMenuItem(
                                    value: "collection",
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.collections_rounded,
                                          color: Color(0xFF2C5F2D),
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Text("Collection"),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: "sanitation",
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.clean_hands_rounded,
                                          color: Color(0xFF2C5F2D),
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Text("Sanitation"),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (v) => setState(() => _jobType = v!),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                      ),

                    // VEHICLE NUMBER
                    _buildTextField(
                      controller: _numberController,
                      label: "Vehicle Number",
                      icon: Icons.confirmation_number_rounded,
                      validator: (v) =>
                          v!.isEmpty ? "Enter vehicle number" : null,
                    ),
                    SizedBox(height: 16),

                    // ROUTE TYPE — hidden for JCB
                    if (_vehicleType != "jcb")
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Route Type",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _routeType,
                                icon: Icon(
                                  Icons.arrow_drop_down_rounded,
                                  color: Color(0xFF2C5F2D),
                                ),
                                isExpanded: true,
                                dropdownColor: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                items: const [
                                  DropdownMenuItem(
                                    value: "manual",
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit_road_rounded,
                                          color: Color(0xFF2C5F2D),
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Text("Manual Route"),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: "map",
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.map_rounded,
                                          color: Color(0xFF2C5F2D),
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Text("Map Route"),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _routeType = v!),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                      ),

                    // SPECIAL JCB ONLY UI
                    if (_vehicleType == "jcb") _buildJCBStops(),

                    // NORMAL VEHICLE ROUTE UIs
                    if (_vehicleType != "jcb" && _routeType == "manual")
                      _buildManualRoute(),

                    if (_vehicleType != "jcb" && _routeType == "map")
                      _buildMapRoutePicker(),

                    // KM INPUT — hidden for JCB
                    if (_vehicleType != "jcb")
                      _buildTextField(
                        controller: _kmController,
                        label: "Distance (KM)",
                        icon: Icons.speed_rounded,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v!.isEmpty ? "Enter distance in KM" : null,
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // 💾 Save Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF2C5F2D), Color(0xFF1E3A1E)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF2C5F2D).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                icon: _isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Icon(Icons.save_rounded, color: Colors.white, size: 20),
                label: Text(
                  _isSaving ? "Saving..." : "Save Vehicle",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isSaving ? null : _saveVehicle,
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ------------------ JCB STOP UI ------------------
  Widget _buildJCBStops() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.pin_drop_rounded,
                  color: Colors.orange.shade600,
                  size: 18,
                ),
              ),
              SizedBox(width: 8),
              Text(
                "JCB Stop Points",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            "Add stop points where JCB will operate",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _stopInputController,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: "Enter stop location...",
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (_stopInputController.text.isNotEmpty) {
                      setState(() {
                        _stops.add(_stopInputController.text.trim());
                        _stopInputController.clear();
                      });
                    }
                  },
                  child: Icon(Icons.add_rounded, color: Color(0xFF2C5F2D)),
                ),
              ),
            ],
          ),

          if (_stops.isNotEmpty) SizedBox(height: 12),

          Column(
            children: _stops
                .map(
                  (e) => Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Color(0xFF2C5F2D).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: Color(0xFF2C5F2D),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            e,
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_rounded,
                            size: 18,
                            color: Colors.red.shade600,
                          ),
                          onPressed: () => setState(() => _stops.remove(e)),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // ------------------ MANUAL ROUTE UI ------------------
  Widget _buildManualRoute() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.route_rounded,
                  color: Colors.blue.shade600,
                  size: 18,
                ),
              ),
              SizedBox(width: 8),
              Text(
                "Manual Route",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          _buildTextField(
            controller: _startRouteController,
            label: "Start Point (From)",
            icon: Icons.flag_rounded,
            validator: (v) => v!.isEmpty ? "Enter start point" : null,
          ),
          SizedBox(height: 12),

          _buildTextField(
            controller: _endRouteController,
            label: "End Point (To)",
            icon: Icons.location_on_rounded,
            validator: (v) => v!.isEmpty ? "Enter end point" : null,
          ),
          SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _stopInputController,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: "Add intermediate stop...",
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
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
                  child: Icon(Icons.add_rounded, color: Color(0xFF2C5F2D)),
                ),
              ),
            ],
          ),

          if (_stops.isNotEmpty) SizedBox(height: 12),

          Column(
            children: _stops
                .map(
                  (e) => Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Color(0xFF3498DB).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.circle_rounded,
                            size: 10,
                            color: Color(0xFF3498DB),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            e,
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_rounded,
                            size: 18,
                            color: Colors.red.shade600,
                          ),
                          onPressed: () => setState(() => _stops.remove(e)),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // ------------------ MAP ROUTE UI ------------------
  Widget _buildMapRoutePicker() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.map_rounded,
                  color: Colors.green.shade600,
                  size: 18,
                ),
              ),
              SizedBox(width: 8),
              Text(
                "Map Route",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ElevatedButton.icon(
              icon: Icon(
                Icons.location_searching_rounded,
                color: Color(0xFF2C5F2D),
                size: 20,
              ),
              label: Text(
                "Choose Start & End Points on Map",
                style: TextStyle(
                  color: Color(0xFF2C5F2D),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _openMapPicker(context),
            ),
          ),
          SizedBox(height: 12),

          if (_startPoint != null)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.flag_rounded,
                      size: 16,
                      color: Colors.green.shade600,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Start: ${_startPoint!.latitude.toStringAsFixed(4)}, ${_startPoint!.longitude.toStringAsFixed(4)}",
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_endPoint != null) SizedBox(height: 8),

          if (_endPoint != null)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: Colors.red.shade600,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "End: ${_endPoint!.latitude.toStringAsFixed(4)}, ${_endPoint!.longitude.toStringAsFixed(4)}",
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
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
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              insetPadding: EdgeInsets.zero,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: 500,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Color(0xFF2C5F2D),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.map_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Select Route Points",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(12.2979, 76.6393),
                          zoom: 13,
                        ),
                        onTap: (pos) {
                          setModalState(() {
                            polyPoints.add(pos);
                          });
                        },
                        markers: {
                          if (polyPoints.isNotEmpty)
                            Marker(
                              markerId: MarkerId("start"),
                              position: polyPoints.first,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueGreen,
                              ),
                            ),
                          if (polyPoints.length > 1)
                            Marker(
                              markerId: MarkerId("end"),
                              position: polyPoints.last,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueRed,
                              ),
                            ),
                        },
                        polylines: {
                          if (polyPoints.length > 1)
                            Polyline(
                              polylineId: PolylineId("route"),
                              points: polyPoints,
                              width: 5,
                              color: Color(0xFF2C5F2D),
                            ),
                        },
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          if (polyPoints.length > 1)
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color(0xFF2C5F2D),
                                      Color(0xFF1E3A1E),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF2C5F2D).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
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
                                    _vehicleService.pendingMapPolyline =
                                        polyPoints
                                            .map(
                                              (e) => {
                                                "lat": e.latitude,
                                                "lng": e.longitude,
                                              },
                                            )
                                            .toList();
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    "Save Route",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
        SnackBar(
          content: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "Please select route on map",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _vehicleService.addVehicle(
        type: _vehicleType,
        number: _numberController.text.trim(),
        jobType: _jobType,
        routeType: _routeType,
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
        km: _vehicleType == "jcb"
            ? 0.0
            : double.tryParse(_kmController.text.trim()) ?? 0.0,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF27AE60),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "Vehicle Added Successfully!",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "Error: $e",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ------------------ HELPER METHODS ------------------
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: TextStyle(
        color: Colors.grey.shade800,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Container(
          padding: EdgeInsets.all(12),
          margin: EdgeInsets.only(right: 12),
          child: Icon(icon, color: Color(0xFF2C5F2D)),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF2C5F2D), width: 2),
        ),
        contentPadding: EdgeInsets.all(16),
      ),
    );
  }

  IconData _getVehicleTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'auto':
        return Icons.local_taxi_rounded;
      case 'tipper':
        return Icons.local_shipping_rounded;
      case 'tractor':
        return Icons.agriculture_rounded;
      case 'jcb':
        return Icons.construction_rounded;
      default:
        return Icons.directions_bus_rounded;
    }
  }
}
