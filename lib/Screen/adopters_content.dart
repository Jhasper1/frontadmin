import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'adopter_details_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdoptersPage extends StatefulWidget {
  const AdoptersPage({super.key});

  @override
  State<AdoptersPage> createState() => _AdoptersPageState();
}

class _AdoptersPageState extends State<AdoptersPage> {
  bool isLoading = true;
  String searchQuery = '';
  int currentPage = 0;
  int rowsPerPage = 10;
  bool isDarkMode = false;
  List<Map<String, dynamic>> adopters = [];
  List<Map<String, dynamic>> filteredAdopters = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAdopters();
  }

  Future<void> _fetchAdopters() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.get(
      Uri.parse('http://127.0.0.1:5566/api/admin/getalladopters'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", // Use the token from the widget
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        isLoading = false;
        adopters = List<Map<String, dynamic>>.from(data['data']);
        filteredAdopters = adopters; // Initialize filtered list
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load adopters')),
      );
    }
  }

  void _filterAdopters(String query) {
    setState(() {
      searchQuery = query;
      filteredAdopters = adopters.where((adopter) {
        final adopterInfo = adopter['info'] ?? {};
        final fullName =
            '${adopterInfo['first_name'] ?? ''} ${adopterInfo['last_name'] ?? ''}'
                .toLowerCase();
        return fullName.contains(query.toLowerCase());
      }).toList();
      currentPage = 0; // Reset pagination
    });
  }

  List<Map<String, dynamic>> _getPaginatedAdopters() {
    final startIndex = currentPage * rowsPerPage;
    final endIndex = (currentPage + 1) * rowsPerPage;
    return filteredAdopters.sublist(
      startIndex,
      endIndex > filteredAdopters.length ? filteredAdopters.length : endIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, // Ensures the container spans the full width
        height: double.infinity, // Ensures the container spans the full height
        decoration: BoxDecoration(
          color: isDarkMode
              ? const Color(0xff1e1e20) // Dark mode background
              : const Color(0xfffbfbfe), // Light mode background
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by adopter name...',
                          hintStyle: TextStyle(
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[700],
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[700],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color: isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                            ),
                          ),
                          filled: true,
                          fillColor:
                              isDarkMode ? Colors.grey[800] : Colors.white,
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[700],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      searchController.clear();
                                      searchQuery = '';
                                      filteredAdopters = adopters;
                                      currentPage = 0;
                                    });
                                  },
                                )
                              : null,
                        ),
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        onChanged: _filterAdopters,
                      ),
                    ),

                    // Data Table
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Container(
                            width: constraints.maxWidth,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color:
                                  isDarkMode ? Colors.grey[900] : Colors.white,
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth,
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: DataTable(
                                    columns: const [
                                      DataColumn(
                                          label: Text('Name',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Email',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Phone',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Address',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Actions',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                    ],
                                    rows:
                                        _getPaginatedAdopters().map((adopter) {
                                      final adopterInfo = adopter['info'] ?? {};
                                      final adopterAccount =
                                          adopter['adopter'] ?? {};

                                      return DataRow(
                                        cells: [
                                          DataCell(Text(
                                            '${adopterInfo['first_name'] ?? ''} ${adopterInfo['last_name'] ?? ''}',
                                            style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          )),
                                          DataCell(Text(
                                            adopterAccount['email'] ?? 'N/A',
                                            style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          )),
                                          DataCell(Text(
                                            adopterInfo['contact_number'] ??
                                                'N/A',
                                            style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          )),
                                          DataCell(Text(
                                            adopterInfo['address'] ?? 'N/A',
                                            style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          )),
                                          DataCell(
                                            IconButton(
                                              icon: Icon(
                                                Icons.visibility,
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        AdopterDetailsPage(
                                                            adopterData:
                                                                adopter),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                    headingRowColor: MaterialStateProperty
                                        .resolveWith<Color>(
                                      (Set<MaterialState> states) => isDarkMode
                                          ? Colors.grey[800]!
                                          : Colors.grey[200]!,
                                    ),
                                    dataRowHeight: 60,
                                    headingRowHeight: 50,
                                    horizontalMargin: 20,
                                    columnSpacing: 30,
                                    showCheckboxColumn: false,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Pagination Controls
                    if (filteredAdopters.length > rowsPerPage)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            DropdownButton<int>(
                              value: rowsPerPage,
                              dropdownColor:
                                  isDarkMode ? Colors.grey[800] : Colors.white,
                              items: [5, 10, 25, 50].map((int value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text(
                                    '$value per page',
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    rowsPerPage = value;
                                    currentPage = 0;
                                  });
                                }
                              },
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${currentPage * rowsPerPage + 1}-${(currentPage + 1) * rowsPerPage > filteredAdopters.length ? filteredAdopters.length : (currentPage + 1) * rowsPerPage} of ${filteredAdopters.length}',
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: Icon(
                                Icons.chevron_left,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                              onPressed: currentPage > 0
                                  ? () {
                                      setState(() {
                                        currentPage--;
                                      });
                                    }
                                  : null,
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.chevron_right,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                              onPressed: (currentPage + 1) * rowsPerPage <
                                      filteredAdopters.length
                                  ? () {
                                      setState(() {
                                        currentPage++;
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
