// import 'package:shared_preferences/shared_preferences.dart';

// class SessionManager {
//   static const String KEY_USERNAME = "username";
//   static final SessionManager _instance = SessionManager._internal();

//   factory SessionManager() => _instance;
//   SessionManager._internal();

//   Future<void> saveUserSession(String username) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(KEY_USERNAME, username);
//   }

//   Future<String?> getLoggedInUser() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(KEY_USERNAME);
//   }

//   Future<void> clearSession() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(KEY_USERNAME);
//   }
// }
