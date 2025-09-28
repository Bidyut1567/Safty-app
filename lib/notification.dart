import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';

class EmergencyService {
  /// Fetch emergency contacts safely from Firebase
  static Future<List<String>> getEmergencyContacts(String uid) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final databaseRef = FirebaseDatabase.instance.ref(
        "emergency_contacts/${user?.uid}",
      );
      final snapshot = await databaseRef.get();

      if (!snapshot.exists || snapshot.value == null) return [];

      final data = snapshot.value;

      if (data is List) {
        return data.cast<String>();
      } else if (data is Map) {
        return data.values.map((e) => e.toString()).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching contacts: $e");
      return [];
    }
  }

  /// Send emergency message to all contacts via backend
  static Future<void> notifyAllContacts(String uid, String message) async {
    try {
      final contacts = await getEmergencyContacts(uid);
      if (contacts.isEmpty) {
        print("No emergency contacts found for UID: $uid");
        return;
      }

      final url = Uri.parse('https://backend-4ewz.onrender.com/send-emergency');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message, 'contacts': contacts}),
      );

      if (response.statusCode == 200) {
        print("Emergency messages sent to: $contacts");
      } else {
        print(
          "Failed to send emergency: ${response.statusCode}, ${response.body}",
        );
      }
    } catch (e) {
      print('Error sending emergency: $e');
    }
  }
}
