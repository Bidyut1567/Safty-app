import 'package:flutter/services.dart';

class ContactService {
  static const MethodChannel _channel = MethodChannel(
    'com.safty_gadgate.safty_app/contacts',
  );

  static Future<List<Map<String, String>>> getContacts() async {
    try {
      final List<dynamic> contacts = await _channel.invokeMethod('getContacts');
      return contacts
          .cast<Map>()
          .map(
            (c) => {
              'name': c['name'].toString(),
              'phone': c['phone'].toString(),
            },
          )
          .toList();
    } catch (e) {
      print("Error fetching contacts: $e");
      return [];
    }
  }
}
