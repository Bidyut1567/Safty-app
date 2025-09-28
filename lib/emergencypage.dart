import 'dart:async';
import 'package:flutter/material.dart';
import 'package:safty_app/bluthoot/flutter_blue_puls.dart';
import 'package:safty_app/contact/contactpagelist.dart';
import 'package:safty_app/notification.dart';
// make sure this file exists and is imported

class EmergencyPage extends StatefulWidget {
  final String username;

  const EmergencyPage({super.key, required this.username});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  String connectedBluetoothName = "Not connected";

  @override
  void initState() {
    super.initState();

    // Fade-in for page elements
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeController.forward();

    // Pulse for emergency button (0.0-1.0 for safe opacity)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void sendEmergencyAlert() async {
    const message = "⚠️ Emergency! I need help immediately.";
    await EmergencyService.notifyAllContacts(widget.username, message);

    // SOS Ripple Animation
    _showSOSRipple();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Emergency alert sent!")));
  }

  // SOS Ripple
  void _showSOSRipple() {
    OverlayState? overlayState = Overlay.of(context);
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) {
                double scale = 100 + 30 * _pulseController.value;
                double opacity = (0.4 * (1 - _pulseController.value)).clamp(
                  0.0,
                  1.0,
                );
                return Container(
                  width: scale,
                  height: scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(opacity),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    overlayState?.insert(overlayEntry);
    Timer(const Duration(seconds: 1), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      drawer: _buildDrawer(),
      appBar: AppBar(
        title: const Text("Emergency Dashboard"),
        centerTitle: true,
        backgroundColor: Colors.red.shade700,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FadeTransition(
          opacity: _fadeController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildUserCard(),
              const SizedBox(height: 20),
              _buildEmergencyButton(),
              const SizedBox(height: 15),
              _buildConnectBluetoothButton(),
              const SizedBox(height: 10),
              Text(
                "Connected: $connectedBluetoothName",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 30),
              Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 15),
              // Fix GridView height to avoid layout issues
              SizedBox(height: 300, child: _buildQuickActions()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard() {
    return Hero(
      tag: "user_card",
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.red.shade300,
              child: Text(
                widget.username.isNotEmpty
                    ? widget.username[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 28, color: Colors.white),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.username,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Last emergency: None",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.verified_user, color: Colors.green.shade400, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyButton() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          ScaleTransition(
            scale: _pulseController,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.3),
              ),
            ),
          ),
          SizedBox(
            width: 120,
            height: 120,
            child: ElevatedButton(
              onPressed: sendEmergencyAlert,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: Colors.red.shade700,
                elevation: 8,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                  SizedBox(height: 4),
                  Text(
                    "SOS",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectBluetoothButton() {
    return ElevatedButton.icon(
      onPressed: () async {
        final deviceName = await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) =>
                BluetoothPage(username: widget.username),
            transitionsBuilder: (_, a, __, c) =>
                FadeTransition(opacity: a, child: c),
          ),
        );

        if (deviceName != null) {
          setState(() {
            connectedBluetoothName = deviceName;
          });
        }
      },
      icon: const Icon(Icons.bluetooth, color: Colors.white),
      label: const Text(
        "Connect Bluetooth",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: Colors.blue.shade600,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 6,
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      children: [
        _buildActionCard(
          Icons.notifications_active,
          "Notifications",
          Colors.orange,
          () {},
        ),
        _buildActionCard(Icons.contact_page, "Contacts", Colors.blue, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ContactListPage(
                onContactSelected: (name, phone) {},
                username: widget.username,
              ),
            ),
          );
        }),
        _buildActionCard(Icons.map, "Location", Colors.green, () {}),
        _buildActionCard(Icons.help, "Help Tips", Colors.purple, () {}),
      ],
    );
  }

  Widget _buildActionCard(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.red.shade700),
            child: Text(
              widget.username,
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
