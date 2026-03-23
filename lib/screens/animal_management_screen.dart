import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pet.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';

class AnimalManagementScreen extends StatefulWidget {
  const AnimalManagementScreen({super.key});

  @override
  State<AnimalManagementScreen> createState() => _AnimalManagementScreenState();
}

class _AnimalManagementScreenState extends State<AnimalManagementScreen> {
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
        title: const Text('Animal Management'),
        backgroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPetDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Animal'),
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          final query = _searchController.text.trim().toLowerCase();
          final pets = provider.pets.where((pet) {
            if (query.isEmpty) return true;
            return pet.name.toLowerCase().contains(query) ||
                pet.species.toLowerCase().contains(query) ||
                pet.breed.toLowerCase().contains(query);
          }).toList()
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search animals',
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
                child: pets.isEmpty
                    ? const Center(child: Text('No animals found.'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                        itemCount: pets.length,
                        itemBuilder: (context, index) {
                          final pet = pets[index];
                          return Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ListTile(
                              title: Text(pet.name),
                              subtitle: Text(
                                '${pet.species} • ${pet.breed} • ${pet.gender} • ${pet.age}',
                              ),
                              trailing: Wrap(
                                spacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Chip(
                                    label: Text(pet.status),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  IconButton(
                                    onPressed: () => _openPetDialog(existing: pet),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    onPressed: () => _deletePet(pet),
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

  Future<void> _openPetDialog({Pet? existing}) async {
    final result = await showDialog<_PetFormData>(
      context: context,
      builder: (_) => _PetDialog(existing: existing),
    );

    if (result == null || !mounted) return;
    final provider = context.read<DashboardProvider>();

    try {
      if (existing == null) {
        await provider.addPet(
          name: result.name,
          species: result.species,
          breed: result.breed,
          age: result.age,
          gender: result.gender,
          status: result.status,
          dateAdmitted: result.dateAdmitted,
          notes: result.notes,
        );
      } else {
        await provider.editPet(
          existing.id,
          name: result.name,
          species: result.species,
          breed: result.breed,
          age: result.age,
          gender: result.gender,
          status: result.status,
          dateAdmitted: result.dateAdmitted,
          notes: result.notes,
        );
      }
      _showMessage(existing == null ? 'Animal added.' : 'Animal updated.');
    } catch (error) {
      _showMessage('Failed to save animal: $error');
    }
  }

  Future<void> _deletePet(Pet pet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove animal?'),
        content: Text('Remove ${pet.name} from the list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await context.read<DashboardProvider>().removePet(pet.id);
      _showMessage('Animal removed.');
    } catch (error) {
      _showMessage('Failed to remove animal: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PetFormData {
  const _PetFormData({
    required this.name,
    required this.species,
    required this.breed,
    required this.age,
    required this.gender,
    required this.status,
    this.dateAdmitted,
    this.notes,
  });

  final String name;
  final String species;
  final String breed;
  final String age;
  final String gender;
  final String status;
  final String? dateAdmitted;
  final String? notes;
}

class _PetDialog extends StatefulWidget {
  const _PetDialog({this.existing});

  final Pet? existing;

  @override
  State<_PetDialog> createState() => _PetDialogState();
}

class _PetDialogState extends State<_PetDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _speciesController;
  late final TextEditingController _breedController;
  late final TextEditingController _ageController;
  late final TextEditingController _dateController;
  late final TextEditingController _notesController;

  late String _gender;
  late String _status;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _speciesController = TextEditingController(text: existing?.species ?? '');
    _breedController = TextEditingController(text: existing?.breed ?? '');
    _ageController = TextEditingController(text: existing?.age ?? '');
    _dateController = TextEditingController(text: existing?.dateAdmitted ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _gender = existing?.gender.isNotEmpty == true ? existing!.gender : 'Male';
    _status = existing?.status.isNotEmpty == true ? existing!.status : 'Available';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Animal' : 'Edit Animal'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Required';
                  if (text.length < 2) return 'Name must be at least 2 characters';
                  return null;
                },
              ),
              TextFormField(
                controller: _speciesController,
                decoration: const InputDecoration(labelText: 'Species'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(labelText: 'Breed'),
              ),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                ],
                onChanged: (value) => setState(() => _gender = value ?? 'Male'),
                decoration: const InputDecoration(labelText: 'Gender'),
              ),
              DropdownButtonFormField<String>(
                initialValue: _status,
                items: const [
                  DropdownMenuItem(value: 'Available', child: Text('Available')),
                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'Adopted', child: Text('Adopted')),
                ],
                onChanged: (value) => setState(() => _status = value ?? 'Available'),
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Date Admitted (YYYY-MM-DD)',
                  suffixIcon: IconButton(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                  ),
                ),
                validator: _validateIsoDate,
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
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
      _PetFormData(
        name: _nameController.text.trim(),
        species: _speciesController.text.trim(),
        breed: _breedController.text.trim(),
        age: _ageController.text.trim(),
        gender: _gender,
        status: _status,
        dateAdmitted: _dateController.text.trim().isEmpty ? null : _dateController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
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
