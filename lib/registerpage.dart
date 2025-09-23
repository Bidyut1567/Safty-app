import 'dart:ui';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:safty_app/loginpage.dart';
class Registerpage extends StatefulWidget {
  const Registerpage({super.key});

  @override
  State<Registerpage> createState() => _RegisterpageState();
}

class _RegisterpageState extends State<Registerpage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  final databaseRef = FirebaseDatabase.instance.ref("users"); // Realtime DB reference

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void registerUser() async {
    String username = usernameController.text.trim();
    String password = passwordController.text.trim();

    if(username.isEmpty || password.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Username & Password cannot be empty"))
      );
      return;
    }

    try {
      await databaseRef.child(username).set({
        "password": password,
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User registered successfully"))
      );

      Navigator.push(
          context,
          MaterialPageRoute(builder: (c)=> Loginpage())
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error registering user"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey.shade800, Colors.black87],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: GlassmorphicCard(
            usernameController: usernameController,
            passwordController: passwordController,
            registerUser: registerUser,
          ),
        ),
      ),
    );
  }
}

class GlassmorphicCard extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final VoidCallback registerUser;

  GlassmorphicCard({
    required this.usernameController,
    required this.passwordController,
    required this.registerUser,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: 350,
          padding: EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              width: 1.5,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Register",
                style: TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 25),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  hintText: "Username",
                  hintStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Password",
                  hintStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none),
                ),
              ),
              SizedBox(height: 25),
              ElevatedButton(
                onPressed: registerUser,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                  backgroundColor: Colors.white.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  "Register",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
