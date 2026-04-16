import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum ShelterAccessStatus { allowed, denied, unavailable }

class ShelterAccessResult {
  const ShelterAccessResult._({required this.status, required this.message});

  factory ShelterAccessResult.allowed() {
    return const ShelterAccessResult._(
      status: ShelterAccessStatus.allowed,
      message: '',
    );
  }

  factory ShelterAccessResult.denied() {
    return const ShelterAccessResult._(
      status: ShelterAccessStatus.denied,
      message:
          'This account is not registered as a shelter/admin. Please contact support.',
    );
  }

  factory ShelterAccessResult.unavailable() {
    return const ShelterAccessResult._(
      status: ShelterAccessStatus.unavailable,
      message:
          'Unable to verify shelter access right now. Please try again in a moment.',
    );
  }

  final ShelterAccessStatus status;
  final String message;

  bool get isAllowed => status == ShelterAccessStatus.allowed;
}

class RoleAccessService {
  RoleAccessService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static final RoleAccessService instance = RoleAccessService();

  static const Set<String> _shelterRoles = {
    'admin',
    'shelter',
    'shelter_admin',
    'shelter-admin',
    'shelteradmin',
    'shelter_manager',
    'sheltermanager',
    'staff',
  };

  Future<ShelterAccessResult> checkShelterAccess({required User user}) async {
    var hadReadError = false;

    Future<bool> safe(Future<bool> Function() runCheck) async {
      try {
        return await runCheck();
      } on FirebaseException {
        hadReadError = true;
        return false;
      }
    }

    final uid = user.uid;
    final email = (user.email ?? '').trim().toLowerCase();

    if (await safe(() => _userDocHasShelterRole(uid))) {
      return ShelterAccessResult.allowed();
    }

    if (await safe(() => _shelterDocExists(uid))) {
      return ShelterAccessResult.allowed();
    }

    if (await safe(() => _shelterWithAdminUidExists(uid))) {
      return ShelterAccessResult.allowed();
    }

    if (email.isNotEmpty) {
      if (await safe(() => _shelterWithEmailExists(email))) {
        return ShelterAccessResult.allowed();
      }

      if (await safe(() => _userByEmailHasShelterRole(email))) {
        return ShelterAccessResult.allowed();
      }
    }

    if (hadReadError) {
      return ShelterAccessResult.unavailable();
    }

    return ShelterAccessResult.denied();
  }

  Future<bool> _userDocHasShelterRole(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    final data = snapshot.data();
    if (data == null) {
      return false;
    }
    return _hasShelterRoleFromData(data);
  }

  Future<bool> _shelterDocExists(String uid) async {
    final snapshot = await _firestore.collection('shelters').doc(uid).get();
    return snapshot.exists;
  }

  Future<bool> _shelterWithAdminUidExists(String uid) async {
    final query = await _firestore
        .collection('shelters')
        .where('adminUid', isEqualTo: uid)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<bool> _shelterWithEmailExists(String email) async {
    final adminEmailMatch = await _firestore
        .collection('shelters')
        .where('adminEmail', isEqualTo: email)
        .limit(1)
        .get();

    if (adminEmailMatch.docs.isNotEmpty) {
      return true;
    }

    final shelterEmailMatch = await _firestore
        .collection('shelters')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return shelterEmailMatch.docs.isNotEmpty;
  }

  Future<bool> _userByEmailHasShelterRole(String email) async {
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return false;
    }

    return _hasShelterRoleFromData(query.docs.first.data());
  }

  bool _hasShelterRoleFromData(Map<String, dynamic> data) {
    if (_boolField(data, 'isShelter') ||
        _boolField(data, 'isAdmin') ||
        _boolField(data, 'isShelterAdmin')) {
      return true;
    }

    return _containsShelterRole(data['role']) ||
        _containsShelterRole(data['roles']) ||
        _containsShelterRole(data['accountType']) ||
        _containsShelterRole(data['type']);
  }

  bool _boolField(Map<String, dynamic> data, String key) {
    return data[key] == true;
  }

  bool _containsShelterRole(dynamic roleValue) {
    if (roleValue is String) {
      return _shelterRoles.contains(roleValue.trim().toLowerCase());
    }

    if (roleValue is Iterable) {
      return roleValue.any((item) {
        return item is String &&
            _shelterRoles.contains(item.trim().toLowerCase());
      });
    }

    return false;
  }
}
