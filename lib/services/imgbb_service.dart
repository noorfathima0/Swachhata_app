import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ImgBBService {
  final String apiKey =
      "3904540c5fe1debda35b0d085c88c6ea"; // Replace with your actual key

  Future<String> uploadImage(File imageFile) async {
    final url = Uri.parse("https://api.imgbb.com/1/upload?key=$apiKey");
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(url, body: {"image": base64Image});

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse["data"]["display_url"]; // Returns public image URL
    } else {
      throw Exception("Failed to upload image to ImgBB: ${response.body}");
    }
  }
}
