class Employee {
  Employee({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    this.dept,
    this.email,
    this.phone,
    this.dateHired,
  });

  final String id;
  final String name;
  final String role;
  final String status;
  final String? dept;
  final String? email;
  final String? phone;
  final String? dateHired;

  factory Employee.fromMap(String id, Map<String, dynamic> map) {
    return Employee(
      id: id,
      name: (map['name'] ?? '').toString(),
      role: (map['role'] ?? '').toString(),
      status: (map['status'] ?? 'Active').toString(),
      dept: map['dept']?.toString(),
      email: map['email']?.toString(),
      phone: map['phone']?.toString(),
      dateHired: map['dateHired']?.toString(),
    );
  }
}
