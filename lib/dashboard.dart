import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'items.dart';
import 'settings.dart';
import 'requesthistory.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? userName;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load user data when the screen initializes
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? 'User';
      userEmail = prefs.getString('user_email') ?? 'user@example.com';
    });
  }

  void _navigateToItemsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ItemsPage()),
    );
  }
  void _navigateToRequestList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RequestHistory()),
    );
  }

  void _navigateToSettingsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 60,
        title: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[200],
              child: ClipOval(
                child: Image.asset(
                  'assets/profile.png',
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
                  'Hi, $userName', // Display user name from SharedPreferences
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  userEmail ?? 'Superuser', // Display user email
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: Stack(
                children: [
                  SvgPicture.asset(
                    'assets/bell.svg',
                    width: 25,
                    height: 25,
                    color: Colors.black,
                  ),
                  Positioned(
                    right: -1,
                    top: -1,
                    child: const SmallBadgeCount(count: 45),
                  ),
                ],
              ),
              onPressed: () {},
            ),
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
                    svgPath: 'assets/administrative-approval.svg',
                    label: 'Pending Request',
                    badgeCount: 49,
                    onTap: () => _navigateToItemsScreen(context),
                  ),
                  DashboardCard(
                    svgPath: 'assets/purchase-mobile-sales_svgrepo.com.svg',
                    label: 'Purchase Items',
                    badgeCount: 159,
                    onTap: () => _navigateToItemsScreen(context),
                  ),
                  DashboardCard(
                    svgPath: 'assets/add-to-cart_svgrepo.com.svg',
                    label: 'Items',
                    badgeCount: 254,
                    onTap: () => _navigateToItemsScreen(context),
                  ),
                  DashboardCard(
                    svgPath: 'assets/category_svgrepo.com.svg',
                    label: 'Category',
                    badgeCount: 8,
                    onTap: () => _navigateToItemsScreen(context),
                  ),
                  DashboardCard(
                    svgPath: 'assets/history_svgrepo.com.svg',
                    label: 'History',
                    onTap: () => _navigateToRequestList(context),
                  ),
                  DashboardCard(
                    svgPath: 'assets/hot-dog-stand_svgrepo.com.svg',
                    label: 'Vendors',
                    onTap: () => _navigateToItemsScreen(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        iconSize: 30,
        onTap: (index) {
          if (index == 3) {
            _navigateToSettingsScreen(context);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
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

class DashboardCard extends StatelessWidget {
  final IconData? icon;
  final String? svgPath;
  final String label;
  final int? badgeCount;
  final VoidCallback onTap;

  const DashboardCard({
    Key? key,
    this.icon,
    this.svgPath,
    required this.label,
    this.badgeCount,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null)
                    Icon(icon, size: 40, color: Colors.blue)
                  else if (svgPath != null)
                    SvgPicture.asset(svgPath!, height: 60),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (badgeCount != null && badgeCount! > 0)
            Positioned(
              right: -10,
              top: -10,
              child: BadgeCount(count: badgeCount!),
            ),
        ],
      ),
    );
  }
}
