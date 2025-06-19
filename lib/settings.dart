import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'user_dashboard.dart'; // Import your UserDashboard screen
import 'notifications.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? userName;
  String? userEmail;
  bool isDarkMode = false; // Variable to track the theme
  bool themeChanged = false; // Flag to check if the theme was toggled

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTheme();
  }
  void _navigateToNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NotificationsPage()),
    );
  }
  // Load user data from SharedPreferences
  void _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? 'No Username'; // Default if null
      userEmail = prefs.getString('user_email') ?? 'No Email'; // Default if null
    });
  }

  // Load theme preference from SharedPreferences
  void _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false; // Default is false (light mode)
    });
  }

  // Toggle theme and save preference
  void _toggleTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = !isDarkMode;
      prefs.setBool('isDarkMode', isDarkMode);
      themeChanged = true; // Set the flag to true when theme is changed
    });
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
      backgroundColor: isDarkMode ? Colors.black : Colors.white, // Background color change based on theme
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AnimatedContainer(
          duration: themeChanged ? const Duration(seconds: 1) : Duration.zero, // Apply transition only if themeChanged
          curve: Curves.easeInOut,
          color: isDarkMode ? Colors.black : Colors.white, // AppBar color
          child: AppBar(
            backgroundColor: isDarkMode ? Colors.black : Colors.white, // Set app bar background color explicitly
            elevation: 0,
            iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
            title: AnimatedSwitcher(
              duration: themeChanged ? const Duration(seconds: 1) : Duration.zero, // Apply transition only if themeChanged
              child: Text(
                'Settings',
                key: ValueKey<bool>(isDarkMode), // Key to trigger animation on theme change
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black), // Title color change
              ),
            ),
            actions: [
              // Dark/Light mode toggle button
              IconButton(
                icon: Icon(isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
                onPressed: _toggleTheme, // Toggle theme
              ),
            ],
          ),
        ),
      ),
      body: AnimatedContainer(
        duration: themeChanged ? const Duration(seconds: 1) : Duration.zero, // Apply transition only if themeChanged
        color: isDarkMode ? Colors.black : Colors.white,
        curve: Curves.easeInOut, // Smooth curve
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Circle PNG Image for the user
                Container(
                  width: 180.0,
                  height: 180.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/profile.png', // PNG image from assets
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                // Username
                Text(
                  userName ?? 'No Username',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8.0),
                // Email
                Text(
                  userEmail ?? 'No Email',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: isDarkMode ? Colors.white70 : Colors.grey,
                  ),
                ),
                const SizedBox(height: 16.0),
                // Logout Button
                ElevatedButton(
                  onPressed: () => _logout(context),
                  child: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Red button background
                    foregroundColor: Colors.white, // White text color
                    padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 12.0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: themeChanged ? const Duration(seconds: 1) : Duration.zero, // Apply transition only if themeChanged
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.black : Colors.white, // Set solid color instead of transparent
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDarkMode ? Colors.black : Colors.white, // Bottom navigation background color based on theme
          selectedItemColor: isDarkMode ? Colors.blue : Colors.blueAccent,
          unselectedItemColor: isDarkMode ? Colors.white70 : Colors.grey,
          iconSize: 25, // Adjust icon size for a clean look
          currentIndex: 2,
          showSelectedLabels: false, // Hides labels below icons
          showUnselectedLabels: false, // Hides labels below icons
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DashboardUserScreen()),
              );
            }
            else if (index == 1) {
              _navigateToNotifications(context);
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}
