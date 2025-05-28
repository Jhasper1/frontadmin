import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardScreen extends StatefulWidget {
  final Widget child;

  const DashboardScreen({super.key, required this.child});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isHovered = false;
  List<dynamic> notifications = [];
  bool isLoadingNotifications = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      isLoadingNotifications = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:4000/admin/notifications'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          notifications = [
            ...data['report_notifications'] ?? [],
            ...data['shelter_notifications'] ?? [],
          ];
          isLoadingNotifications = false;
        });
      } else {
        setState(() {
          isLoadingNotifications = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingNotifications = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          // Sidebar (unchanged)
          Material(
            elevation: 2,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isHovered ? 220 : 70,
                color: Colors.white,
                child: Column(
                  children: [
                    // Logo Section
                    Container(
                      height: 80,
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.pets, color: Color(0xFF1976D2)),
                          if (_isHovered)
                            const Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Text('PetHub'),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Sidebar Menu Items
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _buildMenuItem('Dashboard', Icons.dashboard,
                              '/dashboard/content'),
                          _buildMenuItem('All Shelter Accounts',
                              Icons.home_work, '/dashboard/shelter/content'),
                          _buildMenuItem('Adopters List', Icons.people,
                              '/dashboard/adopters'),
                          _buildMenuItem('Reported Shelters', Icons.report,
                              '/dashboard/reported/shelters'),
                          _buildMenuItem('Blocked Shelters', Icons.block,
                              '/blocked/shelters'),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),

                    // Log Out Section
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout),
                          if (_isHovered)
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: GestureDetector(
                                onTap: () => context.go('/login'),
                                child: const Text('Log Out'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main Content Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
              child: Column(
                children: [
                  // Modified App Bar
                  Container(
                    margin: const EdgeInsets.only(left: 16, bottom: 16),
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title Section
                        Text(
                          _getPageTitle(context),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),

                        // Action Buttons Section
                        Row(
                          children: [
                            // Notification Dropdown in App Bar
                            PopupMenuButton<int>(
                              icon: const Icon(Icons.notifications,
                                  color: Colors.grey),
                              itemBuilder: (context) {
                                if (isLoadingNotifications) {
                                  return [
                                    const PopupMenuItem<int>(
                                      value: -1,
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                  ];
                                }

                                if (notifications.isEmpty) {
                                  return [
                                    const PopupMenuItem<int>(
                                      value: -1,
                                      child: Center(
                                        child:
                                            Text('No notifications available'),
                                      ),
                                    ),
                                  ];
                                }

                                final notificationItems = notifications
                                    .take(3)
                                    .map((notification) {
                                      if (notification
                                          .containsKey('report_id')) {
                                        // Report notification
                                        return PopupMenuItem<int>(
                                          value: notification['report_id'],
                                          child: ListTile(
                                            leading: const Icon(Icons.report,
                                                color: Colors.red),
                                            title: Text(
                                              '${notification['first_name']} ${notification['last_name']}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            subtitle: Text(
                                              'reported ${notification['shelter_name']} for ${_parseReason(notification['reason'])}.',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        );
                                      } else if (notification
                                          .containsKey('shelter_id')) {
                                        // Shelter notification
                                        return PopupMenuItem<int>(
                                          value: notification['shelter_id'],
                                          child: ListTile(
                                            leading: const Icon(Icons.home_work,
                                                color: Colors.blue),
                                            title: Text(
                                              notification['shelter_name'],
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            subtitle: Text(
                                              'Pending approval. Email: ${notification['email']}',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        );
                                      }
                                      return null;
                                    })
                                    .whereType<PopupMenuItem<int>>()
                                    .toList();

                                notificationItems.add(
                                  const PopupMenuItem<int>(
                                    enabled: false,
                                    child: Divider(),
                                  ),
                                );
                                notificationItems.add(
                                  PopupMenuItem<int>(
                                    value: -2,
                                    child: Center(
                                      child: Text(
                                        'View All Notifications',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                );

                                return notificationItems;
                              },
                              onSelected: (value) {
                                context.go('/dashboard/notification');
                              },
                            ),
                            const SizedBox(width: 10),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(2.0),
                                child: CircleAvatar(
                                    radius: 16,
                                    backgroundImage:
                                        AssetImage('assets/images/dog.png')),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Content Area
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        color: Colors.grey[100],
                        child: widget.child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon, String route) {
    final currentRoute =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();
    final isActive = currentRoute == route;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go(route),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFE3F2FD) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isActive
                ? Border.all(color: const Color(0xFF1976D2).withOpacity(0.3))
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Row(
            mainAxisAlignment:
                _isHovered ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: isActive ? const Color(0xFF1976D2) : Colors.grey[600]),
              if (_isHovered)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    title,
                    style: TextStyle(
                      color:
                          isActive ? const Color(0xFF1976D2) : Colors.black87,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPageTitle(BuildContext context) {
    final currentRoute =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();
    switch (currentRoute) {
      case '/dashboard/content':
        return 'Dashboard';
      case '/dashboard/shelter/content':
        return 'All Shelter Accounts';
      case '/dashboard/adopters':
        return 'Adopters List';
      case '/dashboard/reported/shelters':
        return 'Reported Shelters';
      case '/blocked/shelters':
        return 'Blocked Shelters';
      case '/dashboard/notification':
        return 'Notifications';
      default:
        return 'Dashboard';
    }
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Report #${notification['report_id']}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Reason', notification['reason']),
                _buildDetailRow('Description', notification['description']),
                _buildDetailRow('Adopter',
                    '${notification['first_name']} ${notification['last_name']}'),
                _buildDetailRow('Shelter', notification['shelter_name']),
                _buildDetailRow('Reported At', notification['created_at']),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _parseReason(String reason) {
    try {
      // Decode the JSON string and remove special characters
      final parsed = json.decode(reason) as String;
      return parsed.replaceAll(RegExp(r'[{}"]'), '').trim();
    } catch (e) {
      // If parsing fails, return the raw reason without special characters
      return reason.replaceAll(RegExp(r'[{}"]'), '').trim();
    }
  }
}
