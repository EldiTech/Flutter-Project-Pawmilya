import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/pawmilya_palette.dart';

class Employee {
  final String id;
  String name;
  String role;
  String email;
  String phone;
  double salary;
  bool isActive;
  String? imageUrl;
  String? shelterId;

  Employee({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.phone,
    this.salary = 0.0,
    this.isActive = true,
    this.imageUrl,
    this.shelterId,
  });

  factory Employee.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Employee(
      id: doc.id,
      name: data['name'] ?? '',
      role: data['role'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      salary: (data['salary'] ?? 0.0).toDouble(),
      isActive: data['isActive'] ?? true,
      imageUrl: data['imageUrl'],
      shelterId: data['shelterId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'email': email,
      'phone': phone,
      'salary': salary,
      'isActive': isActive,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (shelterId != null) 'shelterId': shelterId,
    };
  }
}

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  final CollectionReference _employeesCollection =
      FirebaseFirestore.instance.collection('employees');

  String _searchQuery = '';
  String _selectedRoleFilter = 'All';

  final List<String> _availableRoles = [
    'Veterinarian',
    'Rescuer',
    'Admin',
    'Volunteer Coordinator',
    'Caretaker',
  ];

  List<Employee> _getFilteredEmployees(List<Employee> allEmployees) {
    return allEmployees.where((emp) {
      final matchesSearch =
          emp.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              emp.role.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesRole =
          _selectedRoleFilter == 'All' || emp.role == _selectedRoleFilter;
      return matchesSearch && matchesRole;
    }).toList();
  }

