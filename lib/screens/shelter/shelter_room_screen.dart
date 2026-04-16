import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../theme/pawmilya_palette.dart';

class ShelterRoomScreen extends StatefulWidget {
  const ShelterRoomScreen({super.key});

  @override
  State<ShelterRoomScreen> createState() => _ShelterRoomScreenState();
}

class _ShelterRoomScreenState extends State<ShelterRoomScreen> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shelter Room Monitoring'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // Assuming IoT devices update the shelter document or a sub-collection
        stream: FirebaseFirestore.instance
            .collection('shelters')
            .doc(user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load room data.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;

          // Replace these with actual field names from your hardware/backend if different
          final double temperature = data != null && data.containsKey('temperature')
              ? (data['temperature'] as num).toDouble()
              : 24.5; // Mock data if not present yet
          final double humidity = data != null && data.containsKey('humidity')
              ? (data['humidity'] as num).toDouble()
              : 60.0; // Mock data if not present yet

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusHeader(temperature, humidity),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Temperature',
                        value: '${temperature.toStringAsFixed(1)}°C',
                        icon: Icons.thermostat_outlined,
                        color: temperature > 30 ? Colors.red : Colors.orange,
                        subtitle: _getTempStatus(temperature),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Humidity',
                        value: '${humidity.toStringAsFixed(1)}%',
                        icon: Icons.water_drop_outlined,
                        color: Colors.blueAccent,
                        subtitle: _getHumidityStatus(humidity),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  'Tips for Animal Comfort:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildInfoTile(
                  icon: Icons.info_outline,
                  text: 'Ideal temperature for dogs and cats is 20°C to 26°C.',
                ),
                _buildInfoTile(
                  icon: Icons.info_outline,
                  text: 'Maintain humidity around 30% to 70% to prevent respiratory issues and mold.',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getTempStatus(double temp) {
    if (temp < 18) return 'Too Cold';
    if (temp > 28) return 'Too Hot';
    return 'Optimal';
  }

  String _getHumidityStatus(double humidity) {
    if (humidity < 30) return 'Too Dry';
    if (humidity > 70) return 'Too Humid';
    return 'Optimal';
  }

  Widget _buildStatusHeader(double temp, double hum) {
    bool isOptimal = (temp >= 18 && temp <= 28) && (hum >= 30 && hum <= 70);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOptimal ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOptimal ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOptimal ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            color: isOptimal ? Colors.green : Colors.red,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOptimal ? 'Environment is Stable' : 'Attention Required',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isOptimal ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOptimal
                      ? 'The conditions in the shelter room are optimal for the pets.'
                      : 'Please check the temperature and humidity. It might be uncomfortable for pets.',
                  style: TextStyle(
                    color: isOptimal ? Colors.green.shade900 : Colors.red.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: subtitle == 'Optimal' ? Colors.green : Colors.redAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: PawmilyaPalette.shelterGold, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
