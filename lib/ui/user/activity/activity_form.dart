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

  // Color scheme
  final Color _primaryColor = Colors.teal;
  final Color _primaryDark = Color(0xFF00695C);
  final Color _primaryLight = Color(0xFF4DB6AC);
  final Color _backgroundColor = Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;

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
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.failedToGetLocation}: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
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
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
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
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    // 💾 Save to Firestore with full address
    await FirebaseFirestore.instance.collection('activities').add({
      'userId': user.uid,
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'address': _locationController.text.trim(), // ✅ Save full address
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
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          loc.submitActivity,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.activityTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: _primaryDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: loc.enterActivityTitle,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _primaryLight),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _primaryColor),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (v) =>
                            v!.isEmpty ? loc.enterTitleValidation : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description Field
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.description,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: _primaryDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: loc.describeActivity,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _primaryLight),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _primaryColor),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (v) =>
                            v!.isEmpty ? loc.enterDescriptionValidation : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Location Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.location,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: _primaryDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          hintText: loc.selectLocationOnMapHint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _primaryLight),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _primaryColor),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: Icon(
                            Icons.location_on,
                            color: _primaryColor,
                          ),
                        ),
                        readOnly: true,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _useCurrentLocation,
                          icon: Icon(Icons.my_location, size: 20),
                          label: Text(loc.useCurrentLocation),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryLight,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          loc.orTapMap,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Map Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.map, color: _primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            loc.selectLocationOnMapTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: _primaryDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _primaryLight, width: 1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
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
                                      icon:
                                          BitmapDescriptor.defaultMarkerWithHue(
                                            BitmapDescriptor.hueAzure,
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Image Upload Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.photo_library,
                            color: _primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            loc.uploadImages,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: _primaryDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        loc.upToFiveImages,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),

                      // Selected Images Grid
                      if (_selectedImages.isNotEmpty)
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.only(right: 12),
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _primaryLight,
                                          width: 1,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          _selectedImages[index],
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                          onPressed: () => setState(
                                            () =>
                                                _selectedImages.removeAt(index),
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 24,
                                            minHeight: 24,
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

                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.add_photo_alternate, size: 20),
                          label: Text(
                            '${loc.selectImages} (${_selectedImages.length}/5)',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: _primaryColor),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    icon: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, size: 24),
                    label: Text(
                      _isSubmitting ? loc.submitting : loc.submitActivity,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _submitActivity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: _primaryColor.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
