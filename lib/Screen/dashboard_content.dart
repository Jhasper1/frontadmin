import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Import the custom container

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  int shelterCount = 0;
  int adopterCount = 0;
  int petCount = 0;
  int adoptedPetCount = 0;
  int approvedShelters = 0;
  int pendingShelters = 0;
  bool isLoading = true;
  String errorMessage = '';
  int touchedIndex = -1;

  bool isDarkMode = false; // Theme toggle state

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    const baseUrl = 'http://127.0.0.1:5566';

    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/admin/shelters/count')),
        http.get(Uri.parse('$baseUrl/admin/adopters/count')),
        http.get(Uri.parse('$baseUrl/admin/pets/count')),
        http.get(Uri.parse('$baseUrl/admin/adoptedpets/count')),
        http.get(Uri.parse('$baseUrl/admin/pendingshelters/count')),
        http.get(Uri.parse('$baseUrl/admin/approvedshelters/count')),
      ]);

      setState(() {
        if (responses[0].statusCode == 200) {
          shelterCount = json.decode(responses[0].body)['count'] ?? 0;
        }
        if (responses[1].statusCode == 200) {
          adopterCount = json.decode(responses[1].body)['count'] ?? 0;
        }
        if (responses[2].statusCode == 200) {
          petCount = json.decode(responses[2].body)['count'] ?? 0;
        }
        if (responses[3].statusCode == 200) {
          adoptedPetCount = json.decode(responses[3].body)['count'] ?? 0;
        }
        if (responses[4].statusCode == 200) {
          pendingShelters = json.decode(responses[4].body)['count'] ?? 0;
        }
        if (responses[5].statusCode == 200) {
          approvedShelters = json.decode(responses[5].body)['count'] ?? 0;
        }

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load data: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, // Ensures the container spans the full width
        height: double.infinity, // Ensures the container spans the full height
        decoration: BoxDecoration(
          color: isDarkMode
              ? const Color(0xff010104) // Dark mode background
              : const Color(0xfffbfbfe), // Light mode background
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
                ? Center(child: Text(errorMessage))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                  'Shelters', shelterCount, Icons.home_rounded),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                  'Adopters', adopterCount, Icons.people),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                                child: _buildStatCard(
                                    'Pets', petCount, Icons.pets)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard('Adopted Pets',
                                  adoptedPetCount, Icons.favorite),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        if (shelterCount > 0)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Color.fromARGB(
                                      235, 34, 34, 34) // Dark mode background
                                  : Colors.grey[
                                      200], // Light gray background for light mode
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                if (!isDarkMode)
                                  BoxShadow(
                                    color:
                                        const Color.fromARGB(187, 158, 158, 158)
                                            .withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Shelter Status',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 300,
                                  child: PieChart(
                                    PieChartData(
                                      sections: _buildPieSections(),
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 60,
                                      pieTouchData: PieTouchData(
                                        touchCallback: (FlTouchEvent event,
                                            pieTouchResponse) {
                                          setState(() {
                                            if (!event
                                                    .isInterestedForInteractions ||
                                                pieTouchResponse == null ||
                                                pieTouchResponse
                                                        .touchedSection ==
                                                    null) {
                                              touchedIndex = -1;
                                            } else {
                                              touchedIndex = pieTouchResponse
                                                  .touchedSection!
                                                  .touchedSectionIndex;
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildLegendItem(
                                        'Approved', Color(0xff908cde)),
                                    const SizedBox(width: 20),
                                    _buildLegendItem(
                                        'Pending', Color(0xFF544fbf)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    return List.generate(2, (index) {
      final isTouched = index == touchedIndex;
      final radius = isTouched ? 70.0 : 60.0;

      if (index == 0) {
        return PieChartSectionData(
          value: approvedShelters.toDouble(),
          color: Color(0xFF544fbf),
          title: isTouched
              ? '$approvedShelters shelters'
              : '${((approvedShelters / shelterCount) * 100).toStringAsFixed(1)}%',
          radius: radius,
          titleStyle:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        );
      } else {
        return PieChartSectionData(
          value: pendingShelters.toDouble(),
          color: Color(0xff908cde),
          title: isTouched
              ? '$pendingShelters shelters'
              : '${((pendingShelters / shelterCount) * 100).toStringAsFixed(1)}%',
          radius: radius,
          titleStyle:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        );
      }
    });
  }

  Widget _buildStatCard(String title, int count, IconData icon) {
    return Card(
      elevation: 0,
      color: isDarkMode
          ? const Color.fromARGB(165, 37, 33, 115) // Dark mode card background
          : const Color(0x6B908CDE), // Light mode card background
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isDarkMode
                    ? Colors.white // White text for dark mode
                    : Colors.black, // Black text for light mode
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isDarkMode
                      ? Colors.white // White icon for dark mode
                      : Colors.black, // Black icon for light mode
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode
                        ? Colors.white // White text for dark mode
                        : Colors.black, // Black text for light mode
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }
}
