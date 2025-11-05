import 'package:location/location.dart';

class LocationService {
  final Location _location = Location();

  Future<Map<String, double>> getCurrentLocation() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) throw Exception("Location service not enabled");
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        throw Exception("Location permission denied");
      }
    }

    final locData = await _location.getLocation();
    return {
      'latitude': locData.latitude ?? 0.0,
      'longitude': locData.longitude ?? 0.0,
    };
  }
}
