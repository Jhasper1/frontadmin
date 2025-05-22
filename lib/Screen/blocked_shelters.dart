import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BlockedSheltersScreen extends StatefulWidget {
  @override
  _BlockedSheltersScreenState createState() => _BlockedSheltersScreenState();
}

class _BlockedSheltersScreenState extends State<BlockedSheltersScreen> {
  late Future<Map<String, dynamic>> _reports;
  List<dynamic> shelters = [];
  dynamic selectedShelter;

  @override
  void initState() {
    super.initState();
    _reports = fetchSubmittedReports();
    _reports.then((data) {
      setState(() {
        shelters = data['data'] ?? [];
        if (shelters.isNotEmpty) {
          selectedShelter = shelters[0];
        }
      });
    });
  }

  Future<Map<String, dynamic>> fetchSubmittedReports() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('http://127.0.0.1:5566/admin/blockedshelters'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      _handleUnauthorized();
      return {'data': []};
    } else {
      throw Exception('Failed to load reports: ${response.statusCode}');
    }
  }

  void _handleUnauthorized() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  Widget _buildShelterProfileImage(dynamic shelter) {
    final profile = shelter['shelter_profile'];
    if (profile == null || profile.isEmpty) {
      return CircleAvatar(
        backgroundColor: Colors.grey.shade300,
        child: Icon(Icons.pets, color: Colors.grey.shade600),
      );
    }

    try {
      return CircleAvatar(
        backgroundImage: MemoryImage(base64Decode(profile)),
        backgroundColor: Colors.grey.shade300,
      );
    } catch (e) {
      print('Error decoding base64 image: $e');
      return CircleAvatar(
        backgroundColor: Colors.grey.shade300,
        child: Icon(Icons.error_outline, color: Colors.red),
      );
    }
  }

  void _showBlockConfirmationDialog(BuildContext context, dynamic shelter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unblock Shelter'),
        content: Text(
            'Are you sure you want to unblock "${shelter['shelter_name'] ?? 'this shelter'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close dialog
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await _blockShelter(context, shelter['shelter_id']);
            },
            child: Text('Unblock'),
          ),
        ],
      ),
    );
  }

  Future<void> _blockShelter(BuildContext context, int shelterId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No authentication token found')),
      );
      return;
    }

    final response = await http.put(
      Uri.parse('http://127.0.0.1:5566/admin/shelters/$shelterId/activate'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Shelter unblocked successfully')),
      );

      // Refresh data
      final updatedReports = await fetchSubmittedReports();
      setState(() {
        shelters = updatedReports['data'] ?? [];
        selectedShelter = shelters.isNotEmpty ? shelters[0] : null;
      });
    } else {
      final errorMsg =
          json.decode(response.body)['message'] ?? 'Failed to unblock shelter';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $errorMsg')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _reports,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Left Panel: Reported Shelters
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 16),
                          child: Text(
                            'Blocked Shelters',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: shelters.length,
                            itemBuilder: (context, index) {
                              final shelter = shelters[index];
                              bool isSelected = selectedShelter == shelter;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedShelter = shelter;
                                  });
                                },
                                child: Container(
                                  color: isSelected
                                      ? Colors.grey.shade300
                                      : Colors.transparent,
                                  child: ListTile(
                                    leading: _buildShelterProfileImage(shelter),
                                    title: Text(
                                      shelter['shelter_name'] ??
                                          'Unknown Shelter',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                        '${shelter['total_reports'] ?? 0} reports'),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 20),
                // Right Panel: Report Details
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (selectedShelter != null) ...[
                          Row(
                            children: [
                              _buildShelterProfileImage(selectedShelter),
                              SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedShelter['shelter_name'] ??
                                        'Unknown Shelter',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    selectedShelter['shelter_email'] ??
                                        'No email',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                        ],
                        Text(
                          'Report Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: DataTable(
                                columnSpacing: 20,
                                headingRowColor: MaterialStateProperty.all(
                                    Colors.grey.shade200),
                                columns: const [
                                  DataColumn(
                                      label: SizedBox(
                                          width: 150,
                                          child: Text('Adopter Name'))),
                                  DataColumn(
                                      label: SizedBox(
                                          width: 150, child: Text('Reason'))),
                                  DataColumn(
                                      label: SizedBox(
                                          width: 300,
                                          child: Text('Description'))),
                                  DataColumn(
                                      label: SizedBox(
                                          width: 150, child: Text('Date'))),
                                ],
                                rows: selectedShelter != null
                                    ? (selectedShelter['reports']
                                                as List<dynamic>? ??
                                            [])
                                        .map((report) => DataRow(cells: [
                                              DataCell(SizedBox(
                                                  width: 150,
                                                  child: Text(report[
                                                              'reported_by']
                                                          ?['adopter_name'] ??
                                                      'N/A'))),
                                              DataCell(SizedBox(
                                                  width: 150,
                                                  child: Text(
                                                      report['reason'] ??
                                                          'N/A'))),
                                              DataCell(SizedBox(
                                                  width: 300,
                                                  child: Text(
                                                      report['description'] ??
                                                          'N/A'))),
                                              DataCell(SizedBox(
                                                  width: 150,
                                                  child: Text(
                                                      report['created_at'] ??
                                                          'N/A'))),
                                            ]))
                                        .toList()
                                    : [],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                            label: Text('Unblock Shelter'),
                            onPressed: () {
                              if (selectedShelter != null) {
                                _showBlockConfirmationDialog(
                                    context, selectedShelter);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
