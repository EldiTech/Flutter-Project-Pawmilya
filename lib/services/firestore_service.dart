import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/adoption_application.dart';
import '../models/employee.dart';
import '../models/pet.dart';
import '../models/shelter_profile.dart';
import '../models/shelter_zone.dart';

class FirestoreService {
  FirestoreService(this._firestore);

  final FirebaseFirestore _firestore;

  String? get _ownerUid => FirebaseAuth.instance.currentUser?.uid;

  Stream<ShelterProfile?> watchShelterProfile() {
    final user = FirebaseAuth.instance.currentUser;
    final ownerUid = user?.uid;
    final fallbackEmail = user?.email ?? '';

    if (ownerUid == null) return Stream.value(null);

    return _firestore
        .collection('shelter_users')
        .doc(ownerUid)
        .snapshots()
        .asyncMap((doc) async {
          if (doc.exists) {
            return ShelterProfile.fromMap(
              doc.data() ?? <String, dynamic>{},
              fallbackEmail: fallbackEmail,
            );
          }

          final recovered = await _resolveProfileFromFallbacks(
            ownerUid: ownerUid,
            fallbackEmail: fallbackEmail,
          );

          return recovered ?? ShelterProfile.empty(fallbackEmail: fallbackEmail);
        });
  }

  Future<ShelterProfile?> _resolveProfileFromFallbacks({
    required String ownerUid,
    required String fallbackEmail,
  }) async {
    final collection = _firestore.collection('shelter_users');

    QueryDocumentSnapshot<Map<String, dynamic>>? match;

    final byUid = await collection.where('uid', isEqualTo: ownerUid).limit(1).get();
    if (byUid.docs.isNotEmpty) {
      match = byUid.docs.first;
    }

    if (match == null && fallbackEmail.trim().isNotEmpty) {
      final byEmail = await collection.where('email', isEqualTo: fallbackEmail.trim()).limit(1).get();
      if (byEmail.docs.isNotEmpty) {
        match = byEmail.docs.first;
      }
    }

    if (match == null) {
      return null;
    }

    final data = match.data();
    await _syncRecoveredProfileToOwnerDoc(
      ownerUid: ownerUid,
      fallbackEmail: fallbackEmail,
      data: data,
    );

    return ShelterProfile.fromMap(
      data,
      fallbackEmail: fallbackEmail,
    );
  }

  Future<void> _syncRecoveredProfileToOwnerDoc({
    required String ownerUid,
    required String fallbackEmail,
    required Map<String, dynamic> data,
  }) async {
    final normalizedEmail = ((data['email'] ?? '').toString().trim().isNotEmpty)
        ? data['email']
        : fallbackEmail;

    await _firestore.collection('shelter_users').doc(ownerUid).set({
      ...data,
      'uid': ownerUid,
      'email': normalizedEmail,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<Pet>> watchPets() {
    final ownerUid = _ownerUid;
    if (ownerUid == null) return Stream.value([]);

    return _firestore
        .collection('pets')
        .where('shelterUid', isEqualTo: ownerUid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Pet.fromMap(doc.id, doc.data())).toList());
  }

  Stream<List<AdoptionApplication>> watchApplications() {
    final ownerUid = _ownerUid;
    if (ownerUid == null) return Stream.value([]);

    return _firestore
        .collection('bookings')
        .where('shelterUid', isEqualTo: ownerUid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AdoptionApplication.fromMap(doc.id, doc.data())).toList());
  }

  Stream<List<Employee>> watchEmployees() {
    final ownerUid = _ownerUid;
    if (ownerUid == null) return Stream.value([]);

    return _firestore
        .collection('employees')
        .where('shelterUid', isEqualTo: ownerUid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Employee.fromMap(doc.id, doc.data())).toList());
  }

