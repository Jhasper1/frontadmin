import 'package:flutter/material.dart';
import 'dashboard_content.dart';
import 'shelters_content.dart';
import 'adopters_content.dart';
import 'blocked_shelters.dart';
import 'reported_shelters_content.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedItem = 'Dashboard';
  final String adminName = 'Admin User';
  bool _isHovered = false;

  Widget _getSelectedContent() {
    switch (_selectedItem) {
      case 'All Shelter Accounts':
        return const SheltersContent();
      case 'Adopters List':
        return const AdoptersPage();
      case 'Reported Shelters':
        return ReportedSheltersScreen();
      case 'Blocked Shelters':
        return BlockedSheltersScreen();
      default:
        return const DashboardContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Row(
        children: [
          // Sidebar - Smooth Animation
          Material(
            elevation: 4,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: AnimatedContainer(
                duration: const Duration(
                    milliseconds: 300), // Smooth animation duration
                curve: Curves.easeInOut, // Smooth easing curve
                width: _isHovered ? 220 : 60, // Animate width on hover
                color: const Color.fromARGB(
                    255, 7, 7, 41), // Uniform sidebar color
                child: Column(
                  children: [
                    // Logo Section
                    Container(
                      height: 80,
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          const Icon(Icons.pets, color: Colors.white, size: 30),
                          if (_isHovered)
                            const Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Text(
                                'PetHub',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(
                        color: Color.fromARGB(112, 255, 255, 255), height: 1),

                    // Menu Items with vertical scroll
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _buildMenuItem('Dashboard', Icons.dashboard),
                          _buildMenuItem(
                              'All Shelter Accounts', Icons.home_work),
                          _buildMenuItem('Adopters List', Icons.people),
                          _buildMenuItem('Reported Shelters', Icons.report),
                          _buildMenuItem('Blocked Shelters', Icons.block),
                        ],
                      ),
                    ),

                    // Admin Info
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 10),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.white54)),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 15,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person,
                                size: 18, color: Colors.blue),
                          ),
                          if (_isHovered)
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Text(
                                adminName,
                                style: const TextStyle(color: Colors.white),
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

          // Main content area with app bar
          Expanded(
            child: Column(
              children: [
                // Static AppBar
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title of the current page
                      Text(
                        _selectedItem,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      // Icons on the right side
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.dark_mode,
                                color: Colors.black),
                            onPressed: () {
                              // Handle dark mode toggle
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.notifications,
                                color: Colors.black),
                            onPressed: () {
                              // Handle notifications
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.admin_panel_settings,
                                color: Colors.black),
                            onPressed: () {
                              // Handle admin settings
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main Content Area
                Expanded(
                  child: Container(
                    color: Colors.grey[100],
                    child: _getSelectedContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon) {
    bool isSelected = _selectedItem == title;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedItem = title;
          });
        },
        child: Container(
          color: isSelected
              ? Colors.white
                  .withOpacity(0.3) // Highlight color: white with low opacity
              : Colors.transparent, // Default background color
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? const Color.fromARGB(
                        255, 255, 255, 255) // Icon color for selected item
                    : const Color.fromARGB(
                        255, 255, 255, 255), // Icon color for unselected items
              ),
              if (_isHovered)
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? const Color.fromARGB(255, 255, 255,
                              255) // Text color for selected item
                          : const Color.fromARGB(255, 255, 255,
                              255), // Text color for unselected items
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
