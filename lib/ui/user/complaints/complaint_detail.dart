import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:swachhata_app/l10n/app_localizations.dart';

class ComplaintDetail extends StatefulWidget {
  final QueryDocumentSnapshot data;

  const ComplaintDetail({super.key, required this.data});

  @override
  State<ComplaintDetail> createState() => _ComplaintDetailState();
}

class _ComplaintDetailState extends State<ComplaintDetail> {
  // Red theme colors matching the Complaints dashboard box
  final Color primaryColor = const Color(0xFFEF5350);
  final Color primaryDark = const Color(0xFFE53935);
  final LinearGradient primaryGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF5350), Color(0xFFE53935)],
  );

  void _showFullImageDialog(
    BuildContext context,
    String imageUrl,
    String failedLabel,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: double.infinity,
                    height: 400,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_rounded,
                          size: 80,
                          color: primaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          failedLabel,
                          style: TextStyle(
                            color: primaryDark,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDarkMode
        ? const Color(0xFF121212)
        : const Color(0xFFF5F7FA);
    final Color cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    final loc = AppLocalizations.of(context)!;
    final complaint = widget.data.data() as Map<String, dynamic>;

    final imageUrl = complaint['imageUrl'] ?? '';
    final type = complaint['type'] ?? loc.unknown;
    final description = complaint['description'] ?? loc.noDescription;
    final statusRaw = complaint['status'] ?? 'Pending';
    final latitude = (complaint['latitude'] ?? 0.0).toDouble();
    final longitude = (complaint['longitude'] ?? 0.0).toDouble();
    final address = complaint['address'] ?? loc.addressNotAvailable;
    final createdAt = complaint['createdAt'] as Timestamp?;
    final formattedDate = createdAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toDate())
        : loc.unknownDate;

    // localized status label
    String localizedStatus() {
      final s = statusRaw.toString().toLowerCase();
      if (s.contains('resolved')) return loc.complaintResolved;
      if (s.contains('rejected')) return loc.complaintRejected;
      if (s.contains('progress') || s.contains('in-progress'))
        return loc.complaintInProgress;
      if (s.contains('submitted') || s.contains('pending'))
        return loc.complaintPending;
      return statusRaw.toString();
    }

    Color _getStatusColor(String status) {
      final s = status.toLowerCase();
      if (s.contains('resolved')) return Colors.green.shade600;
      if (s.contains('in progress') ||
          s.contains('progress') ||
          s.contains('in-progress'))
        return Colors.orange.shade600;
      if (s.contains('pending') || s.contains('submitted'))
        return Colors.blue.shade600;
      if (s.contains('rejected')) return Colors.red.shade600;
      return primaryColor;
    }

    IconData _getStatusIcon(String status) {
      final s = status.toLowerCase();
      if (s.contains('resolved')) return Icons.check_circle_rounded;
      if (s.contains('in progress') || s.contains('progress'))
        return Icons.autorenew_rounded;
      if (s.contains('submitted') || s.contains('pending'))
        return Icons.access_time_rounded;
      if (s.contains('rejected')) return Icons.cancel_rounded;
      return Icons.help_rounded;
    }

    final statusColor = _getStatusColor(statusRaw.toString());
    final statusIcon = _getStatusIcon(statusRaw.toString());

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          type,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
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
                          "Complaint Details",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.95),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "ID: #${widget.data.id.substring(0, 8).toUpperCase()}",
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

            // Main Content Container
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Complaint Image",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _showFullImageDialog(
                          context,
                          imageUrl,
                          loc.failedToLoadImage,
                        ),
                        child: Container(
                          width: double.infinity,
                          height: 220,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                // Image
                                Image.network(
                                  imageUrl,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: primaryColor.withOpacity(0.1),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.photo_camera_back_rounded,
                                              size: 60,
                                              color: primaryColor,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              loc.imageNotAvailable,
                                              style: TextStyle(
                                                color: primaryDark,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                ),
                                // Zoom overlay
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black.withOpacity(0.2),
                                    child: Center(
                                      child: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.9),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.zoom_in_rounded,
                                          color: primaryColor,
                                          size: 30,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Tap to view full image",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white60 : Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Status and Type Section
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Complaint Type",
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: primaryColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.report_problem_rounded,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      type,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Status",
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: statusColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, color: statusColor, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  localizedStatus(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Submitted Date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Submitted Date",
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF2D2D2D)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDarkMode
                                ? const Color(0xFF3D3D3D)
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              color: primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Description
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description_rounded,
                            color: primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            loc.description,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF2D2D2D)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDarkMode
                                ? const Color(0xFF3D3D3D)
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                        child: Text(
                          description,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Address
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            loc.addressLabel,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF2D2D2D)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDarkMode
                                ? const Color(0xFF3D3D3D)
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.pin_drop_rounded,
                              color: primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                address,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.4,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Map View
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.map_rounded,
                            color: primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            loc.locationOnMap,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
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
                            initialCameraPosition: CameraPosition(
                              target: LatLng(latitude, longitude),
                              zoom: 16,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId("complaint_location"),
                                position: LatLng(latitude, longitude),
                                infoWindow: InfoWindow(title: type),
                                icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueRed,
                                ),
                              ),
                            },
                            zoomControlsEnabled: true,
                            myLocationButtonEnabled: false,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Tap and drag to explore the location",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white60 : Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
