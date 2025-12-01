import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../../../services/location_service.dart';
import '../../../services/imgbb_service.dart';
import 'package:swachhata_app/l10n/app_localizations.dart';

class ActivityFormPage extends StatefulWidget {
  const ActivityFormPage({super.key});

  @override
  State<ActivityFormPage> createState() => _ActivityFormPageState();
}

class _ActivityFormPageState extends State<ActivityFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final ImgBBService _imgBBService = ImgBBService();
  final LocationService _locationService = LocationService();

  final List<File> _selectedImages = [];
  bool _isSubmitting = false;

  LatLng? _selectedLatLng;
  GoogleMapController? _mapController;

  // ✅ Green theme colors matching the Activities dashboard box
  final Color primaryColor = const Color(0xFF4CAF50);
  final Color primaryDark = const Color(0xFF388E3C);
  final Color primaryLight = const Color(0xFFC8E6C9);
  final LinearGradient primaryGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
  );

  // 📸 Pick multiple images
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      final newFiles = pickedFiles.map((e) => File(e.path)).toList();
      if (_selectedImages.length + newFiles.length > 5) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.maxFiveImages),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } else {
        setState(() => _selectedImages.addAll(newFiles));
      }
    }
  }

  // 📍 Format a readable full address
  String _formatFullAddress(Placemark place) {
    final parts = [
      if (place.name != null && place.name!.isNotEmpty) place.name,
      if (place.subLocality != null && place.subLocality!.isNotEmpty)
        place.subLocality,
      if (place.locality != null && place.locality!.isNotEmpty) place.locality,
      if (place.administrativeArea != null &&
          place.administrativeArea!.isNotEmpty)
        place.administrativeArea,
      if (place.postalCode != null && place.postalCode!.isNotEmpty)
        place.postalCode,
      if (place.country != null && place.country!.isNotEmpty) place.country,
    ];
    return parts.join(', ');
  }

  // 📍 Use current location
  Future<void> _useCurrentLocation() async {
    final loc = AppLocalizations.of(context)!;
    try {
      final location = await _locationService.getCurrentLocation();
      final lat = location['latitude']!;
      final lng = location['longitude']!;

      final placemarks = await placemarkFromCoordinates(lat, lng);
      String address = loc.unknownLocation;
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        address = _formatFullAddress(place);
      }

      setState(() {
        _selectedLatLng = LatLng(lat, lng);
        _locationController.text = address;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLatLng!, 15),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.failedToGetLocation}: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  // 📍 Handle map tap to select location
  Future<void> _onMapTap(LatLng position) async {
    final loc = AppLocalizations.of(context)!;
    try {
      setState(() {
        _selectedLatLng = position;
      });

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      String address = loc.unknownLocation;
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        address = _formatFullAddress(place);
      }

      setState(() {
        _locationController.text = address;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.failedToGetLocation}: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  // 📝 Submit activity
  Future<void> _submitActivity() async {
    final loc = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_selectedLatLng == null || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.selectLocationOnMap),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    List<String> mediaUrls = [];

    // 📤 Upload images to ImgBB
    if (_selectedImages.isNotEmpty) {
      try {
        for (final image in _selectedImages) {
          final url = await _imgBBService.uploadImage(image);
          mediaUrls.add(url);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loc.imageUploadFailed}: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }

    // 💾 Save to Firestore with full address
    await FirebaseFirestore.instance.collection('activities').add({
      'userId': user.uid,
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'address': _locationController.text.trim(),
      'latitude': _selectedLatLng!.latitude,
      'longitude': _selectedLatLng!.longitude,
      'mediaUrls': mediaUrls,
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // ✅ Reset form
    setState(() {
      _titleController.clear();
      _descController.clear();
      _locationController.clear();
      _selectedImages.clear();
      _selectedLatLng = null;
      _isSubmitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.activitySubmitted),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDarkMode
        ? const Color(0xFF121212)
        : const Color(0xFFF5F7FA);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          loc.submitActivity,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: primaryGradient),
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
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.add_task_rounded,
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
                          "Submit New Activity",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.95),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Help keep your community clean and green",
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

            // Main Form Container
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
                    // Title Field
                    Text(
                      loc.activityTitle,
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
                        controller: _titleController,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: loc.enterActivityTitle,
                          hintStyle: TextStyle(
                            color: isDarkMode ? Colors.white54 : Colors.black45,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (v) =>
                            v!.isEmpty ? loc.enterTitleValidation : null,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Description Field
                    Text(
                      loc.description,
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
                          hintText: loc.describeActivity,
                          hintStyle: TextStyle(
                            color: isDarkMode ? Colors.white54 : Colors.black45,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (v) =>
                            v!.isEmpty ? loc.enterDescriptionValidation : null,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Location Section
                    Text(
                      loc.location,
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
                        controller: _locationController,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: loc.selectLocationOnMapHint,
                          hintStyle: TextStyle(
                            color: isDarkMode ? Colors.white54 : Colors.black45,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          prefixIcon: Icon(
                            Icons.location_on_rounded,
                            color: primaryColor,
                            size: 22,
                          ),
                        ),
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _useCurrentLocation,
                        icon: const Icon(Icons.my_location_rounded, size: 22),
                        label: Text(loc.useCurrentLocation),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryLight,
                          foregroundColor: primaryDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Map Section
                    Text(
                      loc.selectLocationOnMapTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: GoogleMap(
                          initialCameraPosition: const CameraPosition(
                            target: LatLng(20.5937, 78.9629), // India center
                            zoom: 4,
                          ),
                          markers: _selectedLatLng == null
                              ? {}
                              : {
                                  Marker(
                                    markerId: const MarkerId("selected"),
                                    position: _selectedLatLng!,
                                    icon: BitmapDescriptor.defaultMarkerWithHue(
                                      BitmapDescriptor.hueGreen,
                                    ),
                                  ),
                                },
                          onMapCreated: (controller) =>
                              _mapController = controller,
                          onTap: _onMapTap,
                          myLocationButtonEnabled: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        loc.orTapMap,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white60 : Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Image Upload Section
                    Text(
                      loc.uploadImages,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.upToFiveImages,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Selected Images Grid
                    if (_selectedImages.isNotEmpty)
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 12),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: primaryColor.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.file(
                                        _selectedImages[index],
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _selectedImages.removeAt(index),
                                      ),
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                    if (_selectedImages.isNotEmpty) const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 22,
                        ),
                        label: Text(
                          '${loc.selectImages} (${_selectedImages.length}/5)',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    _isSubmitting
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
                                      primaryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  loc.submitting,
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.send_rounded, size: 24),
                              label: Text(
                                loc.submitActivity,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: _submitActivity,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
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
