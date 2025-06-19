import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart'; // For parsing the date
import 'package:timeago/timeago.dart' as timeago;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'user_dashboard.dart';
import 'settings.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> userRequests = [];
  List<dynamic> filteredRequests = [];
  bool isDarkMode = false; // Variable to track the theme
  String userName = 'Guest';
  String userEmail = 'No Department';
  String? token;
  bool isLoading = true;


  @override
  void initState() {
    super.initState();
    _loadTheme();
    _loadUserData(); // Load user data from SharedPreferences
    _loadTokenAndFetchRequests(); // Load token and fetch user requests

  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUserName = prefs.getString('user_name');
    String? savedUserEmail = prefs.getString('user_email');

    setState(() {
      userName = savedUserName ?? 'Guest'; // Default to 'Guest' if null
      userEmail = savedUserEmail ?? 'No Department'; // Default if null
    });
  }

  // Load theme preference from SharedPreferences
  void _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode =
          prefs.getBool('isDarkMode') ?? false; // Default to false (light mode)
    });
  }

  Future<void> _loadTokenAndFetchRequests() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString(
        'auth_token'); // Assuming token is stored as 'auth_token'

    if (token == null) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: No token found')),
      );
      return;
    }

    fetchUserRequests();
  }

  void _navigateToSettingsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsPage()),
    );
  }

  Future<void> fetchUserRequests() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://edharti.eu-north-1.elasticbeanstalk.com/api/logistic/user-history'),
        headers: {
          'Authorization': 'Bearer $token', // Pass the token in the headers
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['user-requests'] is List) {
          setState(() {
            userRequests = data['user-requests'];
            filteredRequests = userRequests; // Initially, show all requests
            isLoading = false;
          });
        } else {
          throw Exception('Unexpected JSON structure');
        }
      } else {
        throw Exception('Failed to load user history');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  Color _getTrailingColor(String? status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTrailingIcon(String? status) {
    switch (status) {
      case 'Approved':
        return Icons.check_circle;
      case 'Rejected':
        return Icons.cancel;
      case 'Pending':
        return Icons.hourglass_empty;
      default:
        return Icons.help_outline;
    }
  }

  RichText _getStatusMessage(String? status) {
    String baseMessage;
    String lastWord;
    Color lastWordColor;

    switch (status) {
      case 'Approved':
        baseMessage = 'Your request for issuing items has been';
        lastWord = ' approved';
        lastWordColor = Colors.green;
        break;
      case 'Rejected':
        baseMessage = 'Your request for issuing items has been';
        lastWord = ' rejected';
        lastWordColor = Colors.red;
        break;
      case 'Pending':
        baseMessage = 'Your request is pending';
        lastWord = ' approval';
        lastWordColor = Colors.orange;
        break;
      default:
        baseMessage = 'Unknown';
        lastWord = ' status';
        lastWordColor = Colors.grey;
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 14,
          color: Colors.black, // Default text color
        ),
        children: [
          TextSpan(text: baseMessage),
          TextSpan(
            text: lastWord,
            style: TextStyle(color: lastWordColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  String _getTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';

    DateTime now = DateTime.now();
    DateTime dateTime;

    // Parse timestamp and handle timezone
    if (timestamp is String) {
      try {
        dateTime = DateFormat("yyyy-MM-dd HH:mm:ss").parse(timestamp, true).toLocal();
      } catch (e) {
        return 'Invalid time format';
      }
    } else if (timestamp is DateTime) {
      dateTime = timestamp.toLocal();
    } else {
      return 'Unknown time';
    }

    Duration difference = now.difference(dateTime);

    if (difference.inDays >= 1) {
      return '${difference.inDays} day${difference.inDays > 1 ? "s" : ""} ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} hour${difference.inHours > 1 ? "s" : ""} ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? "s" : ""} ago';
    } else if (difference.inSeconds >= 1) {
      return '${difference.inSeconds} second${difference.inSeconds > 1 ? "s" : ""} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors
              .black), // Change title color based on theme
        ),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        // AppBar color based on theme
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors
            .black), // Icon color based on theme
      ),
      body: AnimatedContainer(
        duration: const Duration(seconds: 0),
        // Smooth animation
        color: isDarkMode ? Colors.black : Colors.white,
        // Background color based on theme
        curve: Curves.easeInOut,
        // Smooth curve
        child: isLoading
            ? Center(
            child: CircularProgressIndicator()) // Show loading spinner while fetching data
            : RefreshIndicator(
          onRefresh: _loadTokenAndFetchRequests, // Refresh callback
          child: filteredRequests
              .where((request) =>
          request['status'] == 'Approved' || request['status'] == 'Rejected')
              .isEmpty
              ? Center(
            child: Text(
              'No notifications available.',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 16,
              ),
            ),
          )
              : ListView.builder(
            itemCount: filteredRequests
                .where((request) =>
            request['status'] == 'Approved' || request['status'] == 'Rejected')
                .length,
            itemBuilder: (context, index) {
              final filteredRequest = filteredRequests
                  .where((request) =>
              request['status'] == 'Approved' ||
                  request['status'] == 'Rejected')
                  .toList()[index];

              return Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 2.0, 20.0, 0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  // Card color based on theme
                  child: Stack(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.all(8.0),
                        leading: SvgPicture.asset(
                          filteredRequest['status'] == 'Approved'
                              ? 'assets/happy.svg'
                              : (filteredRequest['status'] == 'Rejected'
                              ? 'assets/sadd.svg'
                              : 'assets/default.svg'),
                          width: 40.0,
                          height: 40.0,
                        ),
                        title: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 45, 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  filteredRequest['status'] == 'Approved'
                                      ? 'Request Approved'
                                      : (filteredRequest['status'] == 'Rejected'
                                      ? 'Request Rejected'
                                      : 'Request Pending'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white : Colors
                                        .black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          // Padding to separate subtitle
                          child: RichText(
                            text: TextSpan(
                              text: 'Your request for issuing items has been ',
                              // Common text
                              style: TextStyle(
                                color: isDarkMode ? Colors.white70 : Colors
                                    .black54,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: filteredRequest['status'] == 'Approved'
                                      ? 'approved'
                                      : filteredRequest['status'] == 'Rejected'
                                      ? 'rejected'
                                      : 'pending', // Last word dynamically set
                                  style: TextStyle(
                                    color: filteredRequest['status'] ==
                                        'Approved'
                                        ? Colors.green
                                        : filteredRequest['status'] ==
                                        'Rejected'
                                        ? Colors.red
                                        : Colors.orange,
                                    // Color for the last word based on status
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          // Align content to the right
                          children: [
                            Text(
                              filteredRequest['issued_date'] != null &&
                                  filteredRequest['issued_date'] != ''
                                  ? _getTimeAgo(filteredRequest['issued_date'])
                                  : (filteredRequest['rejected_date'] != null &&
                                  filteredRequest['rejected_date'] != ''
                                  ? _getTimeAgo(
                                  filteredRequest['rejected_date'])
                                  : 'Unknown time'),
                              // Fallback for both null/empty dates
                              style: TextStyle(
                                color: isDarkMode ? Colors.white70 : Colors
                                    .grey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              filteredRequest['request_id'],
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.grey,
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 8.0,
                        right: 8.0,
                        child: Icon(
                          _getTrailingIcon(filteredRequest['status']),
                          color: _getTrailingColor(
                              filteredRequest['status']), // Dynamic color
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        // Bottom navigation background color
        selectedItemColor: isDarkMode ? Colors.blue : Colors.blueAccent,
        unselectedItemColor: isDarkMode ? Colors.white70 : Colors.grey,
        currentIndex: 1,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        iconSize: 25,
        onTap: (index) {
          // Navigate based on the selected tab
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const DashboardUserScreen()),
            );
          } else if (index == 2) {
            _navigateToSettingsScreen(context);
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