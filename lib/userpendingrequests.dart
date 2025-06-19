import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'settings.dart';
import 'requesteditemslist.dart';
import 'notifications.dart';
import 'user_dashboard.dart';
import 'login.dart';

class StationeryScreen extends StatefulWidget {
  const StationeryScreen({Key? key}) : super(key: key);

  @override
  _StationeryScreenState createState() => _StationeryScreenState();
}

class _StationeryScreenState extends State<StationeryScreen> {
  String? userName;
  String? userEmail;
  bool isDarkMode = false;
  int cartCount = 45;
  int notificationCount = 10;
  bool isLoading = true; // Initially true as items are being fetched
  List<dynamic> items = [];
  List<Map<String, dynamic>> selectedItems = [];
  List<dynamic> filteredItems = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchItems();
    _loadTheme();
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

  Future<void> _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? 'Guest';
      userEmail = prefs.getString('user_email') ?? 'No Department';
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

  Future<void> _fetchItems() async {
    setState(() {
      isLoading = true;
    });

    final url = 'http://edharti.eu-north-1.elasticbeanstalk.com/api/items/details';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          items = data['data'];
          filteredItems = items;
          isLoading = false; // Data fetched successfully
        });
      } else {
        setState(() {
          isLoading = false; // Stop loading even if there's an error
        });
        if (response.statusCode == 401) {
          Fluttertoast.showToast(
            msg: 'Unauthorized request. Please log in again.',
            toastLength: Toast.LENGTH_SHORT,
          );
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false; // Stop loading on error
      });
      Fluttertoast.showToast(
        msg: 'Error fetching items: $e',
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }


  void _searchItems(String query) {
    final searchQuery = query.toLowerCase();
    setState(() {
      filteredItems = items.where((item) {
        final label = item['label'].toLowerCase();
        final category = item['category_name'].toLowerCase();
        return label.contains(searchQuery) || category.contains(searchQuery);
      }).toList();
    });
  }

  bool _isAnyItemSelected() => selectedItems.isNotEmpty;

  Future<void> refreshItems() async {
    await _fetchItems();
    Fluttertoast.showToast(
      msg: "Items refreshed successfully!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 10),
            Expanded(child: _buildItemList()),
            if (_isAnyItemSelected())
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RequestItemList(selectedItems: selectedItems),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 45),
                    backgroundColor: const Color(0xFF4A90E2),
                  ),
                  child: const Text(
                    'Requested Items List',
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

  AppBar _buildAppBar() {
    return AppBar(
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
  Widget _buildItemList() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (filteredItems.isEmpty) {
      return Center(
        child: Text(
          'No Records Found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refreshItems,
      child: ListView.builder(
        itemCount: filteredItems.length,
        itemBuilder: (context, index) {
          final item = filteredItems[index];
          int currentItemNumber = item['currentNumber'] ?? 0;

          return Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black : Colors.white, // Adjust background color
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2), // Outline color
                width: 1, // Outline width
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 9,
                  offset: Offset(2, 3),
                ),
              ],
            ),

            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['label'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          item['category_name'],
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        if (item['available_units'] == 0)
                          const Text(
                            'Out of Stock',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (item['available_units'] > 0)
                        GestureDetector(
                          onTap: item['available_units'] > 0 && currentItemNumber > 0
                              ? () {
                            setState(() {
                              item['currentNumber'] = currentItemNumber - 1;
                              if (item['currentNumber'] > 0) {
                                selectedItems = [
                                  ...selectedItems.where((i) => i['id'] != item['id']),
                                  {
                                    'id': item['id'],
                                    'label': item['label'],
                                    'category_id': item['category_id'],
                                    'quantity': item['currentNumber'] -1,
                                  },
                                ];
                              } else {
                                selectedItems.removeWhere((i) => i['id'] == item['id']);
                              }
                            });
                          }
                              : null,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Color(0xFF95D2B3),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(Icons.remove, color: Colors.white, size: 14),
                          ),
                        ),
                      if (item['available_units'] > 0)
                        SizedBox(width: 6),
                      if (item['available_units'] > 0)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 1.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFF95D2B3)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            currentItemNumber.toString(),
                            style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.black,),

                          ),
                        ),
                      if (item['available_units'] > 0)
                        SizedBox(width: 6),
                      if (item['available_units'] > 0)
                        GestureDetector(
                          onTap: item['available_units'] >= currentItemNumber
                              ? () {
                            setState(() {
                              if (item['currentNumber'] == item['available_units']) {
                                Fluttertoast.showToast(
                                  msg: "Max limit reached",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  timeInSecForIosWeb: 1,
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                  fontSize: 16.0,
                                );
                              } else {
                                item['currentNumber'] = currentItemNumber + 1;
                                selectedItems = [
                                  ...selectedItems.where((i) => i['id'] != item['id']),
                                  {
                                    'id': item['id'],
                                    'label': item['label'],
                                    'category_name': item['category_name'],
                                    'category_id': item['category_id'],
                                    'quantity': currentItemNumber + 1,
                                  },
                                ];
                              }
                            });
                          }
                              : null,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Color(0xFF95D2B3),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(Icons.add, color: Colors.white, size: 14),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
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

