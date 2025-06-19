import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RequestHistory extends StatefulWidget {
  @override
  _RequestHistoryState createState() => _RequestHistoryState();
}

class _RequestHistoryState extends State<RequestHistory> {
  bool _isLoading = false;
  List<dynamic> _userRequests = [];

  // Method to fetch the user history
  Future<void> _fetchUserHistory() async {
    setState(() {
      _isLoading = true;
    });

    // Retrieve the token from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      _showDialog('Token Error', 'No token found. Please login again.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Make the GET request with the token
    final response = await http.get(
      Uri.parse('http://edharti.eu-north-1.elasticbeanstalk.com/api/logistic/user-history'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      // Parse the response and update state
      final data = json.decode(response.body);
      setState(() {
        _userRequests = data['user-requests']; // Accessing the 'user-requests' array
        _isLoading = false;
      });
    } else {
      _showDialog('Error', 'Failed to load data. Status: ${response.statusCode}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to show dialog
  Future<void> _showDialog(String title, String content) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(content),
          ),
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

  @override
  void initState() {
    super.initState();
    _fetchUserHistory(); // Fetch data when the screen loads
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Icon(Icons.history, color: Colors.blue),
            SizedBox(width: 8),
            Text('History', style: TextStyle(color: Colors.black)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Display spinner while loading
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : Expanded(
              child: ListView.builder(
                itemCount: _userRequests.length,
                itemBuilder: (context, index) {
                  var request = _userRequests[index];
                  return HistoryCard(
                    requestId: request['request_id'] ?? '',
                    requestedDate: request['requested_date'] ?? '',
                    status: request['status'] ?? 'Unknown',
                    totalRequestedUnits: request['total_requested_units'] ?? 0,
                    totalIssuedUnits: request['total_issued_units'] ?? 0,
                    items: request['items'] ?? [],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.face), label: ''),
        ],
      ),
    );
  }
}

class HistoryCard extends StatelessWidget {
  final String requestId;
  final String requestedDate;
  final String status;
  final int totalRequestedUnits;
  final int totalIssuedUnits;
  final List<dynamic> items;

  HistoryCard({
    required this.requestId,
    required this.requestedDate,
    required this.status,
    required this.totalRequestedUnits,
    required this.totalIssuedUnits,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          // Set color based on the status
          color: _getStatusColor(status),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request ID: $requestId',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text('Requested Date: $requestedDate'),
          // Show status with the appropriate color
          Text(
            'Status: $status',
            style: TextStyle(color: _getStatusColor(status)),
          ),
          SizedBox(height: 8),
          Text('Total Requested Units: $totalRequestedUnits'),
          Text('Total Issued Units: $totalIssuedUnits'),
          SizedBox(height: 12),
          Text(
            'Items:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Column(
            children: items.map((item) {
              return ListTile(
                title: Text(item['logistic_item_name'] ?? 'No Name'),
                subtitle: Text('Category: ${item['category_name'] ?? 'No Category'}'),
                trailing: Text('Requested: ${item['requested_units']} / Issued: ${item['issued_units'] ?? 0}'),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Helper method to determine the color based on status
  Color _getStatusColor(String status) {
    if (status == 'Approved') {
      return Colors.green; // Approved -> Green
    } else if (status == 'Rejected') {
      return Colors.red; // Rejected -> Red
    } else if (status == 'Pending') {
      return Colors.blue; // Pending -> Yellow
    } else {
      return Colors.grey; // Default color if status is unknown
    }
  }
}
