import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/employee.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() => _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
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
          'Employee Management',
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
        onPressed: () => _openEmployeeDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 10,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add),
        label: Text(
          'Add Employee',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          final query = _searchController.text.trim().toLowerCase();
          final employees = provider.employees.where((item) {
            if (query.isEmpty) return true;
            return item.name.toLowerCase().contains(query) ||
                item.role.toLowerCase().contains(query) ||
                (item.dept ?? '').toLowerCase().contains(query);
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
                    hintText: 'Search employees',
                    hintStyle: GoogleFonts.quicksand(
                      color: AppColors.textMuted,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: AppColors.warmAccent.withValues(alpha: 0.72)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: AppColors.warmAccent.withValues(alpha: 0.72)),
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
                child: employees.isEmpty
                    ? Center(
                        child: Text(
                          'No employees found.',
                          style: GoogleFonts.quicksand(
                            color: AppColors.textMuted,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: employees.length,
                        itemBuilder: (context, index) {
                          final employee = employees[index];
                          final subtitleDepartment = employee.dept?.isNotEmpty == true
                              ? employee.dept!
                              : 'No department';
                          final subtitleEmail = employee.email?.isNotEmpty == true
                              ? employee.email!
                              : 'No email';

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
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _EmployeeAvatar(name: employee.name),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              employee.name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.quicksand(
                                                color: AppColors.textDark,
                                                fontSize: 38,
                                                fontWeight: FontWeight.w700,
                                                height: 0.98,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _EmployeeStatusBadge(status: employee.status),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        employee.role,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.quicksand(
                                          color: AppColors.textMuted,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '• $subtitleDepartment',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.quicksand(
                                          color: AppColors.textMid,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        subtitleEmail,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.quicksand(
                                          color: AppColors.textMid,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: AppColors.warmBg,
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: AppColors.warmAccent.withValues(alpha: 0.78),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _EmployeeActionButton(
                                                icon: Icons.edit_outlined,
                                                onTap: () => _openEmployeeDialog(existing: employee),
                                              ),
                                              _EmployeeActionButton(
                                                icon: Icons.delete_outline,
                                                onTap: () => _deleteEmployee(employee),
                                              ),
                                            ],
                                          ),
                                        ),
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

  Future<void> _openEmployeeDialog({Employee? existing}) async {
    final result = await showDialog<_EmployeeFormData>(
      context: context,
      builder: (_) => _EmployeeDialog(existing: existing),
    );

    if (result == null || !mounted) return;

    try {
      if (existing == null) {
        await context.read<DashboardProvider>().addEmployee(
              name: result.name,
              role: result.role,
              status: result.status,
              dept: result.dept,
              email: result.email,
              phone: result.phone,
              dateHired: result.dateHired,
            );
      } else {
        await context.read<DashboardProvider>().editEmployee(
              existing.id,
              name: result.name,
              role: result.role,
              status: result.status,
              dept: result.dept,
              email: result.email,
              phone: result.phone,
              dateHired: result.dateHired,
            );
      }
      _showMessage(existing == null ? 'Employee added.' : 'Employee updated.');
    } catch (error) {
      _showMessage('Failed to save employee: $error');
    }
  }

  Future<void> _deleteEmployee(Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove employee?'),
        content: Text('Remove ${employee.name} from the list?'),
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
      await context.read<DashboardProvider>().removeEmployee(employee.id);
      _showMessage('Employee removed.');
    } catch (error) {
      _showMessage('Failed to remove employee: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _EmployeeAvatar extends StatelessWidget {
  const _EmployeeAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.warmAccent.withValues(alpha: 0.92), width: 1.4),
      ),
      child: CircleAvatar(
        radius: 31,
        backgroundColor: AppColors.warmAccent.withValues(alpha: 0.43),
        child: Text(
          initial,
          style: GoogleFonts.quicksand(
            color: AppColors.textDark,
            fontSize: 30,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _EmployeeStatusBadge extends StatelessWidget {
  const _EmployeeStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive = status.toLowerCase() == 'active';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? AppColors.adoptionGreen.withValues(alpha: 0.14) : AppColors.warmBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppColors.adoptionGreen.withValues(alpha: 0.4)
              : AppColors.warmAccent.withValues(alpha: 0.85),
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.adoptionGreen.withValues(alpha: 0.24),
                  blurRadius: 10,
                  spreadRadius: -1,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        status,
        style: GoogleFonts.quicksand(
          color: isActive ? AppColors.adoptionGreen.withValues(alpha: 0.95) : AppColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmployeeActionButton extends StatelessWidget {
  const _EmployeeActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Icon(icon, size: 22, color: AppColors.textDark),
      ),
    );
  }
}

class _EmployeeFormData {
  const _EmployeeFormData({
    required this.name,
    required this.role,
    required this.status,
    this.dept,
    this.email,
    this.phone,
    this.dateHired,
  });

  final String name;
  final String role;
  final String status;
  final String? dept;
  final String? email;
  final String? phone;
  final String? dateHired;
}

class _EmployeeDialog extends StatefulWidget {
  const _EmployeeDialog({this.existing});

  final Employee? existing;

  @override
  State<_EmployeeDialog> createState() => _EmployeeDialogState();
}

class _EmployeeDialogState extends State<_EmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  static const List<String> _roleOptions = [
    'Veterinarian',
    'Caretaker',
    'Volunteer',
    'Admin Staff',
    'Manager',
  ];
  static const List<String> _departmentOptions = [
    'Administration',
    'Medical',
    'Operations',
    'Adoption',
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _dateController;

  late String _status;
  String? _selectedRole;
  String? _selectedDepartment;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _emailController = TextEditingController(text: existing?.email ?? '');
    _phoneController = TextEditingController(text: existing?.phone ?? '');
    _dateController = TextEditingController(text: existing?.dateHired ?? '');
    _status = existing?.status ?? 'Active';
    _selectedRole = existing?.role;
    _selectedDepartment = existing?.dept;

    if (_selectedRole != null && !_roleOptions.contains(_selectedRole)) {
      _selectedRole = null;
    }
    if (_selectedDepartment != null && !_departmentOptions.contains(_selectedDepartment)) {
      _selectedDepartment = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Employee' : 'Edit Employee'),
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
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                hint: const Text('Select role'),
                items: _roleOptions
                    .map(
                      (role) => DropdownMenuItem<String>(
                        value: role,
                        child: Text(role),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedRole = value),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              DropdownButtonFormField<String>(
                initialValue: _selectedDepartment,
                decoration: const InputDecoration(labelText: 'Department'),
                hint: const Text('Select department'),
                items: _departmentOptions
                    .map(
                      (department) => DropdownMenuItem<String>(
                        value: department,
                        child: Text(department),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedDepartment = value),
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return null;
                  const emailPattern = r'^[^\s@]+@[^\s@]+\.[^\s@]+$';
                  if (!RegExp(emailPattern).hasMatch(text)) return 'Enter a valid email';
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return null;
                  final digits = text.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 7) return 'Enter a valid phone number';
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: _status,
                items: const [
                  DropdownMenuItem(value: 'Active', child: Text('Active')),
                  DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                ],
                onChanged: (value) => setState(() => _status = value ?? 'Active'),
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Date Hired (YYYY-MM-DD)',
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

    Navigator.pop(
      context,
      _EmployeeFormData(
        name: _nameController.text.trim(),
        role: _selectedRole!.trim(),
        status: _status,
        dept: _selectedDepartment,
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        dateHired: _dateController.text.trim().isEmpty ? null : _dateController.text.trim(),
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