  void _showAddEditModal({Employee? employee}) {
    final isEditing = employee != null;
    final nameController = TextEditingController(text: employee?.name ?? '');
    final emailController = TextEditingController(text: employee?.email ?? '');
    final phoneController = TextEditingController(text: employee?.phone ?? '');
    final salaryController = TextEditingController(text: employee?.salary.toString() ?? '');
    String selectedRole = employee?.role ?? _availableRoles.first;
    bool isActive = employee?.isActive ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PawmilyaPalette.creamTop,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit Employee' : 'Add Employee',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: PawmilyaPalette.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: PawmilyaPalette.textSecondary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            TextField(
                              controller: nameController,
                              decoration: _inputDecoration('Full Name', Icons.person),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: emailController,
                              decoration: _inputDecoration('Email Address', Icons.email),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: phoneController,
                              decoration: _inputDecoration('Phone Number', Icons.phone),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: salaryController,
                              decoration: _inputDecoration('Base Salary/Wage', Icons.attach_money),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: selectedRole,
                              decoration: _inputDecoration('Role', Icons.work),
                              dropdownColor: PawmilyaPalette.creamMid,
                              items: _availableRoles.map((role) {
                                return DropdownMenuItem(
                                  value: role,
                                  child: Text(role, style: const TextStyle(color: PawmilyaPalette.textPrimary)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setModalState(() {
                                  if (value != null) selectedRole = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              title: const Text(
                                'Active Status',
                                style: TextStyle(color: PawmilyaPalette.textPrimary, fontWeight: FontWeight.w600),
                              ),
                              value: isActive,
                              activeThumbColor: PawmilyaPalette.gold,
                              onChanged: (val) {
                                setModalState(() => isActive = val);
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: PawmilyaPalette.shelterGold,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () async {
                                  if (nameController.text.trim().isEmpty) return;

                                  final employeeData = Employee(
                                    id: employee?.id ?? '', // Not used for mapping
                                    name: nameController.text.trim(),
                                    email: emailController.text.trim(),
                                    phone: phoneController.text.trim(),
                                    salary: double.tryParse(salaryController.text.trim()) ?? 0.0,
                                    role: selectedRole,
                                    isActive: isActive,
                                    shelterId: FirebaseAuth.instance.currentUser?.uid,
                                  ).toMap();

                                  if (isEditing) {
                                    await _employeesCollection.doc(employee.id).update(employeeData);
                                  } else {
                                    await _employeesCollection.add(employeeData);
                                  }
                                  
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                                child: Text(
                                  isEditing ? 'Save Changes' : 'Add Employee',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PawmilyaPalette.creamTop,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Employee', style: TextStyle(color: PawmilyaPalette.textPrimary)),
        content: Text(
          'Are you sure you want to remove ${employee.name}?',
          style: const TextStyle(color: PawmilyaPalette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: PawmilyaPalette.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              await _employeesCollection.doc(employee.id).delete();
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${employee.name} deleted'),
                    backgroundColor: PawmilyaPalette.textPrimary,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _viewDetails(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PawmilyaPalette.creamTop,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(employee.name, style: const TextStyle(color: PawmilyaPalette.textPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.work, 'Role', employee.role),
            _buildDetailRow(Icons.email, 'Email', employee.email),
            _buildDetailRow(Icons.phone, 'Phone', employee.phone),
            _buildDetailRow(Icons.attach_money, 'Base Salary', '₱${employee.salary.toStringAsFixed(2)}'),
            _buildDetailRow(
              Icons.toggle_on,
              'Status',
              employee.isActive ? 'Active' : 'Inactive',
              color: employee.isActive ? Colors.green.shade600 : Colors.red.shade400,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: PawmilyaPalette.goldDark)),
          ),
        ],
      ),
    );
  }

  void _processPayroll(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PawmilyaPalette.creamTop,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet, color: PawmilyaPalette.goldDark),
            SizedBox(width: 8),
            Text('Process Payroll', style: TextStyle(color: PawmilyaPalette.textPrimary)),
          ],
        ),
        content: Text(
          'Would you like to process the regular payment of ₱${employee.salary.toStringAsFixed(2)} for ${employee.name}?',
          style: const TextStyle(color: PawmilyaPalette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: PawmilyaPalette.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PawmilyaPalette.shelterGold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              
              final shelterRef = FirebaseFirestore.instance.collection('shelters').doc(user.uid);
              
              try {
                await FirebaseFirestore.instance.runTransaction((transaction) async {
                  final shelterSnap = await transaction.get(shelterRef);
                  double currentBalance = 0.0;
                  
                  if (shelterSnap.exists && shelterSnap.data() != null && shelterSnap.data()!.containsKey('balance')) {
                    currentBalance = (shelterSnap.data()!['balance'] as num).toDouble();
                  }

                  if (currentBalance < employee.salary) {
                    throw Exception('Insufficient funds');
                  }

                  transaction.update(shelterRef, {'balance': currentBalance - employee.salary});
                  
                  final transactionRef = shelterRef.collection('transactions').doc();
                  transaction.set(transactionRef, {
                    'amount': employee.salary,
                    'type': 'expense',
                    'category': 'payroll',
                    'description': 'Payroll: ${employee.name}',
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payroll processed for ${employee.name}'),
                      backgroundColor: Colors.green.shade600,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().contains('Insufficient') ? 'Error: Insufficient Funds' : 'Error processing payroll'),
                      backgroundColor: Colors.red.shade400,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: PawmilyaPalette.textSecondary),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(color: PawmilyaPalette.textSecondary, fontWeight: FontWeight.w500)),
          Expanded(child: Text(value, style: TextStyle(color: color ?? PawmilyaPalette.textPrimary, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: PawmilyaPalette.textSecondary),
      prefixIcon: Icon(icon, color: PawmilyaPalette.textSecondary),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PawmilyaPalette.cardEdge),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PawmilyaPalette.cardEdge),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PawmilyaPalette.gold, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PawmilyaPalette.creamMid,
      appBar: AppBar(
        backgroundColor: PawmilyaPalette.creamTop,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: PawmilyaPalette.textPrimary),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Employee Management',
              style: TextStyle(
                color: PawmilyaPalette.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              'Manage shelter staff and roles',
              style: TextStyle(
                color: PawmilyaPalette.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              icon: const Icon(Icons.add_circle, color: PawmilyaPalette.goldDark, size: 28),
              tooltip: 'Add Employee',
              onPressed: () => _showAddEditModal(),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _employeesCollection
                  .where('shelterId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: PawmilyaPalette.shelterGold));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final allEmployees = snapshot.data!.docs
                    .map((doc) => Employee.fromFirestore(doc))
                    .where((emp) => emp.shelterId == FirebaseAuth.instance.currentUser?.uid)
                    .toList();

                final filteredEmployees = _getFilteredEmployees(allEmployees);

                if (filteredEmployees.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredEmployees.length,
                  itemBuilder: (context, index) {
                    final employee = filteredEmployees[index];
                    return _buildEmployeeCard(employee);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: PawmilyaPalette.creamTop,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search by name or role...',
              hintStyle: const TextStyle(color: PawmilyaPalette.textSecondary),
              prefixIcon: const Icon(Icons.search, color: PawmilyaPalette.textSecondary),
              filled: true,
              fillColor: PawmilyaPalette.creamMid,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                ..._availableRoles.map((role) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: _buildFilterChip(role),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedRoleFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedRoleFilter = label);
      },
      selectedColor: PawmilyaPalette.goldLight,
      backgroundColor: PawmilyaPalette.creamBottom,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : PawmilyaPalette.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: PawmilyaPalette.cardEdge, width: 1),
      ),
      elevation: 2,
      shadowColor: Colors.black12,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: PawmilyaPalette.creamBottom,
                  backgroundImage: employee.imageUrl != null ? NetworkImage(employee.imageUrl!) : null,
                  child: employee.imageUrl == null
                      ? Text(
                          employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 24, color: PawmilyaPalette.textPrimary, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: PawmilyaPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        employee.role,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: PawmilyaPalette.goldDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.email, size: 14, color: PawmilyaPalette.textSecondary.withValues(alpha: 0.8)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              employee.email,
                              style: TextStyle(fontSize: 12, color: PawmilyaPalette.textSecondary.withValues(alpha: 0.8)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: employee.isActive ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: employee.isActive ? Colors.green.shade300 : Colors.red.shade300,
                    ),
                  ),
                  child: Text(
                    employee.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: employee.isActive ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: PawmilyaPalette.creamBottom, height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => _viewDetails(employee),
                    icon: const Icon(Icons.visibility, size: 16, color: PawmilyaPalette.textSecondary),
                    label: const Text('View', style: TextStyle(fontSize: 12, color: PawmilyaPalette.textSecondary)),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => _processPayroll(employee),
                    icon: const Icon(Icons.payments_outlined, size: 16, color: Colors.green),
                    label: const Text('Pay', style: TextStyle(fontSize: 12, color: Colors.green)),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => _showAddEditModal(employee: employee),
                    icon: const Icon(Icons.edit, size: 16, color: PawmilyaPalette.goldDark),
                    label: const Text('Edit', style: TextStyle(fontSize: 12, color: PawmilyaPalette.goldDark)),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => _confirmDelete(employee),
                    icon: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade400),
                    label: Text('Delete', style: TextStyle(fontSize: 12, color: Colors.red.shade400)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: PawmilyaPalette.goldLight.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text(
            'No employees found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: PawmilyaPalette.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your filters or add a new employee.',
            style: TextStyle(color: PawmilyaPalette.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: PawmilyaPalette.shelterGold,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add Employee'),
            onPressed: () => _showAddEditModal(),
          ),
        ],
      ),
    );
  }
}
