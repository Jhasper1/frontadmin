import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ShelterDetailsPage extends StatefulWidget {
  final Map<String, dynamic> shelter;
  final Function(Map<String, dynamic>) onApprove;
  final VoidCallback onBack;

  const ShelterDetailsPage({
    super.key,
    required this.shelter,
    required this.onApprove,
    required this.onBack,
  });

  @override
  _ShelterDetailsPageState createState() => _ShelterDetailsPageState();
}

class _ShelterDetailsPageState extends State<ShelterDetailsPage> {
  List<Map<String, dynamic>> adoptionHistory = [];
  List<Map<String, dynamic>> shelterPets = [];
  bool isLoadingHistory = false;
  bool isLoadingPets = false;
  bool showAdoptionHistory = true;
  bool hasFetchedHistory = false;
  bool hasFetchedPets = false;

  @override
  void initState() {
    super.initState();
    _fetchAdoptionHistory();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchAdoptionHistory() async {
    if (hasFetchedHistory) return;

    setState(() {
      isLoadingHistory = true;
    });

    final shelterId = widget.shelter['shelter_id']?.toString();
    print('Fetching adoption history for shelter_id: $shelterId');
    if (shelterId == null || shelterId.isEmpty) {
      throw Exception('Shelter ID cannot be null or empty');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      throw Exception('Authentication token cannot be null');
    }

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:4000/applications/shelter/$shelterId'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final shelterData = data['data']['shelter'];
        final historyData = data['data']['adoption_history'];

        widget.shelter['info'] = {
          'shelter_name': shelterData['name'],
          'shelter_email': shelterData['email'],
          'shelter_contact': shelterData['contact'],
          'shelter_address': shelterData['address'],
          'description': shelterData['profile'],
        };

        setState(() {
          adoptionHistory = List<Map<String, dynamic>>.from(historyData ?? []);
          isLoadingHistory = false;
          hasFetchedHistory = true;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          isLoadingHistory = false;
          hasFetchedHistory = true;
        });
      } else {
        setState(() {
          isLoadingHistory = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to load adoption history: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error fetching adoption history: $e');
      setState(() {
        isLoadingHistory = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong')),
      );
    }
  }

  Future<void> _fetchShelterPets() async {
    if (hasFetchedPets) return;

    setState(() {
      isLoadingPets = true;
    });

    final shelterId = widget.shelter['shelter_id']?.toString();
    print('Fetching shelter pets for shelter_id: $shelterId');
    if (shelterId == null || shelterId.isEmpty) {
      throw Exception('Shelter ID cannot be null or empty');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      throw Exception('Authentication token cannot be null');
    }

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:4000/shelter/$shelterId/pets'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          shelterPets = List<Map<String, dynamic>>.from(data['data'] ?? []);
          isLoadingPets = false;
          hasFetchedPets = true;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          isLoadingPets = false;
          hasFetchedPets = true;
        });
      } else {
        setState(() {
          isLoadingPets = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to load shelter pets: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error fetching shelter pets: $e');
      setState(() {
        isLoadingPets = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong')),
      );
    }
  }

  Widget _buildPetImagesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      shrinkWrap: false,
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.9,
      ),
      itemCount: shelterPets.length,
      itemBuilder: (context, index) {
        final pet = shelterPets[index];
        final petMedia = pet['petmedia'] ?? {};
        final imageData = petMedia['pet_image1'];

        return GestureDetector(
          onTap: () => _showPetDetails(context, pet),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageData != null
                      ? Image.memory(
                          base64Decode(imageData),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPetPlaceholder(),
                        )
                      : _buildPetPlaceholder(),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(12)),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        pet['pet_name'] ?? 'Mixed Breed',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPetPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets,
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              'No Image',
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPetDetails(BuildContext context, Map<String, dynamic> pet) {
    final petMedia = pet['petmedia'] ?? {};
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      height: 300,
                      width: double.infinity,
                      child: petMedia['pet_image1'] != null
                          ? Image.memory(
                              base64Decode(petMedia['pet_image1']),
                              fit: BoxFit.cover,
                            )
                          : _buildPetPlaceholder(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pet['pet_name'] ?? 'Unknown',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildDetailChip(
                                  '${pet['pet_age'] ?? 'N/A'} ${pet['age_type'] ?? ''}'),
                              _buildDetailChip(pet['pet_sex'] ?? 'N/A'),
                              _buildDetailChip(pet['pet_size'] != null
                                  ? '${pet['pet_size']} kg'
                                  : 'N/A'),
                              Chip(
                                label: Text(
                                  pet['status']?.toString().toUpperCase() ??
                                      'UNKNOWN',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: pet['status'] == 'available'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (pet['pet_descriptions'] != null) ...[
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(pet['pet_descriptions']!),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(String text) {
    return Chip(
      label: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      backgroundColor: Theme.of(context).cardColor,
      side: BorderSide(
        color: Theme.of(context).dividerColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.shelter['info'] ?? {};
    final status = widget.shelter['reg_status']?.toString().toLowerCase();

    if (widget.shelter['reg_status'] == null) {
      throw Exception('Shelter registration status cannot be null');
    }
    if (info['shelter_name'] == null) {
      throw Exception('Shelter name cannot be null');
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shelter (${status == 'approved' ? 'Approved' : 'Pending'})',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.blue[100],
                              child:
                                  widget.shelter['info']['description'] != null
                                      ? ClipOval(
                                          child: Image.memory(
                                            base64Decode(widget.shelter['info']
                                                ['description']),
                                            fit: BoxFit.cover,
                                            width: 100,
                                            height: 100,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Icon(
                                              Icons.pets,
                                              size: 50,
                                              color: Colors.blue[700],
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          Icons.pets,
                                          size: 50,
                                          color: Colors.blue[700],
                                        ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Name: ${widget.shelter['info']['shelter_name']}',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Contact Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Email: ${widget.shelter['info']['shelter_email'] ?? 'N/A'}',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Phone: ${widget.shelter['info']['shelter_contact'] ?? 'N/A'}',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Address: ${widget.shelter['info']['shelter_address'] ?? 'N/A'}',
                            style: TextStyle(fontSize: 16),
                          ),
                          if (widget.shelter['info']['description'] !=
                              null) ...[
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (status != 'approved') ...[
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: () => widget.onApprove(widget.shelter),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
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
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                showAdoptionHistory = true;
                              });
                              _fetchAdoptionHistory();
                            },
                            child: const Text('Adoption History'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                showAdoptionHistory = false;
                              });
                              _fetchShelterPets();
                            },
                            child: const Text('Pets'),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: widget.onBack,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: showAdoptionHistory
                        ? (isLoadingHistory
                            ? const Center(child: CircularProgressIndicator())
                            : adoptionHistory.isEmpty
                                ? Center(
                                    child: Text(
                                      'No history available',
                                      style: TextStyle(),
                                    ),
                                  )
                                : LayoutBuilder(
                                    builder: (context, constraints) {
                                      final tableWidth = constraints.maxWidth;
                                      return SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: DataTable(
                                          columns: const [
                                            DataColumn(
                                                label: Text('Adopter Name')),
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
                                                      history['adopter_name'] ??
                                                          'N/A'),
                                                )),
                                                DataCell(Container(
                                                  width: tableWidth * 0.25,
                                                  child: Text(
                                                      history['pet_name'] ??
                                                          'N/A'),
                                                )),
                                                DataCell(Container(
                                                  width: tableWidth * 0.25,
                                                  child: Text(
                                                    history['status']
                                                            ?.toString()
                                                            .toUpperCase() ??
                                                        'N/A',
                                                    style: TextStyle(
                                                      color:
                                                          history['status'] ==
                                                                  'completed'
                                                              ? Colors.green
                                                              : Colors.orange,
                                                    ),
                                                  ),
                                                )),
                                                DataCell(Container(
                                                  width: tableWidth * 0.25,
                                                  child: Text(
                                                      history['date'] ?? 'N/A'),
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
                                  ))
                        : (isLoadingPets
                            ? const Center(child: CircularProgressIndicator())
                            : shelterPets.isEmpty
                                ? Center(
                                    child: Text(
                                      'No pets available',
                                      style: TextStyle(),
                                    ),
                                  )
                                : _buildPetImagesGrid()),
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
