import 'package:flutter/material.dart';

class SettingsContent extends StatelessWidget {
  const SettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16), // Add margin around the container
      padding: const EdgeInsets.all(
          16), // Optional: Add padding inside the container
      decoration: BoxDecoration(
        color: Colors.white, // Optional: Background color
        borderRadius: BorderRadius.circular(8), // Optional: Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2), // Optional: Shadow color
            spreadRadius: 2,
            blurRadius: 6,
            offset: const Offset(0, 2), // Shadow position
          ),
        ],
      ),
      child: const Text(
        'Settings Panel',
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}
