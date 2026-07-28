import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileService {
  static const String profileUrl = 'http://54.255.150.15/mobile-api/profile';

  static Future<bool> fetchAndSaveProfile({
    required String memberCode,
  }) async {
    if (memberCode.isEmpty) return false;

    final response = await http.post(
      Uri.parse(profileUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'member_code': memberCode}),
    );

    if (response.statusCode != 200) return false;

    final data = jsonDecode(response.body);
    if (data is! Map || data['success'] != true || data['user'] == null) {
      return false;
    }

    final user = Map<String, dynamic>.from(data['user'] as Map);
    final prefs = await SharedPreferences.getInstance();
    await saveUser(user, prefs: prefs, fallbackMemberCode: memberCode);

    return true;
  }

  static Future<void> saveUser(
    Map<String, dynamic> user, {
    SharedPreferences? prefs,
    String fallbackMemberCode = '',
  }) async {
    final storage = prefs ?? await SharedPreferences.getInstance();

    await storage.setString('name', _asString(user['name']));
    await storage.setString('email', _asString(user['email']));
    await storage.setString('phone', _asString(user['phone']));
    await storage.setString('address', _asString(user['address']));
    await storage.setString(
      'member_code',
      _asString(user['member_code'], fallbackMemberCode),
    );
    await storage.setInt('total_points', _asInt(user['total_points']));
    await storage.remove('earned_points');
  }

  static String _asString(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    return value.toString();
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
