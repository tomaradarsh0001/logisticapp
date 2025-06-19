import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings.dart';
import 'user_dashboard.dart';

class RequestDetailPage extends StatefulWidget {
  final dynamic requestId;
  final String label;
  final String category;
  final String totalUnit;
  final String issuedUnit;
  final String updateDate;
  final String approvalDate;
  final String status;

  const RequestDetailPage({
    Key? key,
    required this.requestId,
    required this.label,
    required this.category,
    required this.totalUnit,
    required this.issuedUnit,
    required this.updateDate,
    required this.approvalDate,
    required this.status,
  }) : super(key: key);

  @override
  _RequestDetailPageState createState() => _RequestDetailPageState();
}

class _RequestDetailPageState extends State<RequestDetailPage> {
  bool isDarkMode = false; // Variable to track the theme

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  // Load theme preference from SharedPreferences
  void _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false; // Default to false (light mode)
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        title: Text(
          'Request Details',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
      ),
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          color: isDarkMode ? Colors.black : Colors.white,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Request ID: ${widget.requestId}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              ..._buildSeparateCards(
                widget.label,
                widget.category,
                widget.totalUnit,
                widget.issuedUnit,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        selectedItemColor: isDarkMode ? Colors.blue : Colors.blueAccent,
        unselectedItemColor: isDarkMode ? Colors.white70 : Colors.grey,
        currentIndex: 0,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        iconSize: 25,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardUserScreen()),
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

  List<Widget> _buildSeparateCards(String label, String category, String totalUnit, String issuedUnit) {
    List<String> labels = label.split(', ');
    List<String> categories = category.split(', ');
    List<String> totalUnits = totalUnit.split(', ');
    List<String> issuedUnits = issuedUnit.split(', ');

    List<Widget> cards = [];

    for (int i = 0; i < labels.length; i++) {
      cards.add(userHistoryCard(
        label: labels[i],
        category: categories[i],
        totalUnit: totalUnits[i],
        issuedUnit: issuedUnits[i],
        updateDate: widget.updateDate,
        approvalDate: widget.approvalDate,
        status: widget.status,
      ));
    }

    return cards;
  }

  void _navigateToSettingsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  Widget userHistoryCard({
    required String label,
    required String category,
    required String totalUnit,
    required String issuedUnit,
    required String updateDate,
    required String approvalDate,
    required String status,
  }) {
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

    Color statusColor = (status == 'Approved')
        ? Colors.green
        : (status == 'Pending')
        ? Colors.yellow.shade700
        : Colors.red;

    IconData statusIcon = (status == 'Approved')
        ? Icons.check_box
        : (status == 'Pending')
        ? Icons.access_time_filled
        : Icons.cancel_sharp;

    return Card(
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor,
          width: 1.5,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Icon(
                  statusIcon,
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              category,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.grey[600],
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Unit: $totalUnit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  'Issued Unit: $issuedUnit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Requested Date: $formattedRequestedDate',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  ),
                ),
                Text(
                  'Approval Date: $formattedApprovalDate',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
