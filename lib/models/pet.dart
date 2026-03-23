class Pet {
  Pet({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.age,
    required this.gender,
    required this.status,
    this.dateAdmitted,
    this.notes,
  });

  final String id;
  final String name;
  final String species;
  final String breed;
  final String age;
  final String gender;
  final String status;
  final String? dateAdmitted;
  final String? notes;

  factory Pet.fromMap(String id, Map<String, dynamic> map) {
    return Pet(
      id: id,
      name: (map['name'] ?? '').toString(),
      species: (map['species'] ?? '').toString(),
      breed: (map['breed'] ?? '').toString(),
      age: (map['age'] ?? '').toString(),
      gender: (map['gender'] ?? '').toString(),
      status: (map['status'] ?? 'Available').toString(),
      dateAdmitted: map['dateAdmitted']?.toString(),
      notes: map['notes']?.toString(),
    );
  }
}
