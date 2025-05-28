import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'adopter_details_page.dart';

class AdoptersPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const AdoptersPage({Key? key, this.arguments}) : super(key: key);

  @override
  State<AdoptersPage> createState() => _AdoptersPageState();
}

class _AdoptersPageState extends State<AdoptersPage> {
  List<Map<String, dynamic>> adopters = [];
  bool isLoading = true;
  String errorMessage = '';
  int _rowsPerPage = 10;
  int _currentPage = 0;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, dynamic>? selectedAdopter;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _currentPage = 0;
      });
    });

    // Check if arguments are passed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.arguments != null &&
          widget.arguments!.containsKey('adopter_id')) {
        _showAdopterDetails(widget.arguments!);
      } else {
        _fetchAdopters();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAdopters() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:4000/admin/getalladopterstry'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint("API Response: $responseData");

        if (responseData['retCode'] == '200') {
          setState(() {
            adopters =
                List<Map<String, dynamic>>.from(responseData['data'] ?? []);
            isLoading = false;
          });
        } else if (responseData['retCode'] == '401') {
          _handleUnauthorized();
        } else {
          throw Exception(
              'Failed to load adopters. Message: ${responseData['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching adopters: $e');
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  void _handleUnauthorized() {
    setState(() {
      errorMessage = 'Session expired. Please log in again.';
    });
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  int? _extractAdopterId(dynamic adopterData) {
    if (adopterData['adopter_id'] is int) return adopterData['adopter_id'];
    if (adopterData['adopter'] is Map &&
        adopterData['adopter']['adopter_id'] is int) {
      return adopterData['adopter']['adopter_id'];
    }
    if (adopterData['id'] is int) return adopterData['id'];
    return null;
  }

  Map<String, dynamic> _normalizeAdopterData(Map<String, dynamic> adopter) {
    final normalized = Map<String, dynamic>.from(adopter);
    final adopterId = _extractAdopterId(adopter);

    if (adopterId != null) {
      normalized['adopter_id'] =
          adopterId; // Ensure adopter_id is at the top level
    }

    // Ensure info and adopter fields are at the top level
    if (adopter['adopter'] is Map) {
      normalized['info'] = adopter['info'] ?? adopter['adopter']['info'] ?? {};
      normalized['adopter'] = adopter['adopter'] ?? {};
    }

    debugPrint('Normalized adopter data: $normalized');
    return normalized;
  }

  void _showAdopterDetails(Map<String, dynamic> adopter) {
    final normalizedAdopter = _normalizeAdopterData(adopter);
    setState(() {
      selectedAdopter = normalizedAdopter;
    });
  }

  void _goBackToList() {
    setState(() {
      selectedAdopter = null;
    });
  }

  List<Map<String, dynamic>> _filterAdopters() {
    if (_searchQuery.isEmpty) return adopters;

    return adopters.where((adopter) {
      final info = adopter['info'] ?? {};
      final fullName = '${info['first_name'] ?? ''} ${info['last_name'] ?? ''}'
          .toLowerCase();
      return fullName.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<Map<String, dynamic>> _getPaginatedAdopters() {
    final filtered = _filterAdopters();
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;
    return filtered.sublist(
        startIndex, endIndex > filtered.length ? filtered.length : endIndex);
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchAdopters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredAdopters = _filterAdopters();
    final paginatedAdopters = _getPaginatedAdopters();

    return Container(
      margin: const EdgeInsets.only(left: 16),
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xfffbfbfe),
        borderRadius: BorderRadius.circular(12),
      ),
      child: selectedAdopter == null
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Adopters (${filteredAdopters.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff1e1e20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 400,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by adopter name...',
                              hintStyle: const TextStyle(
                                color: Colors.grey,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.grey,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _searchQuery = '';
                                          _currentPage = 0;
                                        });
                                      },
                                    )
                                  : null,
                            ),
                            style: const TextStyle(
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey[300]!,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
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
                                                fontWeight: FontWeight.bold))),
                                    DataColumn(
                                        label: Text('Email',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    DataColumn(
                                        label: Text('Phone',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    DataColumn(
                                        label: Text('Address',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    DataColumn(
                                        label: Text('Actions',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                  ],
                                  rows: paginatedAdopters.map((adopter) {
                                    final info = adopter['info'] ?? {};
                                    final account = adopter['adopter'] ?? {};

                                    return DataRow(
                                      onSelectChanged: (_) =>
                                          _showAdopterDetails(adopter),
                                      cells: [
                                        DataCell(
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                                maxWidth: 200),
                                            child: Text(
                                              '${info['first_name'] ?? ''} ${info['last_name'] ?? ''}',
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(Text(
                                          info['email'] ?? 'Not provided',
                                          style: const TextStyle(
                                            color: Colors.black,
                                          ),
                                        )),
                                        DataCell(Text(
                                          info['contact_number'] ??
                                              'Not provided',
                                          style: const TextStyle(
                                            color: Colors.black,
                                          ),
                                        )),
                                        DataCell(Text(
                                          info['address'] ?? 'Not provided',
                                          style: const TextStyle(
                                            color: Colors.black,
                                          ),
                                        )),
                                        DataCell(
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.visibility,
                                                  size: 20,
                                                  color: Colors.black,
                                                ),
                                                onPressed: () =>
                                                    _showAdopterDetails(
                                                        adopter),
                                                tooltip: 'View Details',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                  headingRowColor:
                                      MaterialStateProperty.resolveWith<Color>(
                                    (Set<MaterialState> states) =>
                                        Colors.grey[200]!,
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
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DropdownButton<int>(
                          value: _rowsPerPage,
                          dropdownColor:
                              const Color.fromARGB(255, 255, 255, 255),
                          items: [5, 10].map((int value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text(
                                '$value per page',
                                style: const TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _rowsPerPage = value;
                                _currentPage = 0;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_left,
                            color: Colors.black,
                          ),
                          onPressed: _currentPage > 0
                              ? () {
                                  setState(() {
                                    _currentPage--;
                                  });
                                }
                              : null,
                        ),
                        Text(
                          'Page ${_currentPage + 1} of ${(filteredAdopters.length / _rowsPerPage).ceil()}',
                          style: const TextStyle(
                            color: Colors.black,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_right,
                            color: Colors.black,
                          ),
                          onPressed: (_currentPage + 1) * _rowsPerPage <
                                  filteredAdopters.length
                              ? () {
                                  setState(() {
                                    _currentPage++;
                                  });
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : AdopterDetailsScreen(
              adopter: selectedAdopter!,
              onBack: _goBackToList,
              onApprove: (Map<String, dynamic> p1) {},
            ),
    );
  }
}