  Stream<List<ShelterZone>> watchZones() {
    final ownerUid = _ownerUid;
    if (ownerUid == null) return Stream.value([]);

    return _firestore
        .collection('shelter_zones')
        .where('shelterUid', isEqualTo: ownerUid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ShelterZone.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> createPet({
    required String name,
    required String species,
    required String breed,
    required String age,
    required String gender,
    required String status,
    String? dateAdmitted,
    String? notes,
  }) async {
    final ownerUid = _requireOwnerUid();
    await _firestore.collection('pets').add(
      _withAuditFields(
        ownerUid,
        _cleanMap({
          'name': name,
          'species': species,
          'breed': breed,
          'age': age,
          'gender': gender,
          'status': status,
          'dateAdmitted': dateAdmitted,
          'notes': notes,
        }),
      ),
    );
  }

  Future<void> updatePet(
    String id, {
    required String name,
    required String species,
    required String breed,
    required String age,
    required String gender,
    required String status,
    String? dateAdmitted,
    String? notes,
  }) async {
    final ownerUid = _requireOwnerUid();
    await _firestore.collection('pets').doc(id).set(
      _withUpdatedAt(
        ownerUid,
        _cleanMap({
          'name': name,
          'species': species,
          'breed': breed,
          'age': age,
          'gender': gender,
          'status': status,
          'dateAdmitted': dateAdmitted,
          'notes': notes,
        }),
      ),
      SetOptions(merge: true),
    );
  }

  Future<void> deletePet(String id) async {
    await _firestore.collection('pets').doc(id).delete();
  }

  Future<void> createApplication({
    required String applicant,
    required String animal,
    required String status,
    String? date,
  }) async {
    final ownerUid = _requireOwnerUid();
    await _firestore.collection('bookings').add(
      _withAuditFields(
        ownerUid,
        _cleanMap({
          'applicant': applicant,
          'animal': animal,
          'status': status,
          'date': date,
        }),
      ),
    );
  }

  Future<void> updateApplication(
    String id, {
    required String applicant,
    required String animal,
    required String status,
    String? date,
  }) async {
    final ownerUid = _requireOwnerUid();
    await _firestore.collection('bookings').doc(id).set(
      _withUpdatedAt(
        ownerUid,
        _cleanMap({
          'applicant': applicant,
          'animal': animal,
          'status': status,
          'date': date,
        }),
      ),
      SetOptions(merge: true),
    );
  }

  Future<void> updateApplicationStatus(String id, String status) async {
    final ownerUid = _requireOwnerUid();
    await _firestore.collection('bookings').doc(id).set(
      _withUpdatedAt(ownerUid, {'status': status}),
      SetOptions(merge: true),
    );
  }

  Future<void> deleteApplication(String id) async {
    await _firestore.collection('bookings').doc(id).delete();
  }

  Future<void> createEmployee({
    required String name,
    required String role,
    required String status,
    String? dept,
    String? email,
    String? phone,
    String? dateHired,
  }) async {
    final ownerUid = _requireOwnerUid();
    await _firestore.collection('employees').add(
      _withAuditFields(
        ownerUid,
        _cleanMap({
          'name': name,
          'role': role,
          'status': status,
          'dept': dept,
          'email': email,
          'phone': phone,
          'dateHired': dateHired,
        }),
      ),
    );
  }

  Future<void> updateEmployee(
    String id, {
    required String name,
    required String role,
    required String status,
    String? dept,
    String? email,
    String? phone,
    String? dateHired,
  }) async {
    final ownerUid = _requireOwnerUid();
    await _firestore.collection('employees').doc(id).set(
      _withUpdatedAt(
        ownerUid,
        _cleanMap({
          'name': name,
          'role': role,
          'status': status,
          'dept': dept,
          'email': email,
          'phone': phone,
          'dateHired': dateHired,
        }),
      ),
      SetOptions(merge: true),
    );
  }

  Future<void> deleteEmployee(String id) async {
    await _firestore.collection('employees').doc(id).delete();
  }

  Future<void> createZone({
    required String name,
    required int humidity,
    required String humidityStatus,
    required int temp,
    required String tempStatus,
  }) async {
    final ownerUid = _requireOwnerUid();
    await _firestore.collection('shelter_zones').add(
      _withAuditFields(
        ownerUid,
        {
          'name': name,
          'humidity': humidity,
          'humidityStatus': humidityStatus,
          'temp': temp,
          'tempStatus': tempStatus,
        },
      ),
    );
  }

  Future<void> updateZone(
    String id, {
    required String name,
    required int humidity,
    required String humidityStatus,
    required int temp,
    required String tempStatus,
  }) async {
    final ownerUid = _requireOwnerUid();
    await _firestore.collection('shelter_zones').doc(id).set(
      _withUpdatedAt(
        ownerUid,
        {
          'name': name,
          'humidity': humidity,
          'humidityStatus': humidityStatus,
          'temp': temp,
          'tempStatus': tempStatus,
        },
      ),
      SetOptions(merge: true),
    );
  }

  Future<void> deleteZone(String id) async {
    await _firestore.collection('shelter_zones').doc(id).delete();
  }

  String _requireOwnerUid() {
    final ownerUid = _ownerUid;
    if (ownerUid == null || ownerUid.trim().isEmpty) {
      throw StateError('Authentication required. Please login again.');
    }
    return ownerUid;
  }

  Map<String, dynamic> _withAuditFields(String ownerUid, Map<String, dynamic> fields) {
    return {
      ...fields,
      'shelterUid': ownerUid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _withUpdatedAt(String ownerUid, Map<String, dynamic> fields) {
    return {
      ...fields,
      'shelterUid': ownerUid,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _cleanMap(Map<String, dynamic> source) {
    final cleaned = <String, dynamic>{};
    source.forEach((key, value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      cleaned[key] = value;
    });
    return cleaned;
  }
}
