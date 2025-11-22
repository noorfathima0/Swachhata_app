import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';

import 'package:swachhata_app/l10n/app_localizations.dart';
import '../../../services/complaint_service.dart';
import '../../../services/location_service.dart';

class ComplaintForm extends StatefulWidget {
  const ComplaintForm({super.key});

  @override
  State<ComplaintForm> createState() => _ComplaintFormState();
}

class _ComplaintFormState extends State<ComplaintForm> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedType;
  File? _image;
  bool _loading = false;

  LatLng? _currentPosition;
  GoogleMapController? _mapController;

  // ✅ Colors
  final Color _primaryColor = Colors.teal;
  final Color _primaryDark = Color(0xFF00695C);
  final Color _primaryLight = Color(0xFF4DB6AC);

  // ✅ Pick image
  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
    );
    if (picked != null) setState(() => _image = File(picked.path));
  }

  // ✅ Fetch current location and reverse geocode
  Future<void> _getLocation() async {
    final locService = LocationService();
    try {
      final loc = await locService.getCurrentLocation();

      final placemarks = await placemarkFromCoordinates(
        loc["latitude"]!,
        loc["longitude"]!,
      );
      final place = placemarks.first;
      String address =
          "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";

      setState(() {
        _currentPosition = LatLng(loc["latitude"]!, loc["longitude"]!);
        _addressController.text = address;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${AppLocalizations.of(context)!.error}: $e")),
      );
    }
  }

  // ✅ Submit complaint
  Future<void> _submitComplaint() async {
    final loc = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate() ||
        _image == null ||
        _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.error), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final service = ComplaintService();
      await service.submitComplaint(
        type: _selectedType!,
        description: _descController.text.trim(),
        image: _image!,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        address: _addressController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.success), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // ✅ Localized complaint types
    final types = [
      loc.complaintTypeGarbage,
      loc.complaintTypeDrainage,
      loc.complaintTypeStreetlight,
      loc.complaintTypeRoadDamage,
      loc.complaintTypeOther,
    ];

    _selectedType ??= types.first;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.addComplaint,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: _primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Complaint Type
              _sectionCard(
                title: loc.complaintType,
                child: DropdownButtonFormField<String>(
                  value: _selectedType,
                  items: types
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedType = v),
                  decoration: _inputDecoration(loc.complaintType),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ Description
              _sectionCard(
                title: loc.complaintDescription,
                child: TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: _inputDecoration(loc.enterDescription),
                  validator: (v) =>
                      v == null || v.isEmpty ? loc.enterDescription : null,
                ),
              ),
              const SizedBox(height: 16),

              // ✅ Image Upload
              _sectionCard(
                title: loc.addPhoto,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: Text(loc.camera),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: Text(loc.gallery),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: _primaryColor),
                              foregroundColor: _primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_image != null) ...[
                      const SizedBox(height: 12),
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _image!,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: () => setState(() => _image = null),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ✅ Location Section
              _sectionCard(
                title: loc.selectLocation,
                child: Column(
                  children: [
                    _currentPosition == null
                        ? Column(
                            children: [
                              CircularProgressIndicator(color: _primaryColor),
                              const SizedBox(height: 8),
                              Text(loc.loading),
                            ],
                          )
                        : SizedBox(
                            height: 250,
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _currentPosition!,
                                zoom: 16,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId("selected"),
                                  position: _currentPosition!,
                                ),
                              },
                              onTap: (pos) async {
                                final placemarks =
                                    await placemarkFromCoordinates(
                                      pos.latitude,
                                      pos.longitude,
                                    );
                                final p = placemarks.first;
                                final address =
                                    "${p.street}, ${p.locality}, ${p.administrativeArea}, ${p.country}";
                                setState(() {
                                  _currentPosition = pos;
                                  _addressController.text = address;
                                });
                              },
                            ),
                          ),

                    const SizedBox(height: 12),

                    ElevatedButton.icon(
                      onPressed: _getLocation,
                      icon: const Icon(Icons.my_location),
                      label: Text(loc.useCurrentLocation),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryLight,
                        foregroundColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _addressController,
                      decoration: _inputDecoration(loc.address),
                      validator: (v) =>
                          v == null || v.isEmpty ? loc.enterAddress : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ✅ Submit Button
              _loading
                  ? Column(
                      children: [
                        CircularProgressIndicator(color: _primaryColor),
                        const SizedBox(height: 12),
                        Text(loc.loading),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitComplaint,
                        icon: const Icon(Icons.send),
                        label: Text(loc.submit),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Reusable card widget
  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: _primaryDark,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  // ✅ Input decoration (with localization)
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
