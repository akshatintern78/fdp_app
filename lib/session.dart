import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'models.dart';

class Session extends ChangeNotifier {
  static const _tokenKey = 'fdp_token';
  static const _userKey = 'fdp_user';

  String? token;
  AppUser? user;
  bool ready = false;

  Api get api => Api(token);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_tokenKey);
    final rawUser = prefs.getString(_userKey);
    if (rawUser != null) {
      user = AppUser.fromJson(jsonDecode(rawUser) as Map<String, dynamic>);
    }
    ready = true;
    notifyListeners();
    if (token == null) return;
    try {
      user = await api.me();
      await prefs.setString(_userKey, jsonEncode(user!.toJson()));
      notifyListeners();
    } on ApiException catch (error) {
      if (error.status == 401) {
        token = null;
        user = null;
        await prefs.remove(_tokenKey);
        await prefs.remove(_userKey);
        notifyListeners();
      }
    } catch (_) {
      // Keep the saved session if the server is briefly unreachable.
    }
  }

  Future<void> login(String email, String password) async {
    final result = await api.login(email.trim(), password);
    token = result.token;
    user = result.user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token!);
    await prefs.setString(_userKey, jsonEncode(user!.toJson()));
    notifyListeners();
  }

  Future<void> logout() async {
    token = null;
    user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    notifyListeners();
  }
}
