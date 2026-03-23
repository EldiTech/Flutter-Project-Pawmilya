import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/shelter_zone.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';

class ShelterRoomScreen extends StatelessWidget {
  const ShelterRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmBg,
      appBar: AppBar(
        title: const Text('Shelter Room'),
        backgroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openZoneDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Zone'),
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          final zones = [...provider.zones]
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          final avgHumidity = zones.isEmpty
              ? 0
              : (zones.map((zone) => zone.humidity).reduce((a, b) => a + b) / zones.length).round();
          final avgTemp = zones.isEmpty
              ? 0
              : (zones.map((zone) => zone.temp).reduce((a, b) => a + b) / zones.length).round();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: 'Avg Humidity',
                      value: '$avgHumidity%',
                      icon: Icons.water_drop_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      title: 'Avg Temperature',
                      value: '$avgTemp°C',
                      icon: Icons.thermostat_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (zones.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Text('No zones found.'),
                ))
              else
                ...zones.map(
                  (zone) => Card(
                    color: Colors.white,
                    child: ListTile(
                      title: Text(zone.name),
                      subtitle: Text(
                        'Humidity: ${zone.humidity}% (${zone.humidityStatus})\n'
                        'Temperature: ${zone.temp}°C (${zone.tempStatus})',
                      ),
                      isThreeLine: true,
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _openZoneDialog(context, existing: zone),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteZone(context, zone),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openZoneDialog(BuildContext context, {ShelterZone? existing}) async {
    final result = await showDialog<_ZoneFormData>(
      context: context,
      builder: (_) => _ZoneDialog(existing: existing),
    );

    if (result == null || !context.mounted) return;

    try {
      if (existing == null) {
        await context.read<DashboardProvider>().addZone(
              name: result.name,
              humidity: result.humidity,
              humidityStatus: result.humidityStatus,
              temp: result.temp,
              tempStatus: result.tempStatus,
            );
      } else {
        await context.read<DashboardProvider>().editZone(
              existing.id,
              name: result.name,
              humidity: result.humidity,
              humidityStatus: result.humidityStatus,
              temp: result.temp,
              tempStatus: result.tempStatus,
            );
      }
      if (!context.mounted) return;
      _showMessage(context, existing == null ? 'Zone added.' : 'Zone updated.');
    } catch (error) {
      if (!context.mounted) return;
      _showMessage(context, 'Failed to save zone: $error');
    }
  }

  Future<void> _deleteZone(BuildContext context, ShelterZone zone) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete zone?'),
        content: Text('Delete ${zone.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<DashboardProvider>().removeZone(zone.id);
      if (!context.mounted) return;
      _showMessage(context, 'Zone deleted.');
    } catch (error) {
      if (!context.mounted) return;
      _showMessage(context, 'Failed to delete zone: $error');
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ZoneFormData {
  const _ZoneFormData({
    required this.name,
    required this.humidity,
    required this.humidityStatus,
    required this.temp,
    required this.tempStatus,
  });

  final String name;
  final int humidity;
  final String humidityStatus;
  final int temp;
  final String tempStatus;
}

class _ZoneDialog extends StatefulWidget {
  const _ZoneDialog({this.existing});

  final ShelterZone? existing;

  @override
  State<_ZoneDialog> createState() => _ZoneDialogState();
}

class _ZoneDialogState extends State<_ZoneDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _humidityController;
  late final TextEditingController _tempController;

  late String _humidityStatus;
  late String _tempStatus;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _humidityController = TextEditingController(text: (existing?.humidity ?? 0).toString());
    _tempController = TextEditingController(text: (existing?.temp ?? 0).toString());
    _humidityStatus = existing?.humidityStatus ?? 'Normal';
    _tempStatus = existing?.tempStatus ?? 'Normal';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _humidityController.dispose();
    _tempController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Zone' : 'Edit Zone'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Zone Name'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _humidityController,
                decoration: const InputDecoration(labelText: 'Humidity (%)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final humidity = int.tryParse((value ?? '').trim());
                  if (humidity == null) return 'Enter a number';
                  if (humidity < 0 || humidity > 100) return 'Use 0 to 100';
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: _humidityStatus,
                items: const [
                  DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'High', child: Text('High')),
                  DropdownMenuItem(value: 'Low', child: Text('Low')),
                ],
                onChanged: (value) => setState(() => _humidityStatus = value ?? 'Normal'),
                decoration: const InputDecoration(labelText: 'Humidity Status'),
              ),
              TextFormField(
                controller: _tempController,
                decoration: const InputDecoration(labelText: 'Temperature (°C)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final temp = int.tryParse((value ?? '').trim());
                  if (temp == null) return 'Enter a number';
                  if (temp < 0 || temp > 50) return 'Use 0 to 50';
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: _tempStatus,
                items: const [
                  DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'Warm', child: Text('Warm')),
                  DropdownMenuItem(value: 'Cool', child: Text('Cool')),
                  DropdownMenuItem(value: 'Hot', child: Text('Hot')),
                ],
                onChanged: (value) => setState(() => _tempStatus = value ?? 'Normal'),
                decoration: const InputDecoration(labelText: 'Temperature Status'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      _ZoneFormData(
        name: _nameController.text.trim(),
        humidity: int.parse(_humidityController.text.trim()),
        humidityStatus: _humidityStatus,
        temp: int.parse(_tempController.text.trim()),
        tempStatus: _tempStatus,
      ),
    );
  }
}
