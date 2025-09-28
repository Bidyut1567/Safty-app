import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'bluthoot .dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key, required String username});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  List<Map<String, String>> devices = [];
  String? savedAddress;
  String? savedName;
  bool connecting = false;

  @override
  void initState() {
    super.initState();
    _loadSavedDevice();
    _startDynamicScan();
  }

  Future<void> _loadSavedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedAddress = prefs.getString("device_address");
      savedName = prefs.getString("device_name");
    });
  }

  void _startDynamicScan() async {
    bool isOn = await BluetoothService.isBluetoothOn();
    if (!isOn) await BluetoothService.enableBluetooth();

    BluetoothService.scanDevicesStream.listen((device) {
      if (!devices.any((d) => d['address'] == device['address'])) {
        setState(() => devices.add(device));
        if (device['address'] == savedAddress) {
          connectToDevice(
            savedAddress!,
            savedName ?? "Saved Device",
            auto: true,
          );
        }
      }
    });
  }

  Future<void> connectToDevice(
    String address,
    String name, {
    bool auto = false,
  }) async {
    if (connecting) return;
    setState(() => connecting = true);

    bool connected = await BluetoothService.connectDevice(address);

    if (connected) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString("device_address", address);
      prefs.setString("device_name", name);

      if (!auto) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Connected to $name")));
      }
      Navigator.pop(context); // Go back
    } else {
      if (!auto) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to connect $name")));
      }
    }

    setState(() => connecting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                devices.clear();
              });
              _startDynamicScan();
            },
          ),
        ],
      ),
      body: devices.isEmpty
          ? const Center(child: Text("Scanning for Bluetooth devices..."))
          : ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return ListTile(
                  title: Text(device['name'] ?? 'Unknown'),
                  subtitle: Text(device['address'] ?? ''),
                  trailing: ElevatedButton(
                    onPressed: () => connectToDevice(
                      device['address']!,
                      device['name'] ?? "Unknown",
                    ),
                    child: const Text('Connect'),
                  ),
                );
              },
            ),
    );
  }
}
