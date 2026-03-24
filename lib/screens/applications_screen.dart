import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  OverlayEntry? _toastEntry;
  Timer? _toastTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _toastTimer?.cancel();
    _toastEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmBg,
      appBar: AppBar(
        title: Text(
          'Applications',
          style: GoogleFonts.quicksand(
            color: AppColors.textDark,
            fontSize: 26,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openApplicationDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 10,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add),
        label: Text(
          'Add Application',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.w700, fontSize: 17),
        ),
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textMid.withValues(alpha: 0.9),
                    ),
                    hintText: 'Search applications',
                    hintStyle: GoogleFonts.quicksand(
                      color: AppColors.textMuted,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: AppColors.warmAccent.withValues(alpha: 0.7)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: AppColors.warmAccent.withValues(alpha: 0.7)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.42), width: 1.2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Expanded(
                child: applications.isEmpty
                    ? Center(
                        child: Text(
                          'No applications found.',
                          style: GoogleFonts.quicksand(
                            color: AppColors.textMuted,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: applications.length,
                        itemBuilder: (context, index) {
                          final app = applications[index];
                          final dateLabel = app.date?.isNotEmpty == true ? app.date! : 'No date';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: AppColors.warmAccent.withValues(alpha: 0.58)),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.textDark.withValues(alpha: 0.07),
                                  blurRadius: 18,
                                  offset: const Offset(0, 9),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Applicant Name',
                                            style: GoogleFonts.quicksand(
                                              color: AppColors.textMuted,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.45,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            app.applicant,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.quicksand(
                                              color: AppColors.textDark,
                                              fontSize: 31,
                                              fontWeight: FontWeight.w600,
                                              height: 1,
                                            ),
                                          ),
                                          const SizedBox(height: 9),
                                          Text(
                                            'Pet Name',
                                            style: GoogleFonts.quicksand(
                                              color: AppColors.textMuted,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.45,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${app.animal} • $dateLabel',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.quicksand(
                                              color: AppColors.textMid,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    _ApplicationStatusBadge(status: app.status),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: _QuickActionsTray(
                                    onApprove: app.status == 'Pending'
                                        ? () => _changeStatus(app.id, 'Approved')
                                        : null,
                                    onReject: app.status == 'Pending'
                                        ? () => _changeStatus(app.id, 'Rejected')
                                        : null,
                                    onEdit: () => _openApplicationDialog(existing: app),
                                    onDelete: () => _deleteApplication(app),
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
    final isSuccess = !message.toLowerCase().startsWith('failed');

    _toastTimer?.cancel();
    _toastEntry?.remove();

    final overlay = Overlay.of(context);
    if (overlay.mounted == false) return;

    _toastEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: 16,
          right: 16,
          bottom: 30,
          child: SafeArea(
            child: _FrostedStatusToast(
              message: message,
              isSuccess: isSuccess,
            ),
          ),
        );
      },
    );

    overlay.insert(_toastEntry!);
    _toastTimer = Timer(const Duration(seconds: 3), () {
      _toastEntry?.remove();
      _toastEntry = null;
    });
  }
}

class _ApplicationStatusBadge extends StatelessWidget {
  const _ApplicationStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    final Color textColor;
    final Color fillColor;
    final Color borderColor;

    if (normalized == 'approved') {
      textColor = AppColors.adoptionGreen.withValues(alpha: 0.95);
      fillColor = AppColors.adoptionGreen.withValues(alpha: 0.12);
      borderColor = AppColors.adoptionGreen.withValues(alpha: 0.35);
    } else if (normalized == 'pending') {
      textColor = AppColors.textMid;
      fillColor = AppColors.warmAccent.withValues(alpha: 0.34);
      borderColor = AppColors.primary.withValues(alpha: 0.28);
    } else {
      textColor = AppColors.textMuted;
      fillColor = AppColors.warmBg;
      borderColor = AppColors.warmAccent.withValues(alpha: 0.9);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        status,
        style: GoogleFonts.quicksand(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QuickActionsTray extends StatelessWidget {
  const _QuickActionsTray({
    required this.onEdit,
    required this.onDelete,
    this.onApprove,
    this.onReject,
  });

  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warmBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warmAccent.withValues(alpha: 0.75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onApprove != null)
            _TrayActionButton(
              icon: Icons.check_circle_outline,
              tooltip: 'Approve',
              onTap: onApprove!,
            ),
          if (onReject != null)
            _TrayActionButton(
              icon: Icons.cancel_outlined,
              tooltip: 'Reject',
              onTap: onReject!,
            ),
          _TrayActionButton(
            icon: Icons.edit_outlined,
            tooltip: 'Edit',
            onTap: onEdit,
          ),
          _TrayActionButton(
            icon: Icons.delete_outline,
            tooltip: 'Delete',
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _TrayActionButton extends StatelessWidget {
  const _TrayActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(icon, size: 22, color: AppColors.textDark),
        ),
      ),
    );
  }
}

class _FrostedStatusToast extends StatelessWidget {
  const _FrostedStatusToast({required this.message, required this.isSuccess});

  final String message;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final iconColor = isSuccess
      ? AppColors.adoptionGreen.withValues(alpha: 0.95)
      : AppColors.primaryDark.withValues(alpha: 0.95);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 13, sigmaY: 13),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.warmAccent.withValues(alpha: 0.78)),
            boxShadow: [
              BoxShadow(
                color: AppColors.textDark.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                color: iconColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.quicksand(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
