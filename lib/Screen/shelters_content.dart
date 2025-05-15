import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SheltersContent extends StatefulWidget {
  const SheltersContent({Key? key}) : super(key: key);

  @override
  _SheltersContentState createState() => _SheltersContentState();
}

class _SheltersContentState extends State<SheltersContent> {
  List<dynamic> pendingShelters = [];
  List<dynamic> approvedShelters = [];
  bool isLoading = true;
  String errorMessage = '';
  bool showApproved = false;
  int _rowsPerPage = 10;
  int _currentPage = 0;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _fetchShelters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchShelters() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final url = 'http://127.0.0.1:5566/api/admin/getallshelterstry';
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint("API Response: $responseData");

        if (responseData['retCode'] == '200') {
          final shelters = responseData['data'] as List;
          _categorizeShelters(shelters);
        } else if (responseData['retCode'] == '401') {
          _handleUnauthorized();
        } else {
          throw Exception(
              'Failed to load shelters. Message: ${responseData['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching shelters: $e');
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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

  void _categorizeShelters(List<dynamic> shelters) {
    final List<dynamic> approved = [];
    final List<dynamic> pending = [];

    for (var shelter in shelters) {
      if (_isShelterApproved(shelter)) {
        approved.add(shelter);
      } else {
        pending.add(shelter);
      }
    }

    setState(() {
      approvedShelters = approved;
      pendingShelters = pending;
    });
  }

  bool _isShelterApproved(dynamic shelter) {
    final status = (shelter['reg_status'] ??
            shelter['shelter']?['reg_status'] ??
            shelter['shelter_id']?['reg_status'] ??
            'pending')
        .toString()
        .toLowerCase();
    return status == 'approved';
  }

  int? _extractShelterId(dynamic shelterData) {
    if (shelterData['shelter_id'] is int) return shelterData['shelter_id'];
    if (shelterData['shelter'] is Map &&
        shelterData['shelter']['shelter_id'] is int) {
      return shelterData['shelter']['shelter_id'];
    }
    if (shelterData['id'] is int) return shelterData['id'];
    return null;
  }

  Future<void> _approveShelter(dynamic shelterData) async {
    try {
      final shelterId = _extractShelterId(shelterData);
      if (shelterId == null) throw Exception('Invalid shelter ID');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('No authentication token found');

      debugPrint('Approving shelter ID: $shelterId');

      final response = await http.put(
        Uri.parse(
            'http://127.0.0.1:5566/api/admin/shelters/$shelterId/approve'),
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _handleApprovalSuccess(shelterData, shelterId);
        _showSuccessMessage('Shelter approved successfully!');
        Navigator.of(context).pop();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ??
            'Approval failed with status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in _approveShelter: $e');
      _showErrorMessage(
          'Failed to approve: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  void _handleApprovalSuccess(dynamic shelterData, int shelterId) {
    final index =
        pendingShelters.indexWhere((s) => _extractShelterId(s) == shelterId);
    if (index == -1) return;

    final approvedShelter = _updateShelterStatus(shelterData);

    setState(() {
      pendingShelters.removeAt(index);
      approvedShelters.add(approvedShelter);
    });
  }

  dynamic _updateShelterStatus(dynamic shelter) {
    final updated = Map<String, dynamic>.from(shelter);

    void deepUpdate(Map<String, dynamic> data) {
      data['reg_status'] = 'approved';
      if (data['shelter_id'] is Map) deepUpdate(data['shelter_id']);
      if (data['shelter'] is Map) deepUpdate(data['shelter']);
    }

    deepUpdate(updated);
    return updated;
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
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

  void _showShelterDialog(dynamic shelterData) {
    final info = shelterData['info'] ?? {};
    final status = _isShelterApproved(shelterData) ? 'Approved' : 'Pending';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Shelter Details ($status)'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.7,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Name', info['shelter_name']),
                _buildDetailRow('Address', info['shelter_address']),
                _buildDetailRow('Contact', info['shelter_contact']),
                _buildDetailRow('Email', info['shelter_email']),
                _buildDetailRow('Status', status),
                if (info['description'] != null)
                  _buildDetailRow('Description', info['description']),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!_isShelterApproved(shelterData))
            ElevatedButton(
              onPressed: () => _approveShelter(shelterData),
              child: const Text('Approve'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
          Expanded(
            child: Text(
              value ?? 'Not provided',
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic> _filterShelters(List<dynamic> shelters) {
    if (_searchQuery.isEmpty) return shelters;

    return shelters.where((shelter) {
      final info = shelter['info'] ?? {};
      final name = info['shelter_name']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<dynamic> _getPaginatedShelters(List<dynamic> shelters) {
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;
    return shelters.sublist(
        startIndex, endIndex > shelters.length ? shelters.length : endIndex);
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
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.red,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchShelters,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.grey[800] : Colors.blue,
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

    final filteredShelters = showApproved
        ? _filterShelters(approvedShelters)
        : _filterShelters(pendingShelters);

    final paginatedShelters = _getPaginatedShelters(filteredShelters);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Row for Pending/Approved Shelters
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    showApproved
                        ? 'Approved Shelters (${filteredShelters.length})'
                        : 'Pending Shelters (${filteredShelters.length})',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          isDarkMode ? Colors.white : const Color(0xff1e1e20),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            showApproved = !showApproved; // Toggle the state
                            _currentPage = 0; // Reset the current page
                          });
                        },
                        child: Text(
                          showApproved ? 'Show Pending' : 'Show Approved',
                          style: TextStyle(
                            color: isDarkMode ? Colors.blue[300] : Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width *
                        0.4, // 40% of the screen width
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by shelter name...',
                        hintStyle: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[700],
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
                        fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[700],
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
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _currentPage = 0;
                        });
                      },
                    ),
                  ),
                ],
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
                        color:
                            isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: isDarkMode ? Colors.grey[900] : Colors.white,
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
                                  label: Text('Contact',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Email',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Status',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Actions',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                            ],
                            rows: paginatedShelters.map((shelter) {
                              final info = shelter['info'] ?? {};
                              final status = _isShelterApproved(shelter)
                                  ? 'Approved'
                                  : 'Pending';

                              return DataRow(
                                cells: [
                                  DataCell(
                                    ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 200),
                                      child: Text(
                                        info['shelter_name'] ??
                                            'Unnamed Shelter',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(
                                    info['shelter_contact'] ?? 'Not provided',
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  )),
                                  DataCell(Text(
                                    info['shelter_email'] ?? 'Not provided',
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  )),
                                  DataCell(
                                    Chip(
                                      label: Text(
                                        status,
                                        style: TextStyle(
                                          color: status == 'Approved'
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                      ),
                                      backgroundColor: status == 'Approved'
                                          ? Colors.green[50]
                                          : Colors.orange[50],
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.visibility,
                                            size: 20,
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                          onPressed: () =>
                                              _showShelterDialog(shelter),
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
            if (filteredShelters.length > _rowsPerPage)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    DropdownButton<int>(
                      value: _rowsPerPage,
                      dropdownColor:
                          isDarkMode ? Colors.grey[800] : Colors.white,
                      items: [5, 10, 25, 50].map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(
                            '$value per page',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
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
                    Text(
                      '${_currentPage * _rowsPerPage + 1}-${(_currentPage + 1) * _rowsPerPage > filteredShelters.length ? filteredShelters.length : (_currentPage + 1) * _rowsPerPage} of ${filteredShelters.length}',
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
                      onPressed: _currentPage > 0
                          ? () {
                              setState(() {
                                _currentPage--;
                              });
                            }
                          : null,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chevron_right,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      onPressed: (_currentPage + 1) * _rowsPerPage <
                              filteredShelters.length
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
      ),
    );
  }
}
