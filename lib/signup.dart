import 'package:flutter/material.dart';
import 'login.dart'; // Import login.dart

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ClipPath(
                  child: Image.asset(
                    'assets/rastrapatibhavan.png',
                    width: double.infinity,
                    height: 280,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 150,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      child: ClipOval(
                        child: Image.asset(
                          'assets/emblem.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'Welcome to e-Dharti application',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            // Email TextField
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextField(
                style: TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Enter Email',
                  labelStyle: TextStyle(fontSize: 14),
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6.0)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Mobile Number TextField
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextField(
                style: TextStyle(fontSize: 14),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Enter Mobile Number',
                  labelStyle: TextStyle(fontSize: 14),
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6.0)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Password TextField
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextField(
                style: TextStyle(fontSize: 14),
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Enter password',
                  labelStyle: TextStyle(fontSize: 14),
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6.0)),
                  suffixIcon: Icon(Icons.visibility),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Repeat Password TextField
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextField(
                style: TextStyle(fontSize: 14),
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Repeat password',
                  labelStyle: TextStyle(fontSize: 14),
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6.0)),
                  suffixIcon: Icon(Icons.visibility),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Signup Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    textStyle: TextStyle(fontSize: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.0), // Less border radius
                    ),
                    elevation: 5, // Adds shadow to the button
                  ),
                  onPressed: () {
                    // Your onPressed logic for signup
                  },
                  child: Text('Signup'),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34.0),
              child: Row(
                children: [
                  Expanded(
                    child: Divider(color: Colors.blue, thickness: 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        // Navigate back to the LoginScreen
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        'or Login with Username & Password',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Colors.blue, thickness: 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
            const Text(
              'Copyright © 2024 LDO. All Rights Reserved',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
