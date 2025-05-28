import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class ShelterPetCount {
  final int shelterId;
  final String shelterName;
  final int totalPets;
  final int cats;
  final int dogs;
  final int vaccinated;

  ShelterPetCount({
    required this.shelterId,
    required this.shelterName,
    required this.totalPets,
    required this.cats,
    required this.dogs,
    required this.vaccinated,
  });

  factory ShelterPetCount.fromJson(Map<String, dynamic> json) {
    return ShelterPetCount(
      shelterId: json['shelter_id'] as int? ?? 0,
      shelterName: json['shelter_name'] as String? ?? 'Unknown Shelter',
      totalPets: json['total_pets'] as int? ?? 0,
      cats: json['cats'] as int? ?? 0,
      dogs: json['dogs'] as int? ?? 0,
      vaccinated: json['vaccinated'] as int? ?? 0,
    );
  }
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
  bool isDarkMode = false;
  List<ShelterPetCount> shelterPetCounts = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    const baseUrl = 'http://127.0.0.1:4000';

    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/admin/shelters/count')),
        http.get(Uri.parse('$baseUrl/admin/adopters/count')),
        http.get(Uri.parse('$baseUrl/admin/pets/count')),
        http.get(Uri.parse('$baseUrl/admin/adoptedpets/count')),
        http.get(Uri.parse('$baseUrl/admin/pendingshelters/count')),
        http.get(Uri.parse('$baseUrl/admin/approvedshelters/count')),
        http.get(Uri.parse('$baseUrl/admin/shelterpetcounts')),
      ]);

      setState(() {
        if (responses[0].statusCode == 200) {
          shelterCount = json.decode(responses[0].body)['count'] as int? ?? 0;
        }
        if (responses[1].statusCode == 200) {
          adopterCount = json.decode(responses[1].body)['count'] as int? ?? 0;
        }
        if (responses[2].statusCode == 200) {
          petCount = json.decode(responses[2].body)['count'] as int? ?? 0;
        }
        if (responses[3].statusCode == 200) {
          adoptedPetCount =
              json.decode(responses[3].body)['count'] as int? ?? 0;
        }
        if (responses[4].statusCode == 200) {
          pendingShelters =
              json.decode(responses[4].body)['count'] as int? ?? 0;
        }
        if (responses[5].statusCode == 200) {
          approvedShelters =
              json.decode(responses[5].body)['count'] as int? ?? 0;
        }
        if (responses[6].statusCode == 200) {
          final responseBody = json.decode(responses[6].body);
          if (responseBody is Map<String, dynamic>) {
            final data = responseBody['data'] as List<dynamic>?;
            if (data != null) {
              shelterPetCounts = data
                  .map((item) =>
                      ShelterPetCount.fromJson(item as Map<String, dynamic>))
                  .toList();
            }
          }
        }

        // Filter only active shelters
        shelterCount = approvedShelters + pendingShelters;

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
      backgroundColor: Colors.grey[100],
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 7,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? const Color.fromARGB(235, 34, 34, 34)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      if (!isDarkMode)
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.2),
                                          spreadRadius: 2,
                                          blurRadius: 5,
                                          offset: const Offset(0, 3),
                                        ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                              touchCallback:
                                                  (FlTouchEvent event,
                                                      pieTouchResponse) {
                                                setState(() {
                                                  if (!event
                                                          .isInterestedForInteractions ||
                                                      pieTouchResponse ==
                                                          null ||
                                                      pieTouchResponse
                                                              .touchedSection ==
                                                          null) {
                                                    touchedIndex = -1;
                                                  } else {
                                                    touchedIndex =
                                                        pieTouchResponse
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          _buildLegendItem(
                                              'Approved',
                                              const Color.fromARGB(
                                                  255, 79, 96, 191)),
                                          const SizedBox(width: 20),
                                          _buildLegendItem(
                                            'Pending',
                                            const Color.fromARGB(
                                                255, 140, 152, 222),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 3,
                                child: _buildHorizontalBarChart(),
                              ),
                            ],
                          ),
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
        // Approved shelters
        return PieChartSectionData(
          value: approvedShelters.toDouble(),
          color: const Color.fromARGB(255, 79, 98, 191),
          title: isTouched
              ? '$approvedShelters shelters'
              : '${((approvedShelters / shelterCount) * 100).toStringAsFixed(1)}%',
          radius: radius,
          titleStyle:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        );
      } else {
        // Pending shelters
        return PieChartSectionData(
          value: pendingShelters.toDouble(),
          color: const Color.fromARGB(255, 140, 159, 222),
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
    return Container(
      decoration: BoxDecoration(
        color:
            isDarkMode ? const Color.fromARGB(165, 37, 33, 115) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon,
                size: 32, color: isDarkMode ? Colors.white : Colors.blueAccent),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildHorizontalBarChart() {
    const containerHeight = 410.0;

    return Container(
      height: containerHeight,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            isDarkMode ? const Color.fromARGB(235, 34, 34, 34) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: shelterPetCounts.isEmpty
          ? Center(
              child: Text(
                'No shelter data available',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Static header
                const Text(
                  'Shelter Pet Distribution',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ...shelterPetCounts.asMap().entries.map((entry) {
                          final index = entry.key;
                          final shelter = entry.value;
                          final totalPets = shelter.totalPets;
                          final dogPercentage =
                              totalPets > 0 ? (shelter.dogs / totalPets) : 0.0;
                          final catPercentage =
                              totalPets > 0 ? (shelter.cats / totalPets) : 0.0;
                          final vaccinated = shelter.vaccinated;

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (index > 0)
                                Divider(
                                  height: 20,
                                  thickness: 1,
                                  color: isDarkMode
                                      ? Colors.grey[700]
                                      : Colors.grey[300],
                                ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shelter.shelterName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      height: 24,
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          return Stack(
                                            children: [
                                              // Background
                                              Container(
                                                width: constraints.maxWidth,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: isDarkMode
                                                      ? Colors.grey[800]
                                                      : Colors.grey[200],
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              // Combined bar
                                              Row(
                                                children: [
                                                  // Dogs portion
                                                  Flexible(
                                                    flex: (dogPercentage * 100)
                                                        .round(),
                                                    child: MouseRegion(
                                                      cursor: SystemMouseCursors
                                                          .click,
                                                      child: Tooltip(
                                                        message:
                                                            'Dogs: ${shelter.dogs}',
                                                        child: Container(
                                                          height: 24,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .blue[400],
                                                            borderRadius:
                                                                BorderRadius
                                                                    .only(
                                                              topLeft: Radius
                                                                  .circular(12),
                                                              bottomLeft: Radius
                                                                  .circular(12),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  // Cats portion
                                                  Flexible(
                                                    flex: (catPercentage * 100)
                                                        .round(),
                                                    child: MouseRegion(
                                                      cursor: SystemMouseCursors
                                                          .click,
                                                      child: Tooltip(
                                                        message:
                                                            'Cats: ${shelter.cats}',
                                                        child: Container(
                                                          height: 24,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .orange[400],
                                                            borderRadius:
                                                                BorderRadius
                                                                    .only(
                                                              topRight: Radius
                                                                  .circular(12),
                                                              bottomRight:
                                                                  Radius
                                                                      .circular(
                                                                          12),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    if (totalPets > 0) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Total Pets: $totalPets',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black87,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Vaccinated: $vaccinated',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black87,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
