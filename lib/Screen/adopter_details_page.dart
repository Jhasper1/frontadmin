import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

class AdopterDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> adopter;
  final VoidCallback onBack;
  final Function(Map<String, dynamic>) onApprove;

  const AdopterDetailsScreen({
    super.key,
    required this.adopter,
    required this.onBack,
    required this.onApprove,
  });

  @override
  _AdopterDetailsScreenState createState() => _AdopterDetailsScreenState();
}

class _AdopterDetailsScreenState extends State<AdopterDetailsScreen> {
  Map<String, dynamic> adopterData = {};
  List<Map<String, dynamic>> adoptionHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdopterData();
  }

  Future<void> _fetchAdopterData() async {
    final adopterId = widget.adopter['adopter_id'].toString();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:4000/applications/adopter/$adopterId'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('API Response: $data'); // Debug print to inspect response
        setState(() {
          adopterData =
              Map<String, dynamic>.from(data['data']['adopter'] ?? {});
          adoptionHistory = List<Map<String, dynamic>>.from(
              data['data']['adoption_history'] ?? []);
          isLoading = false;
          print(
              'Adopter Data: $adopterData'); // Debug print to inspect adopterData
          print(
              'Adoption History: $adoptionHistory'); // Debug print to inspect adoptionHistory
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to load adopter data: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      print('Error fetching adopter data: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching adopter data')),
      );
    }
  }

  Uint8List? decodeBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (e) {
      print('Error decoding base64 image: $e');
      return null;
    }
  }

  Widget buildProfileImage(String? base64Profile) {
    if (base64Profile == null || base64Profile.isEmpty) {
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.blue[100],
        child: Icon(
          Icons.person,
          size: 50,
          color: Colors.blue[700],
        ),
      );
    }

    final imageBytes = decodeBase64Image(base64Profile);
    if (imageBytes == null) {
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.blue[100],
        child: Icon(
          Icons.person,
          size: 50,
          color: Colors.blue[700],
        ),
      );
    }

    return CircleAvatar(
      radius: 50,
      backgroundImage: MemoryImage(imageBytes),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Adopter Section (Left Panel)
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Adopter',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: buildProfileImage(adopterData['profile']),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Name: ${adopterData['name'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Contact Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Email: ${adopterData['email'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Phone: ${adopterData['contact'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Address: ${adopterData['address'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Adoption History Section (Right Panel)
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Adoption History',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: widget.onBack,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (adoptionHistory.isEmpty)
                          const Center(child: Text('No adoption history found'))
                        else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final tableWidth = constraints.maxWidth;
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Shelter Name')),
                                    DataColumn(label: Text('Pet Name')),
                                    DataColumn(label: Text('Status')),
                                    DataColumn(label: Text('Date')),
                                  ],
                                  rows: adoptionHistory.map((history) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Container(
                                          width: tableWidth * 0.25,
                                          child: Text(
                                              history['shelter_name'] ?? 'N/A'),
                                        )),
                                        DataCell(Container(
                                          width: tableWidth * 0.25,
                                          child: Text(
                                              history['pet_name'] ?? 'N/A'),
                                        )),
                                        DataCell(Container(
                                          width: tableWidth * 0.25,
                                          child: Text(
                                            history['status']
                                                    ?.toString()
                                                    .toUpperCase() ??
                                                'N/A',
                                            style: TextStyle(
                                              color: history['status'] ==
                                                      'completed'
                                                  ? Colors.green
                                                  : Colors.orange,
                                            ),
                                          ),
                                        )),
                                        DataCell(Container(
                                          width: tableWidth * 0.25,
                                          child: Text(history['date'] ?? 'N/A'),
                                        )),
                                      ],
                                    );
                                  }).toList(),
                                  dataRowHeight: 50,
                                  headingRowHeight: 40,
                                  horizontalMargin: 12,
                                  columnSpacing: 16,
                                  showCheckboxColumn: false,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
