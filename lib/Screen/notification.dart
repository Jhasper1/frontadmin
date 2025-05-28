import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class ReportNotificationsScreen extends StatefulWidget {
  const ReportNotificationsScreen({super.key});

  @override
  State<ReportNotificationsScreen> createState() =>
      _ReportNotificationsScreenState();
}

class _ReportNotificationsScreenState extends State<ReportNotificationsScreen> {
  List<dynamic> reports = [];
  bool isLoading = true;
  bool isError = false;
  String errorMessage = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchReportNotifications();

    // Fetch notifications every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchReportNotifications();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchReportNotifications(); // Automatically fetch notifications
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  Future<void> _fetchReportNotifications() async {
    setState(() {
      isLoading = true;
      isError = false;
    });

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:4000/admin/notifications'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          reports = [
            ...data['report_notifications'] ?? [],
            ...data['shelter_notifications'] ?? [],
          ];
          isLoading = false;
        });
      } else {
        setState(() {
          isError = true;
          errorMessage = 'Failed to load notifications: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isError = true;
        errorMessage = 'Error fetching notifications: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchReportNotifications,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (isError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorMessage),
            ElevatedButton(
              onPressed: _fetchReportNotifications,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (reports.isEmpty) {
      return const Center(child: Text('No reports found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return _buildReportCard(report);
      },
    );
  }

  Widget _buildReportCard(Map<String, dynamic> notification) {
    final isReport = notification.containsKey('report_id');
    final height = 180.0; // Uniform height for all notifications

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      height: height,
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isReport ? Colors.red[200] : Colors.blue[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isReport ? Icons.warning : Icons.store,
                        size: 16,
                        color: isReport ? Colors.red[800] : Colors.blue[800],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isReport
                          ? 'Report #${notification['report_id']}'
                          : 'Shelter Signup: ${notification['shelter_name']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                if (isReport)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(notification['status']),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      notification['status'].toString().toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (isReport)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reason: ${notification['reason']}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['description'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email: ${notification['email']}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isReport) ...[
                      Row(
                        children: [
                          const Icon(Icons.person, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${notification['first_name']} ${notification['last_name']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.home, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            notification['shelter_name'],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          notification['created_at'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    if (isReport) {
                      // Navigate directly to ReportedSheltersContent
                      context.go(
                          '/dashboard/reported/shelters'); // Direct navigation
                    } else {
                      // Navigate directly to SheltersContent
                      context.go(
                          '/dashboard/shelter/content'); // Direct navigation
                    }
                  },
                  child: const Text('VIEW DETAILS'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'reported':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showReportDetails(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Report #${report['report_id']}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Status', report['status']),
                _buildDetailRow('Reason', report['reason']),
                _buildDetailRow('Description', report['description']),
                _buildDetailRow('Adopter',
                    '${report['first_name']} ${report['last_name']}'),
                _buildDetailRow('Shelter', report['shelter_name']),
                _buildDetailRow('Reported At', report['created_at']),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  void _showShelterDetails(Map<String, dynamic> shelter) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Shelter Signup: ${shelter['shelter_name']}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Email', shelter['email']),
                _buildDetailRow('Created At', shelter['created_at']),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
