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

  // ✅ Red theme colors matching the Complaints dashboard box
  final Color _primaryColor = const Color(0xFFEF5350);
  final Color _primaryDark = const Color(0xFFE53935);
  final Color _primaryLight = const Color(0xFFFFCDD2);
  final LinearGradient _primaryGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF5350), Color(0xFFE53935)],
  );

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
        SnackBar(
          content: Text(loc.error),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
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
        SnackBar(
          content: Text(loc.success),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDarkMode
        ? const Color(0xFF121212)
        : const Color(0xFFF5F7FA);
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
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          loc.addComplaint,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: _primaryGradient),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                gradient: _primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.3),
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
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.report_problem_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Report an Issue",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.95),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Help us make your community cleaner and safer",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Complaint Form
            Container(
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Complaint Type
                    Text(
                      loc.complaintType,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF2D2D2D)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode
                              ? const Color(0xFF3D3D3D)
                              : const Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: DropdownButtonFormField<String>(
                          value: _selectedType,
                          items: types
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                    t,
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _selectedType = v),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          dropdownColor: isDarkMode
                              ? const Color(0xFF2D2D2D)
                              : Colors.white,
                          icon: Icon(
                            Icons.arrow_drop_down_rounded,
                            color: _primaryColor,
                            size: 28,
                          ),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Description
                    Text(
                      loc.complaintDescription,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF2D2D2D)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode
                              ? const Color(0xFF3D3D3D)
                              : const Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                      child: TextFormField(
                        controller: _descController,
                        maxLines: 4,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: loc.enterDescription,
                          hintStyle: TextStyle(
                            color: isDarkMode ? Colors.white54 : Colors.black45,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? loc.enterDescription
                            : null,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Image Upload
                    Text(
                      loc.addPhoto,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(
                              Icons.camera_alt_rounded,
                              size: 22,
                            ),
                            label: Text(loc.camera),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(
                              Icons.photo_library_rounded,
                              size: 22,
                            ),
                            label: Text(loc.gallery),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _primaryColor,
                              side: BorderSide(
                                color: _primaryColor,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_image != null)
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _primaryColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _image!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _image = null),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Location Section
                    Text(
                      loc.selectLocation,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _currentPosition == null
                        ? Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0xFF2D2D2D)
                                  : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                CircularProgressIndicator(color: _primaryColor),
                                const SizedBox(height: 16),
                                Text(
                                  loc.loading,
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            height: 250,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDarkMode
                                    ? const Color(0xFF3D3D3D)
                                    : const Color(0xFFE0E0E0),
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: _currentPosition!,
                                  zoom: 16,
                                ),
                                markers: {
                                  Marker(
                                    markerId: const MarkerId("selected"),
                                    position: _currentPosition!,
                                    icon: BitmapDescriptor.defaultMarkerWithHue(
                                      BitmapDescriptor.hueRed,
                                    ),
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
                          ),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: _getLocation,
                      icon: const Icon(Icons.my_location_rounded, size: 22),
                      label: Text(loc.useCurrentLocation),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryLight,
                        foregroundColor: _primaryDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF2D2D2D)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode
                              ? const Color(0xFF3D3D3D)
                              : const Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                      child: TextFormField(
                        controller: _addressController,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: loc.address,
                          hintStyle: TextStyle(
                            color: isDarkMode ? Colors.white54 : Colors.black45,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? loc.enterAddress : null,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    _loading
                        ? Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0xFF2D2D2D)
                                  : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _primaryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  loc.loading,
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: _submitComplaint,
                              icon: const Icon(Icons.send_rounded, size: 24),
                              label: Text(
                                loc.submit,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
