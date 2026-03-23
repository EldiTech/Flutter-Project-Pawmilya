import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/adoption_application.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmBg,
      appBar: AppBar(
        title: const Text('Applications'),
        backgroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openApplicationDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Application'),
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          final query = _searchController.text.trim().toLowerCase();
          final applications = provider.applications.where((app) {
            if (query.isEmpty) return true;
            return app.applicant.toLowerCase().contains(query) ||
                app.animal.toLowerCase().contains(query) ||
                app.status.toLowerCase().contains(query);
          }).toList()
            ..sort((a, b) => (b.date ?? '').compareTo(a.date ?? ''));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search applications',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Expanded(
                child: applications.isEmpty
                    ? const Center(child: Text('No applications found.'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                        itemCount: applications.length,
                        itemBuilder: (context, index) {
                          final app = applications[index];
                          return Card(
                            color: Colors.white,
                            child: ListTile(
                              title: Text(app.applicant),
                              subtitle: Text('${app.animal} • ${app.date ?? 'No date'}'),
                              trailing: Wrap(
                                spacing: 6,
                                children: [
                                  Chip(
                                    label: Text(app.status),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  if (app.status == 'Pending')
                                    IconButton(
                                      tooltip: 'Approve',
                                      icon: const Icon(Icons.check_circle_outline),
                                      onPressed: () => _changeStatus(app.id, 'Approved'),
                                    ),
                                  if (app.status == 'Pending')
                                    IconButton(
                                      tooltip: 'Reject',
                                      icon: const Icon(Icons.cancel_outlined),
                                      onPressed: () => _changeStatus(app.id, 'Rejected'),
                                    ),
                                  IconButton(
                                    onPressed: () => _openApplicationDialog(existing: app),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteApplication(app),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openApplicationDialog({AdoptionApplication? existing}) async {
    final provider = context.read<DashboardProvider>();
    final animals = provider.pets
        .where((pet) => pet.status == 'Available' || pet.status == 'Pending')
        .map((pet) => pet.name)
        .toSet()
        .toList()
      ..sort();

    final result = await showDialog<_ApplicationFormData>(
      context: context,
      builder: (_) => _ApplicationDialog(existing: existing, animalOptions: animals),
    );

    if (result == null || !mounted) return;

    try {
      if (existing == null) {
        await provider.addApplication(
          applicant: result.applicant,
          animal: result.animal,
          status: result.status,
          date: result.date,
        );
      } else {
        await provider.editApplication(
          existing.id,
          applicant: result.applicant,
          animal: result.animal,
          status: result.status,
          date: result.date,
        );
      }
      _showMessage(existing == null ? 'Application added.' : 'Application updated.');
    } catch (error) {
      _showMessage('Failed to save application: $error');
    }
  }

  Future<void> _changeStatus(String id, String status) async {
    try {
      await context.read<DashboardProvider>().setApplicationStatus(id, status);
      _showMessage('Application marked $status.');
    } catch (error) {
      _showMessage('Failed to update status: $error');
    }
  }

  Future<void> _deleteApplication(AdoptionApplication application) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete application?'),
        content: Text('Delete application from ${application.applicant}?'),
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

    if (confirmed != true || !mounted) return;

    try {
      await context.read<DashboardProvider>().removeApplication(application.id);
      _showMessage('Application deleted.');
    } catch (error) {
      _showMessage('Failed to delete application: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ApplicationFormData {
  const _ApplicationFormData({
    required this.applicant,
    required this.animal,
    required this.status,
    this.date,
  });

  final String applicant;
  final String animal;
  final String status;
  final String? date;
}

class _ApplicationDialog extends StatefulWidget {
  const _ApplicationDialog({
    required this.animalOptions,
    this.existing,
  });

  final AdoptionApplication? existing;
  final List<String> animalOptions;

  @override
  State<_ApplicationDialog> createState() => _ApplicationDialogState();
}

class _ApplicationDialogState extends State<_ApplicationDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _applicantController;
  late final TextEditingController _dateController;

  late String _animal;
  late String _status;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _applicantController = TextEditingController(text: existing?.applicant ?? '');
    _dateController = TextEditingController(text: existing?.date ?? '');

    final options = widget.animalOptions;
    final initialAnimal = existing?.animal ?? (options.isNotEmpty ? options.first : '');
    _animal = initialAnimal;
    _status = existing?.status ?? 'Pending';
  }

  @override
  void dispose() {
    _applicantController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.animalOptions;

    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Application' : 'Edit Application'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _applicantController,
                decoration: const InputDecoration(labelText: 'Applicant Name'),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Required';
                  if (text.length < 2) return 'Applicant name is too short';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              if (options.isEmpty)
                TextFormField(
                  initialValue: _animal,
                  decoration: const InputDecoration(labelText: 'Animal'),
                  onChanged: (value) => _animal = value,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: options.contains(_animal) ? _animal : options.first,
                  items: options
                      .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                      .toList(),
                  onChanged: (value) => setState(() => _animal = value ?? options.first),
                  decoration: const InputDecoration(labelText: 'Animal'),
                ),
              DropdownButtonFormField<String>(
                initialValue: _status,
                items: const [
                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'Approved', child: Text('Approved')),
                  DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
                ],
                onChanged: (value) => setState(() => _status = value ?? 'Pending'),
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Date (YYYY-MM-DD)',
                  suffixIcon: IconButton(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                  ),
                ),
                validator: _validateIsoDate,
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

    final cleanedAnimal = _animal.trim();
    if (cleanedAnimal.isEmpty) {
      return;
    }

    final cleanedDate = _dateController.text.trim();
    final safeDate = cleanedDate.isEmpty ? DateTime.now().toIso8601String().split('T').first : cleanedDate;

    Navigator.pop(
      context,
      _ApplicationFormData(
        applicant: _applicantController.text.trim(),
        animal: cleanedAnimal,
        status: _status,
        date: safeDate,
      ),
    );
  }

  String? _validateIsoDate(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final pattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!pattern.hasMatch(text)) return 'Use YYYY-MM-DD';
    if (DateTime.tryParse(text) == null) return 'Invalid date';
    return null;
  }

  Future<void> _pickDate() async {
    final initialDate = DateTime.tryParse(_dateController.text.trim()) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    _dateController.text = date.toIso8601String().split('T').first;
  }
}
