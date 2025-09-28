import 'package:flutter/material.dart';
import 'package:safty_app/bluthoot/flutter_blue_puls.dart';
import 'package:safty_app/contact/contact.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ContactListPage extends StatefulWidget {
  final Function(String name, String phone) onContactSelected;
  final String username; // still passed, but we won’t use it for DB path

  const ContactListPage({
    super.key,
    required this.onContactSelected,
    required this.username,
  });

  @override
  State<ContactListPage> createState() => _ContactListPageState();
}

class _ContactListPageState extends State<ContactListPage> {
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _filteredContacts = [];
  TextEditingController _searchController = TextEditingController();
  Set<String> _selectedNumbers = {};

  @override
  void initState() {
    super.initState();
    fetchContacts();
    _searchController.addListener(_filterContacts);
  }

  void fetchContacts() async {
    final rawContacts = await ContactService.getContacts();

    final List<Map<String, dynamic>> mergedContacts = [];

    for (var c in rawContacts) {
      final name = (c['name'] ?? '').trim();
      final phone = (c['phone'] ?? '').replaceAll(RegExp(r'\s+'), '');

      if (name.isEmpty || phone.isEmpty) continue;

      // merge contacts with same name
      final existing = mergedContacts.indexWhere((e) => e['name'] == name);
      if (existing == -1) {
        mergedContacts.add({
          'name': name,
          'phones': [phone],
        });
      } else {
        (mergedContacts[existing]['phones'] as List).add(phone);
      }
    }

    setState(() {
      _contacts = mergedContacts;
      _filteredContacts = mergedContacts;
    });
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = _contacts.where((contact) {
        final nameMatch = contact['name']!.toLowerCase().contains(query);
        final phoneMatch = (contact['phones'] as List).any(
          (p) => p.toLowerCase().contains(query),
        );
        return nameMatch || phoneMatch;
      }).toList();
    });
  }

  /// Utility: format phone number into E.164 (+91XXXXXXXXXX)
  String formatPhoneNumber(String number) {
    // Remove spaces, dashes, brackets etc.
    number = number.replaceAll(RegExp(r'\D'), '');

    // If starts with country code already (91...), add "+"
    if (number.startsWith('91') && number.length == 12) {
      return '+$number';
    }

    // If it's a 10-digit Indian number, prefix with +91
    if (number.length == 10) {
      return '+91$number';
    }

    // Otherwise just add "+"
    return '+$number';
  }

  Future<void> saveEmergencyContacts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("User not logged in")));
      return;
    }

    final databaseRef = FirebaseDatabase.instance.ref(
      "emergency_contacts/${user.uid}",
    );

    // Format selected numbers
    final formattedNumbers = _selectedNumbers
        .map((num) => formatPhoneNumber(num))
        .toList();

    // ✅ Get existing contacts
    final snapshot = await databaseRef.get();
    List<String> existingContacts = [];
    if (snapshot.exists && snapshot.value != null) {
      if (snapshot.value is List) {
        existingContacts = List<String>.from(snapshot.value as List);
      } else if (snapshot.value is Map) {
        existingContacts = (snapshot.value as Map).values
            .map((e) => e.toString())
            .toList();
      }
    }

    // ✅ Merge old + new (avoid duplicates)
    final mergedContacts = {...existingContacts, ...formattedNumbers}.toList();

    // ✅ Save merged list
    await databaseRef.set(mergedContacts);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Emergency contacts saved")));

    Navigator.pop(context); // go back after saving
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Contact"),
        backgroundColor: const Color(0xFFF5F7FA),
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: fetchContacts, // reload contacts when pressed
            tooltip: "Reload Contacts",
          ),
        ],
      ),

      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search contact",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredContacts.isEmpty
                ? Center(child: Text("No contacts found"))
                : ListView.builder(
                    itemCount: _filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      final List<String> phones = List<String>.from(
                        contact['phones'],
                      );

                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(0xFF1F2A40),
                            child: Text(
                              contact['name']!.isNotEmpty
                                  ? contact['name']![0].toUpperCase()
                                  : '?',
                              style: TextStyle(color: Color(0xFFE8C07D)),
                            ),
                          ),
                          title: Text(contact['name'] ?? ''),
                          children: phones.map((phone) {
                            return CheckboxListTile(
                              title: Text(phone),
                              value: _selectedNumbers.contains(phone),
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedNumbers.add(phone);
                                  } else {
                                    _selectedNumbers.remove(phone);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton(
              onPressed: saveEmergencyContacts,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1F2A40),
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Save Emergency Contacts",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
