import 'package:shared_preferences/shared_preferences.dart';

class DriverLocalStorage {
  static Future<void> saveDriver(Map<String, dynamic> data) async {
    final pref = await SharedPreferences.getInstance();

    await pref.setString("driverId", data['uid'] ?? "");
    await pref.setString("driverName", data['name'] ?? "");
    await pref.setString("driverEmail", data['email'] ?? "");
    await pref.setString("driverPhone", data['phone'] ?? "");
    await pref.setInt("driverAge", data['age'] ?? 0);
  }

  static Future<Map<String, dynamic>> getDriver() async {
    final pref = await SharedPreferences.getInstance();

    return {
      "uid": pref.getString("driverId"),
      "name": pref.getString("driverName"),
      "email": pref.getString("driverEmail"),
      "phone": pref.getString("driverPhone"),
      "age": pref.getInt("driverAge"),
    };
  }

  static Future<void> clear() async {
    final pref = await SharedPreferences.getInstance();
    await pref.clear();
  }

  static Future<void> init() async {}
}
