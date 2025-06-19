import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'settings.dart'; // Importing the Settings screen file
import 'userpendingrequests.dart';
import 'userhistory.dart';
import 'login.dart';
import 'notifications.dart';
import 'dart:async'; // For async operations

class DashboardUserScreen extends StatefulWidget {
  const DashboardUserScreen({Key? key}) : super(key: key);

  @override
  _DashboardUserScreenState createState() => _DashboardUserScreenState();
}

class _DashboardUserScreenState extends State<DashboardUserScreen> {
  String? userName;
  String? userEmail;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTheme();
    _requestNotificationPermission();
  }

  void _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false; // Default to false (light mode)
    });
  }

  // Load user data from SharedPreferences
  void _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? 'No Username'; // Default if null
      userEmail = prefs.getString('user_email') ?? 'No Email'; // Default if null
    });
  }

  void _navigateToRequestlist(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StationeryScreen()),
    );
  }

  void _navigateToHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserHistory()),
    );
  }

  void _navigateToSettingsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsPage()),
    );
  }

  void _navigateToNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NotificationsPage()),
    );
  }
  Future<void> _requestNotificationPermission() async {
    PermissionStatus status = await Permission.notification.request();

    if (status.isGranted) {
      // Permission granted: You can add any logic here, like enabling notifications in your app.
    } else if (status.isDenied) {
      // Permission denied: Handle the logic for denied permission here.
    } else if (status.isPermanentlyDenied) {
      // Permission permanently denied: Optionally guide the user to app settings.
      openAppSettings();
    }
  }

  Future<void> _showDialog(BuildContext context, String title, String content) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.white70 : Colors.white, // Adjust background color
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),

            ),
          ],
        );
      },
    );
  }

  // Logout functionality
  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.white70 : Colors.white, // Adjust background color
          title: Text(
            'Logout',
            style: TextStyle(
              color: isDarkMode ? Colors.black : Colors.black, // Adjust title color
            ),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: TextStyle(
              color: isDarkMode ? Colors.black : Colors.black, // Adjust content color
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDarkMode ? Colors.blueGrey : Colors.blue, // Adjust button color
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Logout',
                style: TextStyle(
                  color: isDarkMode ? Colors.redAccent : Colors.red, // Adjust button color
                ),
              ),
            ),
          ],
        );
      },
    );


    if (shouldLogout != true) return; // User pressed Cancel, so exit.

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      await _showDialog(context, 'Logout Error', 'No token found. You are already logged out.');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
      return;
    }

    final response = await http.post(
      Uri.parse('http://edharti.eu-north-1.elasticbeanstalk.com/api/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('Logout Response: ${response.statusCode}');
    print('Logout Body: ${response.body}');

    if (response.statusCode == 200) {
      // Successfully logged out, remove token and user email
      await prefs.remove('auth_token');
      await prefs.remove('user_email');
      await _showDialog(context, 'Success', 'Logged out successfully.');

      // Redirect to Login screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    } else {
      // Log out failed, show error message
      await _showDialog(context, 'Logout Failed', 'Failed to log out. Status: ${response.statusCode}\n${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        toolbarHeight: 60,
        automaticallyImplyLeading: false, // Remove back button
        title: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isDarkMode ? Colors.blueGrey : Colors.white,
              child: ClipOval(
                child: Image.asset(
                  'assets/profile.png', // Path to profile picture
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, ${userName ?? 'Guest'}',  // Safe fallback if userName is null
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  userEmail ?? 'No Email',  // Safe fallback if userEmail is null
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(3.0),  // Adjust padding if needed
                      child: GestureDetector(
                        onTap: () => _logout(context),  // Handle the tap event
                        child: SvgPicture.asset(
                          'assets/logout.svg',  // Replace with your SVG file path
                          height: 22.0,  // Adjust the icon size as needed
                          width: 22.0,
                          color: Colors.blue,  // Adjust the icon color as needed
                        ),
                      ),
                    ),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 10,  // Small text size
                        color: Colors.blue,  // Same color as the icon
                      ),
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  DashboardCard(
                    svgPath: 'assets/administrative-approval.svg', // Example SVG path
                    label: 'Request Items',
                    onTap: () => _navigateToRequestlist(context),
                    isDarkMode: isDarkMode, // Pass isDarkMode to DashboardCard
                  ),
                  DashboardCard(
                    svgPath: 'assets/history_svgrepo.com.svg', // Example SVG path
                    label: 'History',
                    onTap: () => _navigateToHistory(context),
                    isDarkMode: isDarkMode, // Pass isDarkMode to DashboardCard
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDarkMode ? Colors.black : Colors.white, // Bottom navigation background color based on theme
        selectedItemColor: isDarkMode ? Colors.blue : Colors.blueAccent,
        unselectedItemColor: isDarkMode ? Colors.white70 : Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        iconSize: 25,
        onTap: (index) {
          // Navigate to Settings when the last tab is tapped
          if (index == 2) {
            _navigateToSettingsScreen(context);
          }
          else if (index == 1) {
            _navigateToNotifications(context);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String svgPath;
  final String label;
  final VoidCallback onTap;
  final bool isDarkMode; // Accept isDarkMode as a parameter

  const DashboardCard({
    Key? key,
    required this.svgPath,
    required this.label,
    required this.onTap,
    required this.isDarkMode, // Initialize it here
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white, // Adjust based on dark mode
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black.withOpacity(0.6) : Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              svgPath,
              height: 60.0,
              // color: isDarkMode ? Colors.white : Colors.black,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
