import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        title: Text(
          'Animal Management',
          style: GoogleFonts.quicksand(
            color: AppColors.textDark,
            fontSize: 26,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPetDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 10,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add),
        label: Text(
          'Add Animal',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.w700, fontSize: 17),
        ),
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textMid.withValues(alpha: 0.9),
                    ),
                    hintText: 'Search animals',
                    hintStyle: GoogleFonts.quicksand(
                      color: AppColors.textMuted,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: AppColors.warmAccent.withValues(alpha: 0.75)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: AppColors.warmAccent.withValues(alpha: 0.75)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.45), width: 1.2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Expanded(
                child: pets.isEmpty
                    ? Center(
                        child: Text(
                          'No animals found.',
                          style: GoogleFonts.quicksand(
                            color: AppColors.textMuted,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 104),
                        itemCount: pets.length,
                        itemBuilder: (context, index) {
                          final pet = pets[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: AppColors.warmAccent.withValues(alpha: 0.6)),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.textDark.withValues(alpha: 0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _PetPortrait(name: pet.name),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pet.name,
                                        style: GoogleFonts.quicksand(
                                          color: AppColors.textDark,
                                          fontSize: 26,
                                          fontWeight: FontWeight.w600,
                                          height: 1.05,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${pet.species} • ${pet.breed}',
                                        style: GoogleFonts.quicksand(
                                          color: AppColors.textDark,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${pet.gender} • ${pet.age}',
                                        style: GoogleFonts.quicksand(
                                          color: AppColors.textMuted,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          _StatusPill(status: pet.status),
                                          const Spacer(),
                                          _ActionIcon(
                                            icon: Icons.edit_outlined,
                                            onTap: () => _openPetDialog(existing: pet),
                                          ),
                                          const SizedBox(width: 8),
                                          _ActionIcon(
                                            icon: Icons.delete_outline,
                                            onTap: () => _deletePet(pet),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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

class _PetPortrait extends StatelessWidget {
  const _PetPortrait({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.warmAccent.withValues(alpha: 0.9), width: 1.3),
      ),
      child: CircleAvatar(
        radius: 38,
        backgroundColor: AppColors.warmAccent.withValues(alpha: 0.45),
        child: Text(
          initial,
          style: GoogleFonts.quicksand(
            color: AppColors.textDark,
            fontSize: 33,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warmBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
      ),
      child: Text(
        status,
        style: GoogleFonts.quicksand(
          color: AppColors.textDark,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.warmBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.textDark, size: 21),
      ),
    );
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
