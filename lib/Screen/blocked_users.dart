import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class InactiveAdoptersPage extends StatefulWidget {
  const InactiveAdoptersPage({super.key});

  @override
  State<InactiveAdoptersPage> createState() => _InactiveAdoptersPageState();
}

class _InactiveAdoptersPageState extends State<InactiveAdoptersPage> {
  List<dynamic> inactiveAdopters = [];
  List<dynamic> filteredAdopters = [];
  bool isLoading = true;
  String errorMessage = '';
  int _currentPage = 0;
  final int _rowsPerPage = 10;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchInactiveAdopters();
    _searchController.addListener(_filterAdopters);
  }

  Future<void> fetchInactiveAdopters() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:5566/api/admin/blockedadopters'), // Replace with your actual API endpoint
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // Use the token from the widget
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          inactiveAdopters = data['data'] ?? [];
          filteredAdopters = inactiveAdopters;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'Failed to load inactive adopters: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching data: $e';
        isLoading = false;
      });
    }
  }

  void _filterAdopters() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      filteredAdopters = inactiveAdopters.where((item) {
        final info = item['info'];
        final name = '${info['first_name']} ${info['last_name']}'.toLowerCase();
        return name.contains(_searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final paginatedAdopters = filteredAdopters
        .skip(_currentPage * _rowsPerPage)
        .take(_rowsPerPage)
        .toList();

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : filteredAdopters.isEmpty
                  ? const Center(child: Text('No inactive adopters found'))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Search Bar
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search by adopter name...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          setState(() {
                                            _searchController.clear();
                                            _searchQuery = '';
                                            filteredAdopters = inactiveAdopters;
                                            _currentPage = 0;
                                          });
                                        },
                                      )
                                    : null,
                              ),
                            ),
                          ),

                          // Table
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Container(
                                  width: constraints.maxWidth,
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
                                              label: Text(
                                                'Name',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                'Email',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                'Phone',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                'Address',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                'Status',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                'Actions',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                          rows: paginatedAdopters.map((item) {
                                            final adopter = item['adopter'];
                                            final info = item['info'];

                                            return DataRow(
                                              cells: [
                                                DataCell(Text(
                                                    '${info['first_name']} ${info['last_name']}')),
                                                DataCell(Text(
                                                    adopter['email'] ?? 'N/A')),
                                                DataCell(Text(
                                                    info['contact_number'] ??
                                                        'N/A')),
                                                DataCell(Text(
                                                    info['address'] ?? 'N/A')),
                                                DataCell(
                                                  Row(
                                                    children: const [
                                                      Icon(Icons.circle,
                                                          size: 12,
                                                          color: Colors.red),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'Inactive',
                                                        style: TextStyle(
                                                            color: Colors.red),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                DataCell(
                                                  Row(
                                                    children: [
                                                      TextButton(
                                                        onPressed: () {
                                                          _showReactivateDialog(
                                                              adopter[
                                                                  'adopter_id']);
                                                        },
                                                        child: const Text(
                                                            'Reactivate'),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      TextButton(
                                                        onPressed: () {
                                                          _showAdopterDetails(
                                                              item);
                                                        },
                                                        child: const Text(
                                                            'View Details'),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          }).toList(),
                                          headingRowColor: MaterialStateProperty
                                              .resolveWith<Color>(
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

                          // Pagination Controls
                          if (filteredAdopters.length > _rowsPerPage)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '${_currentPage * _rowsPerPage + 1}-${(_currentPage + 1) * _rowsPerPage > filteredAdopters.length ? filteredAdopters.length : (_currentPage + 1) * _rowsPerPage} of ${filteredAdopters.length}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left),
                                    onPressed: _currentPage > 0
                                        ? () {
                                            setState(() {
                                              _currentPage--;
                                            });
                                          }
                                        : null,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed:
                                        (_currentPage + 1) * _rowsPerPage <
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
                    ),
    );
  }

  void _showReactivateDialog(int adopterId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reactivate Account'),
        content: const Text(
            'Are you sure you want to reactivate this adopter account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _reactivateAdopter(adopterId);
              Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _reactivateAdopter(int adopterId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    try {
      final response = await http.put(
        Uri.parse(
            'http://127.0.0.1:5566/api/admin/adopters/$adopterId/activate'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // Use the token from the widget
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adopter reactivated successfully')),
        );
        fetchInactiveAdopters(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to reactivate adopter: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reactivating adopter: $e')),
      );
    }
  }

  void _showAdopterDetails(Map<String, dynamic> adopterData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Adopter Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildDetailItem('Name',
                '${adopterData['info']['first_name']} ${adopterData['info']['last_name']}'),
            _buildDetailItem('Email', adopterData['info']['email']),
            _buildDetailItem(
                'Phone', adopterData['info']['phone_number'] ?? 'N/A'),
            _buildDetailItem(
                'Address', adopterData['info']['address'] ?? 'N/A'),
            _buildDetailItem('Status', adopterData['adopter']['status']),
            _buildDetailItem('Created At',
                _formatDate(adopterData['adopter']['created_at'])),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
          const Divider(),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
