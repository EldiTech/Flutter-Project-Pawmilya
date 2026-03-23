class AdoptionApplication {
  AdoptionApplication({
    required this.id,
    required this.applicant,
    required this.animal,
    required this.status,
    this.date,
  });

  final String id;
  final String applicant;
  final String animal;
  final String status;
  final String? date;

  factory AdoptionApplication.fromMap(String id, Map<String, dynamic> map) {
    return AdoptionApplication(
      id: id,
      applicant: (map['applicant'] ?? '').toString(),
      animal: (map['animal'] ?? '').toString(),
      status: (map['status'] ?? 'Pending').toString(),
      date: map['date']?.toString(),
    );
  }
}
