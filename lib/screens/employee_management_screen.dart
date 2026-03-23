import 'package:flutter/material.dart';
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
        title: const Text('Employee Management'),
        backgroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEmployeeDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Employee'),
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search employees',
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
                child: employees.isEmpty
                    ? const Center(child: Text('No employees found.'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                        itemCount: employees.length,
                        itemBuilder: (context, index) {
                          final employee = employees[index];
                          return Card(
                            color: Colors.white,
                            child: ListTile(
                              title: Text(employee.name),
                              subtitle: Text(
                                '${employee.role} • ${employee.dept ?? 'No department'}\n${employee.email ?? 'No email'}',
                              ),
                              isThreeLine: true,
                              trailing: Wrap(
                                spacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Chip(
                                    label: Text(employee.status),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  IconButton(
                                    onPressed: () => _openEmployeeDialog(existing: employee),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteEmployee(employee),
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

  late final TextEditingController _nameController;
  late final TextEditingController _roleController;
  late final TextEditingController _deptController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _dateController;

  late String _status;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _roleController = TextEditingController(text: existing?.role ?? '');
    _deptController = TextEditingController(text: existing?.dept ?? '');
    _emailController = TextEditingController(text: existing?.email ?? '');
    _phoneController = TextEditingController(text: existing?.phone ?? '');
    _dateController = TextEditingController(text: existing?.dateHired ?? '');
    _status = existing?.status ?? 'Active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _deptController.dispose();
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
              TextFormField(
                controller: _roleController,
                decoration: const InputDecoration(labelText: 'Role'),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Required';
                  if (text.length < 2) return 'Role must be at least 2 characters';
                  return null;
                },
              ),
              TextFormField(
                controller: _deptController,
                decoration: const InputDecoration(labelText: 'Department'),
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
        role: _roleController.text.trim(),
        status: _status,
        dept: _deptController.text.trim().isEmpty ? null : _deptController.text.trim(),
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
