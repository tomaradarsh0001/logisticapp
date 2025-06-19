import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'settings.dart';
import 'requestdetailpage.dart';
import 'notifications.dart';
import 'user_dashboard.dart';

class UserHistory extends StatefulWidget {
  @override
  _UserHistoryState createState() => _UserHistoryState();
}

class _UserHistoryState extends State<UserHistory> {
  List<dynamic> userRequests = [];
  List<dynamic> filteredRequests = []; // Store filtered results
  bool isLoading = true;
  String? token;
  String userName = 'Guest';
  String userEmail = 'No Department';
  TextEditingController searchController = TextEditingController(); // Controller for search input
  bool isCardOpened = false; // To track whether a card is opened or not
  int? openedRequestId; // To track the ID of the opened request
  bool isDarkMode = false;


  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load user data from SharedPreferences
    _loadTokenAndFetchRequests(); // Load token and fetch user requests
    _loadTheme();
  }
  void _navigateToNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NotificationsPage()),
    );
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
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.yellow.shade700;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  // Function to load user data from SharedPreferences
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUserName = prefs.getString('user_name');
    String? savedUserEmail = prefs.getString('user_email');

    setState(() {
      userName = savedUserName ?? 'Guest'; // Default to 'Guest' if null
      userEmail = savedUserEmail ?? 'No Department'; // Default if null
    });
  }
  void _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false; // Default to false (light mode)
    });
  }

  // Function to load token and fetch user history
  Future<void> _loadTokenAndFetchRequests() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('auth_token'); // Assuming token is stored as 'auth_token'

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

  // Function to fetch user requests from API
  Future<void> fetchUserRequests() async {
    try {
      final response = await http.get(
        Uri.parse('http://edharti.eu-north-1.elasticbeanstalk.com/api/logistic/user-history'),
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

  // Function to filter the list based on the search query
  void _searchItems(String query) {
    setState(() {
      filteredRequests = userRequests.where((request) {
        String label = request['request_id'].toString().toLowerCase();
        return label.contains(query.toLowerCase()); // Filter by matching query
      }).toList();
    });
  }

  // Function to open a specific request card by tapping on a request ID
  void _openRequestCard(int requestId) {
    setState(() {
      if (openedRequestId == requestId) {
        isCardOpened = !isCardOpened; // Toggle the card visibility
      } else {
        openedRequestId = requestId;
        isCardOpened = true; // Open the card for the selected request
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70), // Adjust the height as needed
        child: Padding(
          padding: const EdgeInsets.only(top: 48.0, left: 28.0, right: 28.0, bottom: 0), // Top 48, rest 16
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.blueGrey : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6), // Rounded corners
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0), // Inner padding
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_sharp, color: isDarkMode ? Colors.white70 : Colors.black,),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.history, color: Colors.blue), // Icon inside the avatar
                ),
                SizedBox(width: 8), // Spacing between avatar and text
                Text(
                  'History',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildSearchBar(),
            SizedBox(height: 8),
            isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredRequests.isEmpty
                ? Center(child: Text('No Records found.'))
                : Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await fetchUserRequests(); // Fetch user data when pulled to refresh
                },
                child: ListView.builder(
                  itemCount: filteredRequests.length,
                  itemBuilder: (context, index) {
                    final request = filteredRequests[index];
                    return userHistoryCard(
                      requestId: request['request_id'],
                      initials: request['request_id']?.substring(0, 2) ?? 'NA',
                      label: (request['items'] as List)
                          .map((item) => item['logistic_item_name'] ?? 'Unknown Category')
                          .join(', ') ?? 'Unknown label',
                      category: (request['items'] as List)
                          .map((item) => item['category_name'] ?? 'Unknown Category')
                          .join(', ') ?? 'Unknown Category',
                      totalUnit: (request['items'] as List)
                          .map((item) => item['requested_units'].toString() ?? 'Unknown')
                          .join(', ') ?? 'Unknown Units',
                      issuedUnit: (request['items'] as List)
                          .map((item) => item['issued_units'].toString() ?? 'Unknown')
                          .join(', ') ?? 'Unknown Units',
                      updateDate: request['requested_date'] ?? 'N/A',
                      approvalDate: request['issued_date'] ?? 'N/A',
                      status: request['status'] ?? 'Unknown',
                      isOpened: openedRequestId == request['request_id'] && isCardOpened,
                    );
                  },
                ),
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
          else if (index == 0) {
            _navigateToDashboard(context);
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
      ),    );
  }

  // Search Bar widget
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: searchController,
        onChanged: _searchItems,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black, // Adjust text color
        ),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: 'Search Request ID',
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

  // History Card widget
  Widget userHistoryCard({
    required dynamic requestId,  // Can be dynamic type
    required String initials,
    required String label,
    required String category,
    required String totalUnit,
    required String issuedUnit,
    required String updateDate,
    required String approvalDate,
    required String status,
    required bool isOpened,
  }) {
    // Convert requestId to integer if it's a string
    int requestIdInt = (requestId is String) ? int.tryParse(requestId) ?? 0 : requestId;

    // Now you can use requestIdInt as an integer in your logic

    String formattedRequestedDate = 'N/A';
    if (updateDate != 'N/A') {
      try {
        DateTime parsedDate = DateTime.parse(updateDate);
        formattedRequestedDate = DateFormat('yyyy-MM-dd').format(parsedDate);
      } catch (e) {
        formattedRequestedDate = 'N/A';
      }
    }

    String formattedApprovalDate = 'N/A';
    if (approvalDate != 'N/A') {
      try {
        DateTime parsedDate = DateTime.parse(approvalDate);
        formattedApprovalDate = DateFormat('yyyy-MM-dd').format(parsedDate);
      } catch (e) {
        formattedApprovalDate = 'N/A';
      }
    }

    return GestureDetector(
      onTap: () {
        _openRequestCard(requestIdInt);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RequestDetailPage(
              requestId: requestId.toString(),  // Ensure it's passed as string
              label: label,
              category: category,
              totalUnit: totalUnit,
              issuedUnit: issuedUnit,
              updateDate: updateDate,
              approvalDate: approvalDate,
              status: status,
            ),
          ),
        );
      },
      child: Card(
        elevation: 4,
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(initials),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: isDarkMode ? Colors.white : Colors.black,
                        )),
                        SizedBox(height: 4),
                        Text(requestId, style: TextStyle(fontSize: 14, color: Colors.grey)),
                        SizedBox(height: 4),
                        Text('Requested Date: $formattedRequestedDate', style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white70 : Colors.black,)),
                        SizedBox(height: 4),
                        Text(
                          'Status: $status',
                          style: TextStyle(
                            fontSize: 14,
                            color: _getStatusColor(status), // Use a method to get the color
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
              if (isOpened)
                Column(
                  children: [
                    Text('Additional Details Here...'),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
