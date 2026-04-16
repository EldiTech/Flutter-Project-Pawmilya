import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'email_service.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static final AuthService instance = AuthService();

  Future<UserCredential> signInUser({
    required String email,
    required String password,
  }) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: _normalizeEmail(email),
      password: password,
    );

    if (result.user != null) {
      final doc = await _firestore.collection('users').doc(result.user!.uid).get();
      if (doc.exists && doc.data()?['status'] == 'banned') {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'user-banned',
          message: 'Your account has been suspended by the administrator.',
        );
      }
    }
    return result;
  }

  Future<UserCredential> signInShelter({
    required String emailOrAdminId,
    required String password,
  }) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: _normalizeShelterCredential(emailOrAdminId),
      password: password,
    );

    if (result.user != null) {
      final doc = await _firestore.collection('shelters').doc(result.user!.uid).get();
      if (doc.exists) {
        final status = doc.data()?['status'];
        if (status == 'pending_verification') {
          await _auth.signOut();
          throw FirebaseAuthException(
            code: 'pending-verification',
            message: 'Your shelter account is pending verification by the administration.',
          );
        } else if (status == 'banned') {
          await _auth.signOut();
          throw FirebaseAuthException(
            code: 'shelter-banned',
            message: 'Your shelter account has been suspended by the administrator.',
          );
        }
      }
    }
    return result;
  }

  Future<UserCredential> createUserAccount({
    required String email,
    required String password,
    required String username,
    required String realName,
    required String phoneNumber,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    final trimmedUsername = username.trim();
    final trimmedRealName = realName.trim();
    final normalizedPhone = _normalizePhoneNumber(phoneNumber);

    final credential = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      await user.updateDisplayName(trimmedRealName);
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': normalizedEmail,
        'username': trimmedUsername,
        'realName': trimmedRealName,
        'phoneNumber': normalizedPhone,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return credential;
  }

  Future<void> sendPasswordReset({required String email}) {
    return _auth.sendPasswordResetEmail(email: _normalizeEmail(email));
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No authenticated user found.');
    }

    // Re-authenticate the user before changing the password
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: oldPassword,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<UserCredential> createShelterAccount({
    required String shelterName,
    required String organizationType,
    required String registrationNumber,
    required String yearEstablished,
    required String fullAddress,
    required String cityProvince,
    required String postalCode,
    required String googleMapsUrl,
    required String email,
    required String phoneNumber,
    required String alternateContact,
    required String websiteUrl,
    required String username,
    required String password,
    required String adminFullName,
    required String adminRole,
    required String animalTypesAccepted,
    required String capacity,
    required String servicesOffered,
    required String operatingHours,
  }) async {
    final normalizedEmail = _normalizeEmail(email);

    UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // Handle re-registration logic
        try {
          credential = await _auth.signInWithEmailAndPassword(
            email: normalizedEmail,
            password: password,
          );
          
          final existingDoc = await _firestore.collection('shelters').doc(credential.user!.uid).get();
          if (existingDoc.exists) {
            final status = existingDoc.data()?['status'];
            if (status == 'pending_verification' || status == 'approved') {
              await _auth.signOut();
              throw FirebaseAuthException(
                code: 'duplicate-application',
                message: 'An active or approved application already exists for this email.',
              );
            }
            // If rejected, allow overwriting the application
          }
        } on FirebaseAuthException catch (signInError) {
          if (signInError.code == 'wrong-password' || signInError.code == 'invalid-credential') {
             throw FirebaseAuthException(
               code: 'email-already-in-use',
               message: 'An account with this email already exists. Please login, or use the correct password to re-apply if you were rejected.',
             );
          }
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    final user = credential.user;
    if (user != null) {
      await user.updateDisplayName(shelterName.trim());
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': normalizedEmail,
        'role': 'shelter',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _firestore.collection('shelters').doc(user.uid).set({
        'uid': user.uid,
        'shelterName': shelterName.trim(),
        'organizationType': organizationType.trim(),
        'registrationNumber': registrationNumber.trim(),
        'yearEstablished': yearEstablished.trim(),
        'location': {
          'fullAddress': fullAddress.trim(),
          'cityProvince': cityProvince.trim(),
          'postalCode': postalCode.trim(),
          'googleMapsUrl': googleMapsUrl.trim(),
        },
        'contact': {
          'email': normalizedEmail,
          'phoneNumber': _normalizePhoneNumber(phoneNumber),
          'alternateContact': _normalizePhoneNumber(alternateContact),
          'websiteUrl': websiteUrl.trim(),
        },
        'accountDetails': {'username': username.trim()},
        'adminDetails': {
          'fullName': adminFullName.trim(),
          'role': adminRole.trim(),
        },
        'operations': {
          'animalTypesAccepted': animalTypesAccepted.trim(),
          'capacity': capacity.trim(),
          'servicesOffered': servicesOffered.trim(),
          'operatingHours': operatingHours.trim(),
        },
        'status': 'pending_verification',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Sending Application Received Email
      await EmailService.instance.sendEmail(
        to: normalizedEmail,
        subject: 'Application Received',
        message: 'Hello $shelterName,\n\nYour application has been received and is pending review. We will notify you once your application status is updated.\n\nThank you,\nThe Admin Team',
      );
    }

    return credential;
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  String mapError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
          return 'No account found for this email.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'Too many attempts. Please try again later.':
          return 'Too many attempts. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Please check your connection.';
        case 'email-already-in-use':
          return 'An account with this email already exists. If you were rejected, log in or use the correct password to re-apply.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'duplicate-application':
          return error.message ?? 'An active or approved application already exists for this email.';
        default:
          return error.message ?? 'Authentication failed. Please try again.';
      }
    }

    return 'Unexpected error. Please try again.';
  }

  String _normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  String _normalizePhoneNumber(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), '');
  }

  String _normalizeShelterCredential(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('@')) {
      return normalized;
    }
    return '$normalized@shelter.pawmilya.app';
  }
}
