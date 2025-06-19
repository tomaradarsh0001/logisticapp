import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import 'settings.dart';
import 'login.dart';
import 'user_dashboard.dart';
import 'notifications.dart';

class RequestItemList extends StatefulWidget {
  final List<Map<String, dynamic>?> selectedItems;

  const RequestItemList({Key? key, required this.selectedItems}) : super(key: key);

  @override
  _RequestItemListState createState() => _RequestItemListState();
}

class SmallBadgeCount extends StatelessWidget {
  final int count;

  const SmallBadgeCount({Key? key, required this.count}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Center(
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class BadgeCount extends StatelessWidget {
  final int count;

  const BadgeCount({Key? key, required this.count}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
class _RequestItemListState extends State<RequestItemList> {
  late List<Map<String, dynamic>?> selectedItems;
  String? token;
  String? userName;
  String? userEmail;
  bool isDarkMode = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedItems = widget.selectedItems;
    _loadToken();
    _loadUserData();
    _loadTheme();
  }
  void _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? 'No Username'; // Default if null
      userEmail = prefs.getString('user_email') ?? 'No Email'; // Default if null
    });
  }
  Future<void> _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }
  void _navigateToSettingsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsPage()),
    );
  }

  void _navigateToDashboard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DashboardUserScreen()),
    );
  }

  void _navigateToNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NotificationsPage()),
    );
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
  // Load token from SharedPreferences
  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('auth_token');
    });
  }

  void addItem() {
    setState(() {
      selectedItems.add({
        'label': 'New Item',
        'category_name': 'availableCategories[0]',
        'category_id': 1,
        'lastUpdated': 'No Date',
        'quantity': 1,
      });
    });
  }
  void _searchItems(String query) {

  }
  void deleteItem(int index) {
    setState(() {
      if (selectedItems.length > 1) {
        selectedItems.removeAt(index);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('At least one item is required.'),
          ),
        );
      }
    });
  }
  Future<void> submitItems() async {
    if (token == null) {
      _showErrorDialog("Auth token not found. Please log in.");
      return;
    }

    bool hasInvalidQuantity = selectedItems.any((item) => (item?['quantity'] ?? 0) < 1);
    if (hasInvalidQuantity) {
      _showErrorDialog("All items must have a quantity of at least 1.");
      return;
    }

    final payload = {
      "items": selectedItems.map((item) {
        return {
          "logistic_items_id": item?['id'],
          "category_id": item?['category_id'],
          "requested_units": item?['quantity'],
        };
      }).toList(),
    };

    _sendRequest(payload);
  }


  // Send the payload to the server
  Future<void> _sendRequest(Map<String, dynamic> payload) async {
    final url = Uri.parse('http://edharti.eu-north-1.elasticbeanstalk.com/api/logistic/user-request-store');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        _showSuccessDialog("Items submitted successfully!");
      } else {
        _showErrorDialog("Failed to submit items: ${response.reasonPhrase}");
      }
    } catch (e) {
      _showErrorDialog("An error occurred: $e");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Success"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the success dialog
                Navigator.of(context).pop(); // Go back to the previous screen
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: TextField(
        controller: searchController,
        onChanged: _searchItems,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black, // Adjust text color
        ),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: 'Search',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
          ),
          fillColor: isDarkMode ? Colors.black : Colors.white, // Adjust background color
          filled: true,
        ),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDarkMode ? Colors.transparent : Colors.transparent, // Outline in dark mode
              width: 1.5,
            ),
          ),
          backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white, // Gray background for dark mode
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0, // Left and right
              vertical: 34.0,   // Top and bottom
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/confirmrequest.svg', // Replace with your SVG asset path
                  height: 170,
                  width: 170,
                ),
                const SizedBox(height: 16),
                Text(
                  'Are you sure?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black, // Dynamic text color
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure want to purchase the items?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey, // Adjusted for dark mode
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // No Button
                    SizedBox(
                      width: 120,
                      height: 35, // Set a fixed width for the "No" button
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDarkMode ? Colors.yellow : Colors.blue, // Dynamic border color
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 5), // Adjust vertical padding
                        ),
                        child: Text(
                          'No',
                          style: TextStyle(
                            color: isDarkMode ? Colors.yellow : Colors.blue, // Dynamic text color
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Yes Button
                    SizedBox(
                      width: 120,
                      height: 35, // Set a fixed width for the "Yes" button
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                          submitItems(); // Call your submit function
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? Colors.blueAccent : Colors.blue, // Dynamic background
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 5), // Adjust vertical padding
                        ),
                        child: const Text(
                          'Yes',
                          style: TextStyle(
                            color: Colors.white, // "Yes" button text stays white for contrast
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );


      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false, // Removes the back arrow
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
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
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, ${userName ?? 'Guest'}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  userEmail ?? '',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _logout(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/logout.svg',
                    height: 22,
                    width: 22,
                    color: Colors.blue,
                  ),
                  const Text(
                    'Logout',
                    style: TextStyle(fontSize: 10, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 16.0),
        child: Column(
          children: [
            _buildSearchBar(),
        Expanded(
          child: ListView.builder(
            itemCount: selectedItems.length,
            itemBuilder: (context, index) {
              final item = selectedItems[index];
              final label = item?['label'] ?? 'No Label';
              final category = item?['category_name'] ?? 'Stationery';
              final lastUpdated = item?['lastUpdated'] ?? 'No Date';

              // Manage the controller to avoid recreating it on every rebuild
              final quantityController = TextEditingController(
                text: (item?['quantity'] ?? 1).toString(),
              );

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.grey.withOpacity(0.4), // Grey border with 0.4 opacity
                    width: 1, // Border width
                  ),
                ),
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                color: isDarkMode ? Colors.black : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                  child: Row(
                    children: [
                      // Item Number in Circle
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: isDarkMode ? Colors.grey : Colors.black,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isDarkMode ? Colors.black : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Item Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              category,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Last Updated: $lastUpdated',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Quantity Input
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: TextFormField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            item?['quantity'] = int.tryParse(value) ?? 1;
                          },
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white : Colors.black, // Fix dynamic style
                          ),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.all(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Delete Icon
                      IconButton(
                        icon: SvgPicture.asset(
                          'assets/Delete.svg',
                          color: Colors.red,
                          width: 25,
                          height: 25,
                          placeholderBuilder: (context) => const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                        ),
                        onPressed: () => deleteItem(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        Container(
              width: double.infinity,
              height: 45,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF50B8E7),
                    Color(0xFF4A90E2),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton(
                onPressed: () => _showConfirmationDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
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
        else if (index == 0) {
          _navigateToDashboard(context);
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
    );
  }
}
