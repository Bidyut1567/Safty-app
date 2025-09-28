import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:safty_app/contact/contactpagelist.dart';
import 'package:safty_app/emergencypage.dart';
import 'package:safty_app/loginpage.dart';
import 'package:safty_app/registerpage.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await requestBluetoothPermissions();
  //await FlutterBluePlus.initialize(license: "YOUR_LICENSE_KEY");

  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
    );
  }
}

// Future<void> requestBluetoothPermissions() async {
//   if (Platform.isAndroid) {
//     // For Android 12+
//     await [
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.bluetoothAdvertise,
//       Permission.location, // for older Android
//     ].request();
//   } else if (Platform.isIOS) {
//     await [Permission.bluetooth, Permission.location].request();
//   }
// }
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // While Firebase is checking
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ✅ If user is logged in
        if (snapshot.hasData) {
          return EmergencyPage(username: snapshot.data!.email ?? "unknown");
        }

        // ❌ If user is not logged in
        return const Loginpage();
      },
    );
  }
}
