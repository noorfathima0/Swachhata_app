import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' hide Location;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swachhata_app/services/imgbb_service.dart';

class EventFormPage extends StatefulWidget {
  const EventFormPage({super.key});

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<EventFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime? _eventDate;
  List<File> _mediaFiles = [];
  LatLng? _pickedLocation;
  bool _isSaving = false;

  final ImgBBService _imgBBService = ImgBBService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  GoogleMapController? _mapController;
  Marker? _locationMarker;

  // 🖼️ Pick multiple images
  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      final newFiles = picked.map((e) => File(e.path)).toList();
      if (_mediaFiles.length + newFiles.length > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade600,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "You can upload up to 5 images only",
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
      } else {
        setState(() => _mediaFiles.addAll(newFiles));
      }
    }
  }

  // 📍 Get current location
  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isSaving = true);
      final location = Location();
      final locData = await location.getLocation();
      final newPosition = LatLng(locData.latitude!, locData.longitude!);
      setState(() => _pickedLocation = newPosition);
      await _getAddressFromLatLng(newPosition);
      _moveCamera(newPosition);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "Failed to get location: $e",
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

  // 📍 Reverse geocode
  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address =
            "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
        setState(() {
          _locationController.text = address;
          _locationMarker = Marker(
            markerId: const MarkerId("picked_location"),
            position: position,
            infoWindow: InfoWindow(title: address),
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "Failed to fetch address",
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
    }
  }

  void _moveCamera(LatLng pos) =>
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 15));

  // 💾 Save event
  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "Please fill all required fields",
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

    if (_eventDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "Please select event date and time",
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

    if (_pickedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "Please select event location on map",
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
      final mediaUrls = <String>[];
      for (final file in _mediaFiles) {
        final url = await _imgBBService.uploadImage(file);
        mediaUrls.add(url);
      }

      await _firestore.collection('events').add({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'eventDate': Timestamp.fromDate(_eventDate!),
        'address': _locationController.text.trim(),
        'latitude': _pickedLocation!.latitude,
        'longitude': _pickedLocation!.longitude,
        'mediaUrls': mediaUrls,
        'interestedUsers': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF27AE60),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Event created successfully!",
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
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "Failed to create event: $e",
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // 🖼️ Show full image in dialog
  void _showFullImage(File image) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.85),
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: Image.file(
                  image,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 100,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Create New Event",
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
                            Icons.edit_rounded,
                            color: Color(0xFF2C5F2D),
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Event Details",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    _buildTextField(
                      controller: _titleController,
                      label: "Event Title",
                      icon: Icons.title_rounded,
                      validator: (v) =>
                          v == null || v.isEmpty ? "Title required" : null,
                    ),
                    SizedBox(height: 16),

                    _buildTextField(
                      controller: _descController,
                      label: "Description",
                      icon: Icons.description_rounded,
                      maxLines: 3,
                    ),
                    SizedBox(height: 20),

                    // 📍 Location Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.location_on_rounded,
                                color: Colors.red.shade600,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Location",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          controller: _locationController,
                          readOnly: true,
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                "Select location on map or use current location",
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            prefixIcon: Container(
                              padding: EdgeInsets.all(12),
                              margin: EdgeInsets.only(right: 12),
                              child: Icon(
                                Icons.place_rounded,
                                color: Color(0xFF2C5F2D),
                              ),
                            ),
                            suffixIcon: Container(
                              margin: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Color(0xFF2C5F2D).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.my_location_rounded,
                                  color: Color(0xFF2C5F2D),
                                  size: 20,
                                ),
                                onPressed: _getCurrentLocation,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Color(0xFF2C5F2D),
                                width: 2,
                              ),
                            ),
                            contentPadding: EdgeInsets.all(16),
                          ),
                        ),
                        SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 250,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(13.2563, 76.4775),
                                zoom: 12,
                              ),
                              onMapCreated: (controller) =>
                                  _mapController = controller,
                              markers: _locationMarker != null
                                  ? {_locationMarker!}
                                  : <Marker>{},
                              onTap: (pos) async {
                                setState(() => _pickedLocation = pos);
                                await _getAddressFromLatLng(pos);
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Tap on the map to select location",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // 📅 Date & Time Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.calendar_today_rounded,
                                color: Colors.orange.shade600,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Date & Time",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ElevatedButton.icon(
                            icon: Icon(
                              Icons.access_time_rounded,
                              color: Color(0xFF2C5F2D),
                              size: 20,
                            ),
                            label: Text(
                              _eventDate == null
                                  ? "Select Date & Time"
                                  : DateFormat(
                                      'dd MMM yyyy, hh:mm a',
                                    ).format(_eventDate!),
                              style: TextStyle(
                                color: _eventDate == null
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade800,
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
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (time != null) {
                                  setState(() {
                                    _eventDate = DateTime(
                                      date.year,
                                      date.month,
                                      date.day,
                                      time.hour,
                                      time.minute,
                                    );
                                  });
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // 🖼️ Media Section
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.photo_library_rounded,
                          color: Colors.purple.shade600,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Event Images",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Upload up to 5 images",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  SizedBox(height: 16),
                  if (_mediaFiles.isNotEmpty)
                    Column(
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _mediaFiles.map((f) {
                            return Stack(
                              children: [
                                GestureDetector(
                                  onTap: () => _showFullImage(f),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      f,
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
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade600,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ElevatedButton.icon(
                      icon: Icon(
                        Icons.add_photo_alternate_rounded,
                        color: Color(0xFF2C5F2D),
                        size: 20,
                      ),
                      label: Text(
                        "Add Images (${_mediaFiles.length}/5)",
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
                      onPressed: _pickMedia,
                    ),
                  ),
                ],
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
                  _isSaving ? "Creating Event..." : "Create Event",
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
                onPressed: _isSaving ? null : _saveEvent,
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
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
}
