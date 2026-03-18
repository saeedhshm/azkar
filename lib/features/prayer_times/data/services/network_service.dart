import 'dart:io';

import 'package:http/http.dart' as http;

class NetworkService {
  Future<bool> isOnline() async {
    try {
      final response = await http
          .get(Uri.parse('https://clients3.google.com/generate_204'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 204 || response.statusCode == 200) {
        return true;
      }
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
